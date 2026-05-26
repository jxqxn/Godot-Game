class_name StmMapManager
extends RefCounted

const _MapData := preload("res://scripts/stm/map/map_data.gd")

var _current_floor_index: int = 0


func get_current_floor_index() -> int:
	return _current_floor_index


func get_current_floor_info() -> Dictionary:
	if _current_floor_index < 0 or _current_floor_index >= _MapData.FLOORS.size():
		return {}
	return _MapData.FLOORS[_current_floor_index].duplicate(true)


func navigate_to_floor(floor_index: int) -> void:
	if floor_index >= 0 and floor_index < _MapData.FLOORS.size():
		_current_floor_index = floor_index


func get_available_next_floors() -> Array:
	var current_info := get_current_floor_info()
	if current_info.is_empty():
		return []
	var rooms: Array = current_info.get("rooms", [])
	var next_set := {}
	for room in rooms:
		for next_index in room.get("next_floors", []):
			next_set[next_index] = true
	var result: Array = []
	for floor_index in next_set.keys():
		result.append({
			"floor_index": int(floor_index),
			"floor_name": _MapData.FLOORS[int(floor_index)].get("name", "")
		})
	result.sort_custom(func(a, b): return a["floor_index"] < b["floor_index"])
	return result


func get_available_room_types() -> Array:
	var current_info := get_current_floor_info()
	if current_info.is_empty():
		return []
	var rooms: Array = current_info.get("rooms", [])
	var types: Array = []
	for room in rooms:
		types.append(str(room.get("type", "")))
	return types


func is_final_floor() -> bool:
	return _current_floor_index >= _MapData.FLOORS.size() - 1
