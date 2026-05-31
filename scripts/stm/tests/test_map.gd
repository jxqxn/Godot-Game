extends GutTest

const MapDataScript := preload("res://scripts/stm/map/map_data.gd")
const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_floor_count_is_seven() -> void:
	# Given：使用固定测试地图数据。
	# When：读取地图的楼层总数。
	var floors = MapDataScript.FLOORS
	# Then：地图应包含 7 层。
	assert_eq(floors.size(), 7)


func test_layer_one_is_single_combat_node() -> void:
	# Given：固定测试地图。
	# When：查询第 0 层（层 1）的节点列表。
	var layer = MapDataScript.FLOORS[0]
	var nodes = layer["nodes"]
	# Then：该层只有 1 个 Combat 节点，且是必经楼层（无分支）。
	assert_eq(nodes.size(), 1)
	assert_eq(nodes[0]["type"], "combat")
	assert_eq(nodes[0]["next_nodes"], [{"floor_index": 1, "node_index": 0}])


func test_layer_four_branches_to_two_fifth_floor_nodes() -> void:
	# Given：固定测试地图。
	# When：查询第 3 层（层 4）的休息节点后续路径。
	var layer = MapDataScript.FLOORS[3]
	var nodes = layer["nodes"]
	# Then：层 4 是休息节点，并允许前往层 5 的战斗节点或事件节点。
	assert_eq(nodes.size(), 1)
	assert_eq(nodes[0]["type"], "rest")
	assert_eq(nodes[0]["next_nodes"], [
		{"floor_index": 4, "node_index": 0},
		{"floor_index": 4, "node_index": 1},
	])


func test_layer_five_has_combat_and_event_nodes() -> void:
	# Given：固定测试地图。
	# When：查询第 4 层（层 5）的节点列表。
	var layer = MapDataScript.FLOORS[4]
	var nodes = layer["nodes"]
	# Then：层 5 有战斗和事件两个分支节点，二者都通向第 6 层 node 0。
	assert_eq(nodes.size(), 2)
	assert_eq(nodes[0]["type"], "combat")
	assert_eq(nodes[0]["next_nodes"], [{"floor_index": 5, "node_index": 0}])
	assert_eq(nodes[1]["type"], "event")
	assert_eq(nodes[1]["room_payload"].get("event_id"), "debug_fountain")
	assert_eq(nodes[1]["next_nodes"], [{"floor_index": 5, "node_index": 0}])


func test_layer_seven_is_boss_node() -> void:
	# Given：固定测试地图。
	# When：查询第 6 层（层 7）的节点列表。
	var layer = MapDataScript.FLOORS[6]
	var nodes = layer["nodes"]
	# Then：该层只有 1 个 Boss 节点。
	assert_eq(nodes.size(), 1)
	assert_eq(nodes[0]["type"], "boss")
	assert_eq(nodes[0]["next_nodes"], [])


func test_map_manager_starts_at_floor_zero_node_zero() -> void:
	# Given：一个基于固定测试地图初始化的地图管理器。
	var manager = MapManagerScript.new()
	# When：查询当前楼层和节点索引。
	# Then：初始位置为第 1 层 node 0。
	assert_eq(manager.get_current_floor_index(), 0)
	assert_eq(manager.get_current_node_index(), 0)


func test_map_manager_navigate_to_node() -> void:
	# Given：地图管理器处于第 0 层 node 0。
	var manager = MapManagerScript.new()
	# When：导航到第 5 层 node 1。
	var changed = manager.navigate_to_node(4, 1)
	# Then：当前楼层和节点索引变更，并返回 true。
	assert_true(changed)
	assert_eq(manager.get_current_floor_index(), 4)
	assert_eq(manager.get_current_node_index(), 1)
	assert_eq(manager.get_current_node_info().get("type", ""), "event")
	assert_eq(manager.get_current_node().room_payload.get("event_id"), "debug_fountain")


func test_map_manager_rejects_invalid_node() -> void:
	# Given：地图管理器处于第 0 层 node 0。
	var manager = MapManagerScript.new()
	# When：尝试导航到不存在的节点。
	var changed = manager.navigate_to_node(4, 99)
	# Then：导航失败且当前位置不变。
	assert_false(changed)
	assert_eq(manager.get_current_floor_index(), 0)
	assert_eq(manager.get_current_node_index(), 0)


func test_map_manager_available_next_nodes_from_rest_branch() -> void:
	# Given：地图管理器处于第 3 层 node 0（层 4，休息后分支）。
	var manager = MapManagerScript.new()
	manager.navigate_to_node(3, 0)
	# When：查询可用的下一节点选项。
	var options = manager.get_available_next_nodes()
	# Then：可以选择第 5 层战斗节点或第 5 层事件节点。
	assert_eq(options.size(), 2)
	assert_eq(options[0]["floor_index"], 4)
	assert_eq(options[0]["node_index"], 0)
	assert_eq(options[0]["room_type"], "combat")
	assert_eq(options[1]["floor_index"], 4)
	assert_eq(options[1]["node_index"], 1)
	assert_eq(options[1]["room_type"], "event")
	assert_eq(options[1]["room_name"], "事件房间")


func test_map_manager_navigate_to_next_node_only_allows_reachable_options() -> void:
	# Given：地图管理器处于第 3 层 node 0（层 4）。
	var manager = MapManagerScript.new()
	manager.navigate_to_node(3, 0)
	# When：尝试前往不可达的第 6 层 node 0，再前往可达的第 5 层 node 1。
	var bad_result = manager.navigate_to_next_node(5, 0)
	var good_result = manager.navigate_to_next_node(4, 1)
	# Then：不可达导航失败，可达导航成功。
	assert_false(bad_result)
	assert_true(good_result)
	assert_eq(manager.get_current_floor_index(), 4)
	assert_eq(manager.get_current_node_index(), 1)


func test_map_manager_is_final_floor_for_boss_layer() -> void:
	# Given：地图管理器处于第 6 层（层 7 Boss）。
	var manager = MapManagerScript.new()
	manager.navigate_to_node(6, 0)
	# When：查询是否为最终楼层。
	var is_final = manager.is_final_floor()
	# Then：返回 true。
	assert_true(is_final)
