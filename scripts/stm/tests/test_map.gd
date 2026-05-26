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


func test_layer_four_can_branch_to_combat_or_rest_path() -> void:
	# Given：固定测试地图。
	# When：查询第 3 层（层 4）的休息房后续路径。
	var layer = MapDataScript.FLOORS[3]
	var rooms = layer["rooms"]
	# Then：层 4 是休息房，并允许前往层 5 战斗或跳到层 6 休息。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "rest")
	assert_eq(rooms[0]["next_floors"], [4, 5])


func test_layer_five_is_optional_combat_room() -> void:
	# Given：固定测试地图。
	# When：查询第 4 层（层 5）的房间列表。
	var layer = MapDataScript.FLOORS[4]
	var rooms = layer["rooms"]
	# Then：层 5 是可选战斗房，通向层 6。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "combat")
	assert_eq(rooms[0]["next_floors"], [5])


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


func test_map_manager_navigate_to_floor() -> void:
	# Given：地图管理器处于第 0 层。
	var manager = MapManagerScript.new()
	# When：导航到第 1 层（层 2）。
	var changed = manager.navigate_to_floor(1)
	# Then：当前楼层索引变为 1，并返回 true。
	assert_true(changed)
	assert_eq(manager.get_current_floor_index(), 1)


func test_map_manager_rejects_invalid_floor() -> void:
	# Given：地图管理器处于第 0 层。
	var manager = MapManagerScript.new()
	# When：尝试导航到不存在的楼层。
	var changed = manager.navigate_to_floor(99)
	# Then：导航失败且当前楼层不变。
	assert_false(changed)
	assert_eq(manager.get_current_floor_index(), 0)


func test_map_manager_available_next_floors_from_rest_branch() -> void:
	# Given：地图管理器处于第 3 层（层 4，休息后分支）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(3)
	# When：查询可用的下一层选项。
	var options = manager.get_available_next_floors()
	# Then：可以选择前往层 5 战斗或直接前往层 6 休息。
	assert_eq(options.size(), 2)
	assert_eq(options[0]["floor_index"], 4)
	assert_eq(options[1]["floor_index"], 5)


func test_map_manager_navigate_to_next_floor_only_allows_reachable_options() -> void:
	# Given：地图管理器处于第 3 层（层 4）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(3)
	# When：尝试前往不可达的 Boss 层，再前往可达的层 6。
	var bad_result = manager.navigate_to_next_floor(6)
	var good_result = manager.navigate_to_next_floor(5)
	# Then：不可达导航失败，可达导航成功。
	assert_false(bad_result)
	assert_true(good_result)
	assert_eq(manager.get_current_floor_index(), 5)


func test_map_manager_is_final_floor_for_boss_layer() -> void:
	# Given：地图管理器处于第 6 层（层 7 Boss）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(6)
	# When：查询是否为最终楼层。
	var is_final = manager.is_final_floor()
	# Then：返回 true。
	assert_true(is_final)
