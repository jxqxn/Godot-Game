extends GutTest

const MapNodeScript := preload("res://scripts/stm/map/map_node.gd")
const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_map_node_stores_core_fields() -> void:
	# Given：一个地图节点包含楼层、节点索引、房间类型、后续节点和 payload。
	var next_nodes := [{"floor_index": 2, "node_index": 0}]
	var payload := {"encounter_id": "debug_dummy"}
	# When：创建 MapNode。
	var node = MapNodeScript.new(1, 0, "combat", next_nodes, payload)
	# Then：字段按原样保存，但数组/字典应复制，避免外部修改污染节点。
	assert_eq(node.floor_index, 1)
	assert_eq(node.node_index, 0)
	assert_eq(node.room_type, "combat")
	assert_eq(node.next_nodes, next_nodes)
	assert_eq(node.room_payload, payload)
	next_nodes.append({"floor_index": 99, "node_index": 99})
	payload["encounter_id"] = "changed"
	assert_eq(node.next_nodes.size(), 1)
	assert_eq(node.room_payload.get("encounter_id"), "debug_dummy")


func test_map_node_display_room_name_maps_known_room_types() -> void:
	# Given / When / Then：常见 room_type 映射为中文显示名，未知类型保留原字符串。
	assert_eq(MapNodeScript.new(0, 0, "combat").display_room_name(), "战斗房间")
	assert_eq(MapNodeScript.new(0, 0, "rest").display_room_name(), "休息房间")
	assert_eq(MapNodeScript.new(0, 0, "boss").display_room_name(), "Boss 房间")
	assert_eq(MapNodeScript.new(0, 0, "mystery").display_room_name(), "mystery")


func test_map_node_to_option_returns_navigation_option_shape() -> void:
	# Given：一个第 5 层休息节点。
	var node = MapNodeScript.new(4, 1, "rest", [])
	# When：转换为 UI / GameFlow 使用的 option。
	var option: Dictionary = node.to_option("第 5 层")
	# Then：包含稳定的导航字段。
	assert_eq(option.get("floor_index"), 4)
	assert_eq(option.get("node_index"), 1)
	assert_eq(option.get("floor_name"), "第 5 层")
	assert_eq(option.get("room_type"), "rest")
	assert_eq(option.get("room_name"), "休息房间")


func test_map_node_has_next_node_checks_connections() -> void:
	# Given：一个节点连接到第 5 层 node 0 和 node 1。
	var node = MapNodeScript.new(3, 0, "rest", [
		{"floor_index": 4, "node_index": 0},
		{"floor_index": 4, "node_index": 1},
	])
	# When / Then：只能匹配真实连接。
	assert_true(node.has_next_node(4, 0))
	assert_true(node.has_next_node(4, 1))
	assert_false(node.has_next_node(5, 0))
	assert_false(node.has_next_node(4, 2))


func test_map_node_from_dict_reads_current_map_data_shape() -> void:
	# Given：当前 MapData 里的字典节点结构。
	var data := {
		"type": "combat",
		"room_payload": {"encounter_id": "debug_dummy"},
		"next_nodes": [{"floor_index": 1, "node_index": 0}],
	}
	# When：从字典创建 MapNode。
	var node = MapNodeScript.from_dict(0, 0, data)
	# Then：字段正确读取。
	assert_eq(node.floor_index, 0)
	assert_eq(node.node_index, 0)
	assert_eq(node.room_type, "combat")
	assert_eq(node.room_payload.get("encounter_id"), "debug_dummy")
	assert_true(node.has_next_node(1, 0))


func test_map_manager_current_nodes_expose_explicit_room_payloads() -> void:
	# Given：MapData 已显式声明 combat / boss encounter payload。
	var manager = MapManagerScript.new()
	# Then：第 1 层 combat 节点携带 debug_dummy。
	assert_eq(manager.get_current_node().room_payload.get("encounter_id"), "debug_dummy")
	# And：Boss 节点携带 boss_dummy。
	assert_true(manager.navigate_to_node(6, 0))
	assert_eq(manager.get_current_node().room_payload.get("encounter_id"), "boss_dummy")


func test_map_manager_available_next_nodes_remains_compatible() -> void:
	# Given：地图管理器位于第 4 层 node 0。
	var manager = MapManagerScript.new()
	assert_true(manager.navigate_to_node(3, 0))
	# When：查询可前往节点。
	var options: Array = manager.get_available_next_nodes()
	# Then：外部 option 行为保持不变，仍是两个第 5 层节点。
	assert_eq(options.size(), 2)
	assert_eq(options[0].get("floor_index"), 4)
	assert_eq(options[0].get("node_index"), 0)
	assert_eq(options[0].get("room_type"), "combat")
	assert_eq(options[0].get("room_name"), "战斗房间")
	assert_eq(options[1].get("floor_index"), 4)
	assert_eq(options[1].get("node_index"), 1)
	assert_eq(options[1].get("room_type"), "rest")
	assert_eq(options[1].get("room_name"), "休息房间")
