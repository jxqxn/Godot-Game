extends GutTest

const EventRoomScript := preload("res://scripts/stm/rooms/event_room.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")


func test_submit_event_choice_drink_heals_player_and_completes_room() -> void:
	# Given：玩家受伤并进入 debug_fountain 事件选择。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	game_state.player.hp = 40
	room.enter(game_state)
	# When：通过 GameState 公共入口选择 drink。
	var result: Dictionary = game_state.submit_choice("drink")
	# Then：玩家恢复 5 点 HP，选择清空，房间完成。
	assert_true(bool(result.get("ok", false)))
	assert_eq(result.get("code"), "EVENT_HEAL_TAKEN")
	assert_eq(game_state.player.hp, 45)
	assert_false(game_state.has_choice_request())
	assert_true(room.is_completed)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 45)
	assert_eq(room.last_event_action, "heal")


func test_submit_event_choice_drink_does_not_exceed_max_hp() -> void:
	# Given：玩家接近满血并进入 debug_fountain 事件选择。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	game_state.player.hp = game_state.player.max_hp - 2
	room.enter(game_state)
	# When：选择 drink。
	var result: Dictionary = game_state.submit_choice("drink")
	# Then：HP 不超过 max_hp，记录真实恢复结果。
	assert_true(bool(result.get("ok", false)))
	assert_eq(game_state.player.hp, game_state.player.max_hp)
	assert_eq(room.last_hp_before, game_state.player.max_hp - 2)
	assert_eq(room.last_hp_after, game_state.player.max_hp)


func test_submit_event_choice_leave_keeps_hp_and_completes_room() -> void:
	# Given：玩家受伤并进入 debug_fountain 事件选择。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	game_state.player.hp = 40
	room.enter(game_state)
	# When：通过 GameState 公共入口选择 leave。
	var result: Dictionary = game_state.submit_choice("leave")
	# Then：HP 不变，选择清空，房间完成。
	assert_true(bool(result.get("ok", false)))
	assert_eq(result.get("code"), "EVENT_LEFT")
	assert_eq(game_state.player.hp, 40)
	assert_false(game_state.has_choice_request())
	assert_true(room.is_completed)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 40)
	assert_eq(room.last_event_action, "leave")


func test_submit_event_choice_invalid_payload_does_not_clear_choice_or_complete_room() -> void:
	# Given：一个 event_choice 中存在 invalid payload 选项。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	room.enter(game_state)
	game_state.current_choice_request.options.append(ChoiceOptionScript.new("broken", "坏选项", "", {"action": "unknown"}, true))
	# When：提交 invalid 选项。
	var result: Dictionary = game_state.submit_choice("broken")
	# Then：返回失败，不清空 choice，不完成房间。
	assert_false(bool(result.get("ok", true)))
	assert_eq(result.get("code"), "INVALID_PAYLOAD")
	assert_true(game_state.has_choice_request())
	assert_false(room.is_completed)


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)
