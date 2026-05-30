class_name StmMapNode
extends RefCounted

var floor_index: int = 0
var node_index: int = 0
var room_type: String = ""
var room_payload: Dictionary = {}
var next_nodes: Array = []


func _init(p_floor_index: int = 0, p_node_index: int = 0, p_room_type: String = "", p_next_nodes: Array = [], p_room_payload: Dictionary = {}) -> void:
	floor_index = p_floor_index
	node_index = p_node_index
	room_type = p_room_type
	next_nodes = p_next_nodes.duplicate(true)
	room_payload = p_room_payload.duplicate(true)


static func from_dict(p_floor_index: int, p_node_index: int, data: Dictionary):
	return StmMapNode.new(
		p_floor_index,
		p_node_index,
		str(data.get("type", data.get("room_type", ""))),
		data.get("next_nodes", []),
		data.get("room_payload", {})
	)


func display_room_name() -> String:
	match room_type:
		"combat":
			return "战斗房间"
		"rest":
			return "休息房间"
		"boss":
			return "Boss 房间"
		_:
			return room_type


func to_option(floor_name: String) -> Dictionary:
	return {
		"floor_index": floor_index,
		"node_index": node_index,
		"floor_name": floor_name,
		"room_type": room_type,
		"room_name": display_room_name(),
	}


func has_next_node(target_floor_index: int, target_node_index: int) -> bool:
	for target in next_nodes:
		if int(target.get("floor_index", -1)) == target_floor_index and int(target.get("node_index", -1)) == target_node_index:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"type": room_type,
		"room_type": room_type,
		"room_payload": room_payload.duplicate(true),
		"next_nodes": next_nodes.duplicate(true),
	}
