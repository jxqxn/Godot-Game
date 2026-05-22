class_name StmGameState
extends RefCounted

var current_act: int = 1
var floor_in_act: int = 1
var player = null
var current_combat = null
var action_queue = null
var _pending_actions: Array = []


var current_floor: int:
	get:
		return (current_act - 1) * 100 + floor_in_act


func _init(p_player = null) -> void:
	player = p_player
	action_queue = _try_new_global("StmActionQueue")


func add_action(action) -> void:
	if action == null:
		return
	if action_queue != null:
		if action_queue.has_method("add_action"):
			action_queue.add_action(action)
			return
		if action_queue.has_method("enqueue"):
			action_queue.enqueue(action)
			return
	_pending_actions.append(action)


func add_actions(actions: Array) -> void:
	for action in actions:
		add_action(action)


func drive_actions():
	if action_queue != null:
		if action_queue.has_method("drive"):
			return action_queue.drive(self)
		if action_queue.has_method("execute_all"):
			return action_queue.execute_all(self)
	for action in _pending_actions:
		if action != null and action.has_method("execute"):
			action.execute(self)
	_pending_actions.clear()
	return null


func _try_new_global(class_name_text: String):
	for item in ProjectSettings.get_global_class_list():
		if item.get("class") == class_name_text:
			var path = item.get("path", "")
			if path != "":
				var script = load(path)
				if script != null:
					return script.new()
	return null
