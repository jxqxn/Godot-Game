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


func add_action(action, to_front: bool = false) -> void:
	if action == null:
		return
	if action_queue != null:
		if action_queue.has_method("add_action"):
			action_queue.add_action(action, to_front)
			return
		if action_queue.has_method("enqueue"):
			action_queue.enqueue(action)
			return
	if to_front:
		_pending_actions.push_front(action)
		return
	_pending_actions.append(action)


func add_actions(actions: Array, to_front: bool = false) -> void:
	if to_front:
		for index in range(actions.size() - 1, -1, -1):
			add_action(actions[index], true)
		return
	for action in actions:
		add_action(action, false)


func drive_actions():
	if action_queue != null:
		if action_queue.has_method("drive"):
			return action_queue.drive(self)
		if action_queue.has_method("execute_all"):
			return action_queue.execute_all(self)
	var none_result := int(StmTypes.TerminalResult.NONE)
	while not _pending_actions.is_empty():
		var action = _pending_actions.pop_front()
		if action == null or not action.has_method("execute"):
			continue
		var result = action.execute(self)
		if typeof(result) == TYPE_INT:
			var terminal_result := int(result)
			if terminal_result != none_result:
				_pending_actions.clear()
				return terminal_result
	return none_result


func _try_new_global(class_name_text: String):
	for item in ProjectSettings.get_global_class_list():
		if item.get("class") == class_name_text:
			var path = item.get("path", "")
			if path != "":
				var script = load(path)
				if script != null:
					return script.new()
	return null
