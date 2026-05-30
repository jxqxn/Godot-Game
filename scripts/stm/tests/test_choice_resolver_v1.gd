extends GutTest

const StmGameState := preload("res://scripts/stm/engine/game_state.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func test_submit_choice_take_card_adds_selected_card_and_completes_room() -> void:
	# Given：一个战斗奖励 choice request。
	var context = _entered_combat_room_with_reward_request()
	var game_state = context.game_state
	var room = context.room
	# When：选择第一张奖励卡。
	var result: Dictionary = game_state.submit_choice("take_strike")
	# Then：卡牌进入牌组，选择被清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "CARD_REWARD_TAKEN")
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)
	assert_eq(game_state.player.card_manager.get_pile("deck").size(), 1)


func test_submit_choice_skip_card_reward_completes_room_without_card() -> void:
	# Given：一个战斗奖励 choice request。
	var context = _entered_combat_room_with_reward_request()
	var game_state = context.game_state
	var room = context.room
	# When：选择跳过。
	var result: Dictionary = game_state.submit_choice("skip_reward")
	# Then：不加卡，选择被清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "CARD_REWARD_SKIPPED")
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)
	assert_eq(game_state.player.card_manager.get_pile("deck").size(), 0)


func test_submit_choice_rest_heals_player_and_completes_room() -> void:
	# Given：玩家进入休息房且 HP 受损。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	room.enter(game_state)
	# When：选择休息。
	var result: Dictionary = game_state.submit_choice("rest")
	# Then：恢复 30% max_hp，选择清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "REST_TAKEN")
	assert_eq(player.hp, 61)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 61)
	assert_eq(room.last_heal_amount, 21)
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submit_choice_skip_rest_completes_room_without_heal() -> void:
	# Given：玩家进入休息房且 HP 受损。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
	room.enter(game_state)
	# When：选择跳过休息。
	var result: Dictionary = game_state.submit_choice("skip_rest")
	# Then：HP 不变，选择清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "REST_SKIPPED")
	assert_eq(player.hp, 40)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 40)
	assert_eq(room.last_heal_amount, 0)
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submit_choice_unsupported_request_type_still_returns_failure() -> void:
	# Given：当前 request 类型不是当前架构支持的 choice 类型。
	var game_state = StmGameState.new(null)
	var option = ChoiceOptionScript.new("option", "选项", "", {"action": "noop"}, true)
	var request = ChoiceRequestScript.new("mystery", "未知", "mystery_choice", [option])
	game_state.set_choice_request(request)
	# When：提交该 option。
	var result: Dictionary = game_state.submit_choice("option")
	# Then：仍返回 UNSUPPORTED_REQUEST_TYPE，且不清空 request。
	assert_false(result.ok)
	assert_eq(result.code, "UNSUPPORTED_REQUEST_TYPE")
	assert_eq(result.request_type, "mystery_choice")
	assert_true(game_state.has_choice_request())


func _entered_combat_room_with_reward_request() -> Dictionary:
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var room = CombatRoomScript.new()
	room.enter(game_state)
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	return {"game_state": game_state, "room": room}
