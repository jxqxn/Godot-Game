class_name StmRoomFactory
extends RefCounted

const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")


func create_room(map_node):
	if map_node == null:
		return null
	var room = null
	match str(map_node.get("room_type")):
		"combat":
			room = CombatRoomScript.new()
		"rest":
			room = RestRoomScript.new()
		"boss":
			room = BossRoomScript.new()
		_:
			return null
	_apply_room_payload(room, map_node.get("room_payload"))
	return room


func _apply_room_payload(room, payload) -> void:
	if room == null:
		return
	if not payload is Dictionary:
		return
	if room.has_method("set_room_payload"):
		room.set_room_payload(payload)
