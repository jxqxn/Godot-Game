extends GutTest

const ChoiceResolverScript := preload("res://scripts/stm/choices/choice_resolver.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func test_choice_resolver_exists_and_game_state_does_not_own_specific_choice_rules() -> void:
	# Given：ChoiceResolver 是选择规则的长期边界。
	var resolver = ChoiceResolverScript.new()
	var game_state = StmGameState.new(null)
	# Then：Resolver 暴露统一 resolve()；GameState 保留 submit_choice()，但不再持有具体 choice 规则方法。
	assert_true(resolver.has_method("resolve"))
	assert_true(game_state.has_method("submit_choice"))
	assert_false(game_state.has_method("_resolve_card_reward_choice"))
	assert_false(game_state.has_method("_resolve_rest_choice"))


func test_submit_choice_takes_card_reward_through_public_game_state_entry() -> void:
	# Given：战斗胜利后生成 card_reward 请求。
	var context := _entered_combat_room_with_reward_request()
	var game_state = context.game_state
	var room = context.room
	var option = _reward_options(game_state.current_choice_request)[0]
	var selected_card = option.payload.get("card")
	var deck_before: int = game_state.player.card_manager.get_pile("deck").size()
	# When：通过 GameState 公共入口提交奖励选择。
	var result: Dictionary = game_state.submit_choice(option.id)
	# Then：外部行为保持不变，解析细节由 ChoiceResolver 承担。
	assert_true(result.ok)
	assert_eq(result.code, "CARD_REWARD_TAKEN")
	assert_true(str(result.message).contains("获得"))
	assert_eq(game_state.player.card_manager.get_pile("deck").size(), deck_before + 1)
	assert_true(game_state.player.card_manager.get_pile("deck").has(selected_card))
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submit_choice_skips_card_reward_through_public_game_state_entry() -> void:
	# Given：战斗胜利后生成 card_reward 请求。
	var context := _entered_combat_room_with_reward_request()
	var game_state = context.game_state
	var room = context.room
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


func test_submit_choice_takes_rest_choice_through_public_game_state_entry() -> void:
	# Given：玩家受伤后进入休息房并生成 rest_choice。
	var context := _entered_rest_room_with_choice(40)
	var game_state = context.game_state
	var room = context.room
	var rest_option = _option_with_action(game_state.current_choice_request, "rest")
	# When：提交休息选择。
	var result: Dictionary = game_state.submit_choice(rest_option.id)
	# Then：恢复 30% 最大生命并完成房间。
	assert_true(result.ok)
	assert_eq(result.code, "REST_TAKEN")
	assert_true(str(result.message).contains("休息"))
	assert_eq(game_state.player.hp, 61)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 61)
	assert_eq(room.last_heal_amount, 21)
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submit_choice_skips_rest_choice_through_public_game_state_entry() -> void:
	# Given：玩家受伤后进入休息房并生成 rest_choice。
	var context := _entered_rest_room_with_choice(40)
	var game_state = context.game_state
	var room = context.room
	var skip_option = _option_with_action(game_state.current_choice_request, "skip")
	# When：提交跳过休息。
	var result: Dictionary = game_state.submit_choice(skip_option.id)
	# Then：HP 不变，请求清空，房间完成。
	assert_true(result.ok)
	assert_eq(result.code, "REST_SKIPPED")
	assert_true(str(result.message).contains("跳过"))
	assert_eq(game_state.player.hp, 40)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 40)
	assert_eq(room.last_heal_amount, 0)
	assert_null(game_state.current_choice_request)
	assert_true(room.is_completed)


func test_submit_choice_unsupported_request_type_still_returns_failure() -> void:
	# Given：当前 request 类型不是当前架构支持的 choice 类型。
	var game_state = StmGameState.new(null)
	var option = ChoiceOptionScript.new("option", "选项", "", {"action": "noop"}, true)
	var request = ChoiceRequestScript.new("event", "事件", "event_choice", [option])
	game_state.set_choice_request(request)
	# When：提交该 option。
	var result: Dictionary = game_state.submit_choice("option")
	# Then：仍返回 UNSUPPORTED_REQUEST_TYPE，且不清空 request。
	assert_false(result.ok)
	assert_eq(result.code, "UNSUPPORTED_REQUEST_TYPE")
	assert_eq(result.request_type, "event_choice")
	assert_true(game_state.has_choice_request())


func _entered_combat_room_with_reward_request() -> Dictionary:
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var room = CombatRoomScript.new()
	room.enter(game_state)
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	return {"game_state": game_state, "room": room}


func _entered_rest_room_with_choice(player_hp: int) -> Dictionary:
	var player = PlayerScript.new([])
	player.hp = player_hp
	var game_state = StmGameState.new(player)
	var room = RestRoomScript.new()
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
