extends GutTest

const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")


func test_rest_room_enter_creates_rest_choice_without_completing_room() -> void:
	# Given：玩家进入休息房。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房。
	room.enter(game_state)
	# Then：休息房先等待选择，不立即回血或完成。
	assert_false(room.is_completed)
	assert_eq(player.hp, 40)
	assert_true(game_state.has_choice_request())
	var request = game_state.current_choice_request
	assert_eq(request.request_type, "rest_choice")
	assert_true(str(request.title).contains("选择休息行动"))
	assert_not_null(_option_with_action(request, "rest"))
	assert_not_null(_option_with_action(request, "skip"))


func test_submitting_rest_choice_heals_player_and_completes_room() -> void:
	# Given：玩家受伤后进入休息房并获得 rest_choice。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	room.enter(game_state)
	var rest_option = _option_with_action(game_state.current_choice_request, "rest")
	# When：选择休息。
	var result: Dictionary = game_state.submit_choice(rest_option.id)
	# Then：恢复 30% 最大生命，房间完成，选择清空。
	assert_true(result.ok)
	assert_eq(result.code, "REST_TAKEN")
	assert_true(str(result.message).contains("休息"))
	assert_eq(player.hp, 61)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 61)
	assert_eq(room.last_heal_amount, 21)
	assert_true(room.is_completed)
	assert_false(game_state.has_choice_request())


func test_submitting_rest_choice_at_full_hp_records_zero_heal_and_completes_room() -> void:
	# Given：玩家满血进入休息房。
	var player = PlayerScript.new([])
	player.hp = player.max_hp
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	room.enter(game_state)
	var rest_option = _option_with_action(game_state.current_choice_request, "rest")
	# When：选择休息。
	var result: Dictionary = game_state.submit_choice(rest_option.id)
	# Then：HP 不超过上限，但仍完成房间。
	assert_true(result.ok)
	assert_eq(result.code, "REST_TAKEN")
	assert_eq(player.hp, player.max_hp)
	assert_eq(room.last_hp_before, player.max_hp)
	assert_eq(room.last_hp_after, player.max_hp)
	assert_eq(room.last_heal_amount, 0)
	assert_true(room.is_completed)
	assert_false(game_state.has_choice_request())


func test_submitting_skip_rest_keeps_hp_and_completes_room() -> void:
	# Given：玩家进入休息房并获得跳过选项。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	room.enter(game_state)
	var skip_option = _option_with_action(game_state.current_choice_request, "skip")
	# When：选择跳过。
	var result: Dictionary = game_state.submit_choice(skip_option.id)
	# Then：HP 不变，房间完成，选择清空。
	assert_true(result.ok)
	assert_eq(result.code, "REST_SKIPPED")
	assert_true(str(result.message).contains("跳过"))
	assert_eq(player.hp, 40)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 40)
	assert_eq(room.last_heal_amount, 0)
	assert_true(room.is_completed)
	assert_false(game_state.has_choice_request())


func test_invalid_rest_choice_payload_returns_invalid_payload() -> void:
	# Given：一个 rest_choice 请求中 option payload 不合法。
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var option = ChoiceOptionScript.new("broken", "坏选项", "", {"action": "bad_action"}, true)
	var request = ChoiceRequestScript.new("rest_choice", "选择休息行动", "rest_choice", [option], 1, false, {"room": null})
	game_state.set_choice_request(request)
	# When：提交该 option。
	var result: Dictionary = game_state.submit_choice("broken")
	# Then：返回 INVALID_PAYLOAD，且不清空 request。
	assert_false(result.ok)
	assert_eq(result.code, "INVALID_PAYLOAD")
	assert_true(game_state.has_choice_request())


func _option_with_action(request, action: String):
	for option in request.options:
		if option != null and option.payload.get("action") == action:
			return option
	return null
