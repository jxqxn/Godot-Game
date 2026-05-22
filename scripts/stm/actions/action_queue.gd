class_name StmActionQueue
extends RefCounted

var queue: Array = []


func add_action(action, to_front: bool = false) -> void:
	if action == null:
		return
	if to_front:
		queue.push_front(action)
		return
	queue.append(action)


func add_actions(actions: Array, to_front: bool = false) -> void:
	if to_front:
		for index in range(actions.size() - 1, -1, -1):
			add_action(actions[index], true)
		return
	for action in actions:
		add_action(action, false)


func execute_next(game_state) -> int:
	if queue.is_empty():
		return StmTypes.TerminalResult.NONE
	var action = queue.pop_front()
	if action == null:
		return StmTypes.TerminalResult.NONE
	if action.has_method("execute"):
		var result = action.execute(game_state)
		if typeof(result) == TYPE_INT:
			return result
	return StmTypes.TerminalResult.NONE


func execute_all(game_state) -> int:
	var result := StmTypes.TerminalResult.NONE
	while not queue.is_empty():
		result = execute_next(game_state)
		if result != StmTypes.TerminalResult.NONE:
			return result
	return result


func is_empty() -> bool:
	return queue.is_empty()


func clear() -> void:
	queue.clear()


func enqueue(action) -> void:
	add_action(action)


func drive(game_state):
	return execute_all(game_state)
