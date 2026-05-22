class_name StmOption
extends RefCounted

var name: String = ""
var actions: Array = []


func _init(p_name: String = "", p_actions: Array = []) -> void:
	name = p_name
	actions = p_actions.duplicate()
