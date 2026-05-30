extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


func test_game_flow_starts_at_floor_zero() -> void:
	# Given：一个新创建的 GameFlow。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：查询当前楼层索引。
	var floor_index = flow.get_current_floor_index()
	# Then：初始楼层索引为 0。
	assert_eq(floor_index, 0)


func test_game_flow_enter_combat_room_creates_battle() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：进入当前楼层的战斗房间。
	var entered = flow.enter_current_room()
	# Then：game_state 中创建了战斗上下文。
	assert_true(entered)
	assert_not_null(game_state.current_combat)
	assert_not_null(game_state.player)
	assert_not_null(flow.get_current_room())


func test_game_flow_cannot_get_next_options_before_room_completed() -> void:
	# Given：GameFlow 已进入第 0 层战斗房间，但还没有获胜。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	# When：查询可选的下一层。
	var options = flow.get_available_next_floors()
	# Then：房间未完成前没有可用下一层。
	assert_eq(options.size(), 0)


func test_game_flow_combat_win_unlocks_next_options_after_reward_choice() -> void:
	# Given：GameFlow 处于第 0 层，已进入战斗房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	# When：通过战斗胜利进入奖励阶段。
	var completed = flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	# Then：普通战斗不会立刻完成，必须先处理奖励。
	assert_false(completed)
	assert_true(game_state.has_choice_request())
	assert_eq(flow.get_available_next_floors().size(), 0)
	# When：跳过奖励。
	assert_true(_skip_pending_card_reward(flow))
	var options = flow.get_available_next_floors()
	# Then：奖励处理后房间完成并返回第 1 层作为下一层选项。
	assert_eq(options.size(), 1)
	assert_eq(options[0]["floor_index"], 1)


func test_game_flow_cannot_reenter_completed_room_before_advancing() -> void:
	# Given：GameFlow 处于第 0 层，当前战斗房间已经完成但还没有推进下一层。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(_skip_pending_card_reward(flow))
	var completed_room = flow.get_current_room()
	# When：再次尝试进入当前楼层房间。
	var reentered = flow.enter_current_room()
	# Then：规则层拒绝重复进入，当前房间实例不变。
	assert_false(reentered)
	assert_eq(flow.get_current_room(), completed_room)
	assert_eq(flow.get_current_floor_index(), 0)


func test_game_flow_cannot_advance_before_current_room_completed() -> void:
	# Given：GameFlow 处于第 0 层，已进入但未完成战斗房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	# When：尝试推进到下一层。
	var advanced = flow.advance_to_next_floor(1)
	# Then：推进失败且仍停留在第 0 层。
	assert_false(advanced)
	assert_eq(flow.get_current_floor_index(), 0)


func test_game_flow_cannot_advance_to_unreachable_floor() -> void:
	# Given：GameFlow 处于第 0 层且战斗房间已完成。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(_skip_pending_card_reward(flow))
	# When：尝试直接跳到 Boss 层。
	var advanced = flow.advance_to_next_floor(6)
	# Then：推进失败且仍停留在第 0 层。
	assert_false(advanced)
	assert_eq(flow.get_current_floor_index(), 0)


func test_game_flow_advance_to_next_floor() -> void:
	# Given：GameFlow 处于第 0 层，房间已通过战斗胜利和奖励选择完成。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(_skip_pending_card_reward(flow))
	# When：推进到下一层。
	var advanced = flow.advance_to_next_floor(1)
	# Then：当前楼层索引变为 1，且当前房间被离开。
	assert_true(advanced)
	assert_eq(flow.get_current_floor_index(), 1)
	assert_null(flow.get_current_room())


func test_game_flow_rest_room_is_completed_on_enter_and_unlocks_branch() -> void:
	# Given：GameFlow 通过调试入口定位到第 3 层休息房。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	assert_true(flow.debug_navigate_to_floor_for_test(3))
	# When：进入休息房。
	var entered = flow.enter_current_room()
	var options = flow.get_available_next_floors()
	# Then：休息房自动完成，并解锁前往层 5 战斗或层 6 休息的路径。
	assert_true(entered)
	assert_true(flow.get_current_room().is_completed)
	assert_eq(options.size(), 2)
	assert_eq(options[0]["floor_index"], 4)
	assert_eq(options[1]["floor_index"], 5)


func test_game_flow_debug_navigation_rejects_active_room() -> void:
	# Given：GameFlow 已经进入当前楼层房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	# When：尝试使用调试入口强行切楼层。
	var changed = flow.debug_navigate_to_floor_for_test(3)
	# Then：调试入口也会拒绝破坏活跃房间状态。
	assert_false(changed)
	assert_eq(flow.get_current_floor_index(), 0)


func test_game_flow_boss_does_not_complete_without_combat_win() -> void:
	# Given：GameFlow 通过调试入口定位到第 6 层 BossRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	assert_true(flow.debug_navigate_to_floor_for_test(6))
	flow.enter_current_room()
	# When：尝试不通过战斗胜利直接完成 Boss 房间。
	var completed_directly = flow.complete_current_room()
	var completed_without_win = flow.handle_combat_result(TypesScript.TerminalResult.NONE)
	# Then：Boss 不会完成，也不会通关。
	assert_false(completed_directly)
	assert_false(completed_without_win)
	assert_false(flow.is_flow_completed())


func test_game_flow_at_boss_floor_sets_flow_completed_on_combat_win() -> void:
	# Given：GameFlow 通过调试入口定位到第 6 层 BossRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	assert_true(flow.debug_navigate_to_floor_for_test(6))
	flow.enter_current_room()
	# When：传入战斗胜利结果。
	var completed = flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	# Then：Boss 房间完成，并设置 flow_completed。
	assert_true(completed)
	assert_true(flow.get_current_room().is_completed)
	assert_true(flow.is_flow_completed())


func test_game_flow_not_completed_at_non_boss_floor_after_reward_choice() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(_skip_pending_card_reward(flow))
	# When：检查 flow_completed。
	var is_completed = flow.is_flow_completed()
	# Then：普通战斗完成不应触发通关。
	assert_false(is_completed)


func test_game_flow_short_path_reaches_boss_and_completes_flow() -> void:
	# Given：GameFlow 从第 1 层开始，选择最短路径跳过第 5 层战斗。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：依次完成 1-3 层战斗，进入第 4 层休息，跳到第 6 层休息，再进入第 7 层 Boss 并胜利。
	assert_true(_win_current_combat_room_and_advance(flow, 1))
	assert_true(_win_current_combat_room_and_advance(flow, 2))
	assert_true(_win_current_combat_room_and_advance(flow, 3))
	assert_true(_enter_rest_room_and_advance(flow, 5))
	assert_true(_enter_rest_room_and_advance(flow, 6))
	assert_true(flow.enter_current_room())
	assert_eq(flow.get_current_room().get_room_type(), "boss")
	var boss_completed = flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	# Then：流程停留在 Boss 层，并被标记为通关。
	assert_true(boss_completed)
	assert_eq(flow.get_current_floor_index(), 6)
	assert_true(flow.is_flow_completed())


func _win_current_combat_room_and_advance(flow, next_floor_index: int) -> bool:
	if not flow.enter_current_room():
		return false
	if flow.get_current_room().get_room_type() != "combat":
		return false
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	if not _skip_pending_card_reward(flow):
		return false
	return flow.advance_to_next_floor(next_floor_index)


func _enter_rest_room_and_advance(flow, next_floor_index: int) -> bool:
	if not flow.enter_current_room():
		return false
	if flow.get_current_room().get_room_type() != "rest":
		return false
	if not flow.get_current_room().is_completed:
		return false
	return flow.advance_to_next_floor(next_floor_index)


func _skip_pending_card_reward(flow) -> bool:
	var game_state = flow.get_game_state()
	if game_state == null or not game_state.has_choice_request():
		return false
	var request = game_state.current_choice_request
	if request.request_type != "card_reward":
		return false
	for option in request.options:
		if option != null and option.payload.get("action") == "skip":
			var result: Dictionary = game_state.submit_choice(option.id)
			return bool(result.get("ok", false))
	return false
