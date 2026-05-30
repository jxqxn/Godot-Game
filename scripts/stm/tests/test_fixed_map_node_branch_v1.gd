extends GutTest

const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_initial_position_is_first_floor_node_zero_combat() -> void:
	# Given：固定测试地图刚创建。
	var manager = MapManagerScript.new()
	# Then：初始位置是第 1 层 node 0，房间类型为 combat。
	assert_eq(manager.get_current_floor_index(), 0)
	assert_eq(manager.get_current_node_index(), 0)
	assert_eq(manager.get_current_node_info().get("type", ""), "combat")


func test_fourth_floor_rest_branches_to_two_fifth_floor_nodes() -> void:
	# Given：玩家位于第 4 层 node 0 休息房。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(3, 0))
	# When：查询下一节点。
	var next_nodes: Array = manager.get_available_next_nodes()
	# Then：出现两个第 5 层节点，而不是第 5 / 第 6 层跳转。
	assert_eq(manager.get_current_node_info().get("type", ""), "rest")
	assert_eq(next_nodes.size(), 2)
	assert_not_null(_node_option(next_nodes, 4, 0))
	assert_not_null(_node_option(next_nodes, 4, 1))
	assert_eq(_node_option(next_nodes, 4, 0).get("room_type", ""), "combat")
	assert_eq(_node_option(next_nodes, 4, 1).get("room_type", ""), "rest")


func test_fourth_floor_cannot_skip_directly_to_sixth_floor() -> void:
	# Given：玩家位于第 4 层 node 0。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(3, 0))
	# When / Then：不能直接从第 4 层去第 6 层 node 0。
	assert_false(manager.can_navigate_to_next_node(5, 0))
	assert_false(manager.navigate_to_next_node(5, 0))
	assert_eq(manager.get_current_floor_index(), 3)
	assert_eq(manager.get_current_node_index(), 0)


func test_fifth_floor_combat_branch_merges_to_sixth_floor_node_zero() -> void:
	# Given：玩家位于第 5 层 node 0 战斗分支。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(4, 0))
	# When：查询下一节点。
	var next_nodes: Array = manager.get_available_next_nodes()
	# Then：只能前往第 6 层 node 0。
	assert_eq(manager.get_current_node_info().get("type", ""), "combat")
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 5, 0))
	assert_eq(_node_option(next_nodes, 5, 0).get("room_type", ""), "rest")


func test_fifth_floor_rest_branch_merges_to_sixth_floor_node_zero() -> void:
	# Given：玩家位于第 5 层 node 1 休息分支。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(4, 1))
	# When：查询下一节点。
	var next_nodes: Array = manager.get_available_next_nodes()
	# Then：也只能前往第 6 层 node 0。
	assert_eq(manager.get_current_node_info().get("type", ""), "rest")
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 5, 0))
	assert_eq(_node_option(next_nodes, 5, 0).get("room_type", ""), "rest")


func test_sixth_floor_rest_reaches_seventh_floor_boss() -> void:
	# Given：玩家位于第 6 层 node 0 休息房。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(5, 0))
	# When：查询下一节点。
	var next_nodes: Array = manager.get_available_next_nodes()
	# Then：只能前往第 7 层 Boss。
	assert_eq(manager.get_current_node_info().get("type", ""), "rest")
	assert_eq(next_nodes.size(), 1)
	assert_not_null(_node_option(next_nodes, 6, 0))
	assert_eq(_node_option(next_nodes, 6, 0).get("room_type", ""), "boss")


func test_seventh_floor_boss_has_no_next_nodes() -> void:
	# Given：玩家位于第 7 层 Boss。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(6, 0))
	# Then：Boss 是最终节点，没有下一节点。
	assert_eq(manager.get_current_node_info().get("type", ""), "boss")
	assert_true(manager.get_available_next_nodes().is_empty())


func _node_option(options: Array, floor_index: int, node_index: int):
	for option in options:
		if int(option.get("floor_index", -1)) == floor_index and int(option.get("node_index", -1)) == node_index:
			return option
	return null
