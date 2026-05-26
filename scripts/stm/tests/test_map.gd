extends GutTest

const MapDataScript := preload("res://scripts/stm/map/map_data.gd")
const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_floor_count_is_seven() -> void:
	# Given：使用固定测试地图数据。
	# When：读取地图的楼层总数。
	var floors = MapDataScript.FLOORS
	# Then：地图应包含 7 层。
	assert_eq(floors.size(), 7)


func test_layer_one_is_single_combat_room() -> void:
	# Given：固定测试地图。
	# When：查询第 0 层（层 1）的房间列表。
	var layer = MapDataScript.FLOORS[0]
	var rooms = layer["rooms"]
	# Then：该层只有 1 间 CombatRoom，且是必经楼层（无分支）。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "combat")


func test_layer_five_has_two_branch_options() -> void:
	# Given：固定测试地图。
	# When：查询第 4 层（层 5）的房间列表。
	var layer = MapDataScript.FLOORS[4]
	var rooms = layer["rooms"]
	# Then：该层有 2 间可选房间（CombatRoom 和 RestRoom），形成分支。
	assert_eq(rooms.size(), 2)
	var types := []
	for room in rooms:
		types.append(room["type"])
	assert_true(types.has("combat"))
	assert_true(types.has("rest"))


func test_layer_seven_is_boss_room() -> void:
	# Given：固定测试地图。
	# When：查询第 6 层（层 7）的房间列表。
	var layer = MapDataScript.FLOORS[6]
	var rooms = layer["rooms"]
	# Then：该层只有 1 间 BossRoom。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "boss")


func test_map_manager_starts_at_floor_zero() -> void:
	# Given：一个基于固定测试地图初始化的地图管理器。
	var manager = MapManagerScript.new()
	# When：查询当前楼层索引。
	var current = manager.get_current_floor_index()
	# Then：初始楼层索引为 0（层 1）。
	assert_eq(current, 0)


func test_map_manager_navigate_to_next_floor() -> void:
	# Given：地图管理器处于第 0 层。
	var manager = MapManagerScript.new()
	# When：导航到第 1 层（层 2）。
	manager.navigate_to_floor(1)
	# Then：当前楼层索引变为 1。
	assert_eq(manager.get_current_floor_index(), 1)


func test_map_manager_available_next_floors_from_branch() -> void:
	# Given：地图管理器处于第 4 层（层 5，有分支）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(4)
	# When：查询可用的下一层选项。
	var options = manager.get_available_next_floors()
	# Then：当前层的 2 个房间各自指向同一汇合层（层 6），但房间类型不同。
	assert_eq(options.size(), 1)
	assert_eq(options[0]["floor_index"], 5)


func test_map_manager_is_final_floor_for_boss_layer() -> void:
	# Given：地图管理器处于第 6 层（层 7 Boss）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(6)
	# When：查询是否为最终楼层。
	var is_final = manager.is_final_floor()
	# Then：返回 true。
	assert_true(is_final)
