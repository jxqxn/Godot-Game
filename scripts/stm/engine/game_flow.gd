class_name StmGameFlow
extends RefCounted

const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

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
	return flow_completed


func get_available_next_floors() -> Array:
	if _current_room == null or not _current_room.is_completed:
		return []
	return _map_manager.get_available_next_floors()


func get_current_floor_room_types() -> Array:
	return _map_manager.get_available_room_types()


func enter_current_room(room_index: int = 0) -> bool:
	if _current_room != null:
		return false
	var room_types := _map_manager.get_available_room_types()
	if room_index < 0 or room_index >= room_types.size():
		return false
	var room_type: String = room_types[room_index]
	var room = _create_room(room_type)
	if room == null:
		return false
	_current_room = room
	_current_room.enter(_game_state)
	return true


func complete_current_room() -> bool:
	if _current_room == null:
		return false
	if _is_combat_room_type(_current_room.get_room_type()):
		var result := _current_combat_result()
		if result != TypesScript.TerminalResult.COMBAT_WIN:
			return false
		return handle_combat_result(result)
	_current_room.complete(_game_state)
	return true


func handle_combat_result(result: int) -> bool:
	if _current_room == null:
		return false
	if not _is_combat_room_type(_current_room.get_room_type()):
		return false
	if _current_room.has_method("handle_combat_result"):
		_current_room.handle_combat_result(result, _game_state)
	if result == TypesScript.TerminalResult.COMBAT_WIN and _current_room.is_completed and _current_room.get_room_type() == "boss":
		flow_completed = true
	return _current_room.is_completed


func advance_to_next_floor(floor_index: int) -> bool:
	if _current_room == null or not _current_room.is_completed:
		return false
	if not _map_manager.can_navigate_to_next_floor(floor_index):
		return false
	leave_current_room()
	return _map_manager.navigate_to_next_floor(floor_index)


func leave_current_room() -> void:
	if _current_room == null:
		return
	_current_room.leave(_game_state)
	_current_room = null


func _create_room(room_type: String):
	match room_type:
		"combat":
			return CombatRoomScript.new()
		"rest":
			return RestRoomScript.new()
		"boss":
			return BossRoomScript.new()
		_:
			return null


func _is_combat_room_type(room_type: String) -> bool:
	return room_type == "combat" or room_type == "boss"


func _current_combat_result() -> int:
	if _game_state == null or _game_state.current_combat == null:
		return TypesScript.TerminalResult.NONE
	var combat = _game_state.current_combat
	if combat.has_method("check_combat_end"):
		var result = combat.check_combat_end(_game_state)
		if typeof(result) == TYPE_INT:
			return int(result)
	return TypesScript.TerminalResult.NONE
