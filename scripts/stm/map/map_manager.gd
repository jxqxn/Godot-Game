class_name StmMapManager
extends RefCounted

const _MapData := preload("res://scripts/stm/map/map_data.gd")
const MapNodeScript := preload("res://scripts/stm/map/map_node.gd")

var _current_floor_index: int = 0
var _current_node_index: int = 0


func get_current_floor_index() -> int:
	return _current_floor_index


func get_current_node_index() -> int:
	return _current_node_index


func get_current_floor_info() -> Dictionary:
	if _current_floor_index < 0 or _current_floor_index >= _MapData.FLOORS.size():
		return {}
	return _MapData.FLOORS[_current_floor_index].duplicate(true)


func get_current_node():
	return _node_at(_current_floor_index, _current_node_index)


func get_current_node_info() -> Dictionary:
	return _node_info(_current_floor_index, _current_node_index)


func navigate_to_node(floor_index: int, node_index: int) -> bool:
	if _node_at(floor_index, node_index) == null:
		return false
	_current_floor_index = floor_index
	_current_node_index = node_index
	return true


func navigate_to_floor(floor_index: int) -> bool:
	return navigate_to_node(floor_index, 0)


func navigate_to_next_node(floor_index: int, node_index: int) -> bool:
	if not can_navigate_to_next_node(floor_index, node_index):
		return false
	return navigate_to_node(floor_index, node_index)


func navigate_to_next_floor(floor_index: int) -> bool:
	var option = _first_next_node_for_floor(floor_index)
	if option.is_empty():
		return false
	return navigate_to_next_node(int(option["floor_index"]), int(option["node_index"]))


func can_navigate_to_next_node(floor_index: int, node_index: int) -> bool:
	var current_node = get_current_node()
	if current_node == null:
		return false
	return current_node.has_next_node(floor_index, node_index)


func can_navigate_to_next_floor(floor_index: int) -> bool:
	return not _first_next_node_for_floor(floor_index).is_empty()


func get_available_next_nodes() -> Array:
	var current_node = get_current_node()
	if current_node == null:
		return []
	var result: Array = []
	for target in current_node.next_nodes:
		var floor_index := int(target.get("floor_index", -1))
		var node_index := int(target.get("node_index", -1))
		var node = _node_at(floor_index, node_index)
		if node == null:
			continue
		result.append(node.to_option(_floor_name(floor_index)))
	result.sort_custom(func(a, b):
		if int(a["floor_index"]) == int(b["floor_index"]):
			return int(a["node_index"]) < int(b["node_index"])
		return int(a["floor_index"]) < int(b["floor_index"])
	)
	return result


func get_available_next_floors() -> Array:
	return get_available_next_nodes()


func get_available_room_types() -> Array:
	var node = get_current_node()
	if node == null:
		return []
	return [node.room_type]


func is_final_floor() -> bool:
	return _current_floor_index >= _MapData.FLOORS.size() - 1


func _node_at(floor_index: int, node_index: int):
	if floor_index < 0 or floor_index >= _MapData.FLOORS.size():
		return null
	var floor_info: Dictionary = _MapData.FLOORS[floor_index]
	var nodes: Array = floor_info.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return null
	return MapNodeScript.from_dict(floor_index, node_index, nodes[node_index])


func _node_info(floor_index: int, node_index: int) -> Dictionary:
	var node = _node_at(floor_index, node_index)
	if node == null:
		return {}
	return node.to_dict()


func _first_next_node_for_floor(floor_index: int) -> Dictionary:
	for option in get_available_next_nodes():
		if int(option.get("floor_index", -1)) == floor_index:
			return option
	return {}


func _floor_name(floor_index: int) -> String:
	if floor_index < 0 or floor_index >= _MapData.FLOORS.size():
		return ""
	return str(_MapData.FLOORS[floor_index].get("name", ""))
