class_name StmRoom
extends RefCounted

var is_completed: bool = false


func enter(_game_state) -> void:
	is_completed = false


func leave(_game_state) -> void:
	pass


func complete(_game_state) -> void:
	is_completed = true


func get_room_type() -> String:
	return ""
