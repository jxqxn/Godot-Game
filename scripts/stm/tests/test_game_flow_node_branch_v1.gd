extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func test_game_flow_fourth_floor_rest_unlocks_two_fifth_floor_nodes() -> void:
	# Given：流程沿 node 0 正常推进到第 4 层休息房。
	var flow = _flow_at_completed_fourth_floor_rest()
	# When：查询可前往节点。
	var next_nodes: Array = flow.get_available_next_nodes()
	# Then：第 4 层后是两个第 5 层节点，而不是第 5 / 第 6 层跳转。
	assert_eq(flow.get_current_floor_index(), 3)
	assert_eq(flow.get_current_node_index(), 0)
	assert_eq(next_nodes.size(), 2)
	assert_not_null(_node_option(next_nodes, 4, 0))
	assert_not_null(_node_option(next_nodes, 4, 1))
	assert_eq(_node_option(next_nodes, 4, 0).get("room_type", ""), "combat")
	assert_eq(_node_option(next_nodes, 4, 1).get("room_type", ""), "rest")
	assert_false(flow.advance_to_next_node(5, 0))


func test_game_flow_combat_branch_must_complete_fifth_floor_before_sixth_floor() -> void:
	# Given：第 4 层休息完成后。
	var flow = _flow_at_completed_fourth_floor_rest()
	# When：选择第 5 层 node 0 战斗分支。
	assert_true(flow.advance_to_next_node(4, 0))
	assert_eq(flow.get_current_floor_index(), 4)
	assert_eq(flow.get_current_node_index(), 0)
	assert_true(flow.enter_current_room())
	# Then：进入的是第 5 层 combat，完成前不能前往第 6 层。
	assert_eq(flow.get_current_room().get_room_type(), "combat")
	assert_false(flow.advance_to_next_node(5, 0))
	# When：完成 combat 和奖励。
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(_skip_pending_card_reward(flow))
	var next_nodes: Array = flow.get_available_next_nodes()
	# Then：完成后只能前往第 6 层 node 0。
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 5, 0))
	assert_true(flow.advance_to_next_node(5, 0))
	assert_eq(flow.get_current_floor_index(), 5)
	assert_eq(flow.get_current_node_index(), 0)


func test_game_flow_rest_branch_reaches_fifth_floor_rest_then_merges_to_sixth_floor() -> void:
	# Given：第 4 层休息完成后。
	var flow = _flow_at_completed_fourth_floor_rest()
	# When：选择第 5 层 node 1 休息分支。
	assert_true(flow.advance_to_next_node(4, 1))
	assert_eq(flow.get_current_floor_index(), 4)
	assert_eq(flow.get_current_node_index(), 1)
	assert_true(flow.enter_current_room())
	# Then：进入的是第 5 层 rest，完成前不能前往第 6 层。
	assert_eq(flow.get_current_room().get_room_type(), "rest")
	assert_false(flow.advance_to_next_node(5, 0))
	# When：完成 rest_choice。
	assert_true(_skip_pending_rest_choice(flow))
	var next_nodes: Array = flow.get_available_next_nodes()
	# Then：完成后汇合到第 6 层 node 0。
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 5, 0))
	assert_true(flow.advance_to_next_node(5, 0))
	assert_eq(flow.get_current_floor_index(), 5)
	assert_eq(flow.get_current_node_index(), 0)


func test_game_flow_node_path_can_reach_boss_after_sixth_floor() -> void:
	# Given：选择第 5 层 rest 分支并汇合到第 6 层。
	var flow = _flow_at_completed_fourth_floor_rest()
	assert_true(flow.advance_to_next_node(4, 1))
	assert_true(flow.enter_current_room())
	assert_true(_skip_pending_rest_choice(flow))
	assert_true(flow.advance_to_next_node(5, 0))
	# When：完成第 6 层 rest。
	assert_true(flow.enter_current_room())
	assert_eq(flow.get_current_room().get_room_type(), "rest")
	assert_true(_skip_pending_rest_choice(flow))
	# Then：可以前往第 7 层 Boss。
	var next_nodes: Array = flow.get_available_next_nodes()
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 6, 0))
	assert_eq(_node_option(next_nodes, 6, 0).get("room_type", ""), "boss")


func _flow_at_completed_fourth_floor_rest():
	var flow = GameFlowScript.new(_create_game_state())
	assert_true(_win_current_combat_room_and_advance_to_node(flow, 1, 0))
	assert_true(_win_current_combat_room_and_advance_to_node(flow, 2, 0))
	assert_true(_win_current_combat_room_and_advance_to_node(flow, 3, 0))
	assert_true(flow.enter_current_room())
	assert_eq(flow.get_current_room().get_room_type(), "rest")
	assert_true(_skip_pending_rest_choice(flow))
	return flow


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


func _win_current_combat_room_and_advance_to_node(flow, floor_index: int, node_index: int) -> bool:
	if not flow.enter_current_room():
		return false
	if flow.get_current_room().get_room_type() != "combat":
		return false
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	if not _skip_pending_card_reward(flow):
		return false
	return flow.advance_to_next_node(floor_index, node_index)


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


func _skip_pending_rest_choice(flow) -> bool:
	var game_state = flow.get_game_state()
	if game_state == null or not game_state.has_choice_request():
		return false
	var request = game_state.current_choice_request
	if request.request_type != "rest_choice":
		return false
	for option in request.options:
		if option != null and option.payload.get("action") == "skip":
			var result: Dictionary = game_state.submit_choice(option.id)
			return bool(result.get("ok", false))
	return false


func _node_option(options: Array, floor_index: int, node_index: int):
	for option in options:
		if int(option.get("floor_index", -1)) == floor_index and int(option.get("node_index", -1)) == node_index:
			return option
	return null
