class_name StmGameFlow
extends RefCounted

const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")

var _map_manager: StmMapManager = MapManagerScript.new()
var _current_room = null
var _game_state = null
var flow_completed: bool = false


func _init(game_state) -> void:
	_game_state = game_state


func get_current_floor_index() -> int:
	return _map_manager.get_current_floor_index()


func get_current_room():
	return _current_room


func get_game_state():
	return _game_state


func is_flow_completed() -> bool:
	if flow_completed:
		return true
	if _current_room != null and _current_room.is_completed and _current_room.get_room_type() == "boss":
		flow_completed = true
		return true
	return false


func get_available_next_floors() -> Array:
	return _map_manager.get_available_next_floors()


func get_current_floor_room_types() -> Array:
	return _map_manager.get_available_room_types()


func enter_current_room() -> void:
	var room_types := _map_manager.get_available_room_types()
	if room_types.is_empty():
		return
	var room_type: String = room_types[0]
	var room = null
	match room_type:
		"combat":
			room = CombatRoomScript.new()
		"rest":
			room = RestRoomScript.new()
		"boss":
			room = BossRoomScript.new()
		_:
			return
	_current_room = room
	_current_room.enter(_game_state)


func complete_current_room() -> void:
	if _current_room == null:
		return
	_current_room.complete(_game_state)
	if _current_room.get_room_type() == "boss":
		flow_completed = true


func advance_to_next_floor(floor_index: int) -> void:
	leave_current_room()
	_map_manager.navigate_to_floor(floor_index)


func leave_current_room() -> void:
	if _current_room == null:
		return
	_current_room.leave(_game_state)
	_current_room = null
