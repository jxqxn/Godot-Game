extends GutTest

const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func test_combat_win_creates_card_reward_request_without_completing_room() -> void:
	# Given：一个已经进入战斗的 CombatRoom。
	var context := _entered_combat_room()
	var game_state = context.game_state
	var room = context.room
	# When：战斗胜利结果传给房间。
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	# Then：房间先进入奖励选择状态，不直接完成。
	assert_false(room.is_completed)
	assert_not_null(game_state.current_choice_request)
	var request = game_state.current_choice_request
	assert_eq(request.request_type, "card_reward")
	assert_true(str(request.title).contains("选择一张奖励卡牌"))
	assert_eq(_reward_options(request).size(), 3)
	assert_not_null(_option_with_action(request, "skip"))


func test_card_reward_options_have_take_card_payloads_and_skip_payload() -> void:
	# Given：战斗胜利后生成奖励请求。
	var context := _entered_combat_room()
	context.room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, context.game_state)
	var request = context.game_state.current_choice_request
	# When：检查奖励选项。
	var reward_options := _reward_options(request)
	var skip_option = _option_with_action(request, "skip")
	# Then：奖励选项携带 take_card payload，跳过选项携带 skip payload。
	assert_eq(reward_options.size(), 3)
	for option in reward_options:
		assert_eq(option.payload.get("action"), "take_card")
		assert_not_null(option.payload.get("card"))
	assert_not_null(skip_option)
	assert_eq(skip_option.payload.get("action"), "skip")
	assert_null(skip_option.payload.get("card"))


func test_submitting_card_reward_adds_selected_card_to_deck_and_completes_room() -> void:
	# Given：战斗胜利后有 card_reward 请求。
	var context := _entered_combat_room()
	var game_state = context.game_state
	var room = context.room
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	var request = game_state.current_choice_request
	var option = _reward_options(request)[0]
	var selected_card = option.payload.get("card")
	var deck_before: int = game_state.player.card_manager.get_pile("deck").size()
	# When：提交奖励卡选择。
	var result: Dictionary = game_state.submit_choice(option.id)
	# Then：对应卡牌加入 deck，请求清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "CARD_REWARD_TAKEN")
	assert_true(str(result.message).contains("获得"))
	assert_eq(game_state.player.card_manager.get_pile("deck").size(), deck_before + 1)
	assert_true(game_state.player.card_manager.get_pile("deck").has(selected_card))
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submitting_skip_reward_keeps_deck_size_and_completes_room() -> void:
	# Given：战斗胜利后有跳过奖励选项。
	var context := _entered_combat_room()
	var game_state = context.game_state
	var room = context.room
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	var skip_option = _option_with_action(game_state.current_choice_request, "skip")
	var deck_before: int = game_state.player.card_manager.get_pile("deck").size()
	# When：提交跳过奖励。
	var result: Dictionary = game_state.submit_choice(skip_option.id)
	# Then：deck 不变，请求清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "CARD_REWARD_SKIPPED")
	assert_true(str(result.message).contains("跳过奖励"))
	assert_eq(game_state.player.card_manager.get_pile("deck").size(), deck_before)
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_repeated_combat_win_does_not_create_duplicate_reward_request() -> void:
	# Given：第一次处理战斗胜利后已经有奖励请求。
	var context := _entered_combat_room()
	var game_state = context.game_state
	var room = context.room
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	var first_request = game_state.current_choice_request
	# When：重复处理战斗胜利。
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	# Then：仍然是同一个请求，没有重复生成。
	assert_eq(game_state.current_choice_request, first_request)
	assert_eq(game_state.current_choice_request.options.size(), first_request.options.size())


func test_completed_room_does_not_create_new_reward_request() -> void:
	# Given：奖励已经被跳过，房间已完成。
	var context := _entered_combat_room()
	var game_state = context.game_state
	var room = context.room
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	var skip_option = _option_with_action(game_state.current_choice_request, "skip")
	game_state.submit_choice(skip_option.id)
	assert_true(room.is_completed)
	# When：再次处理胜利。
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	# Then：不再生成新的奖励请求。
	assert_null(game_state.current_choice_request)


func _entered_combat_room() -> Dictionary:
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var room = CombatRoomScript.new()
	room.enter(game_state)
	return {"game_state": game_state, "room": room}


func _reward_options(request) -> Array:
	var result: Array = []
	for option in request.options:
		if option != null and option.payload.get("action") == "take_card":
			result.append(option)
	return result


func _option_with_action(request, action: String):
	for option in request.options:
		if option != null and option.payload.get("action") == action:
			return option
	return null
