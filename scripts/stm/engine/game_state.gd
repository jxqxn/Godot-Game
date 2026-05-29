class_name StmGameState
extends RefCounted

var current_act: int = 1
var floor_in_act: int = 1
var player = null
var current_combat = null
var current_choice_request = null
var action_queue = null
var _pending_actions: Array = []


var current_floor: int:
	get:
		return (current_act - 1) * 100 + floor_in_act


func _init(p_player = null) -> void:
	player = p_player
	action_queue = _try_new_global("StmActionQueue")


func set_choice_request(request) -> void:
	current_choice_request = request


func clear_choice_request() -> void:
	current_choice_request = null


func has_choice_request() -> bool:
	return current_choice_request != null


func submit_choice(option_id: String) -> Dictionary:
	if current_choice_request == null:
		return _choice_result(false, "NO_CHOICE_REQUEST", "当前没有等待处理的选择")
	var request = current_choice_request
	if not request.has_method("get_option"):
		return _choice_result(false, "UNSUPPORTED_REQUEST_TYPE", "选择请求无效", str(request.get("request_type") if request.get("request_type") != null else ""), option_id)
	var option = request.get_option(option_id)
	if option == null:
		return _choice_result(false, "OPTION_NOT_FOUND", "选项不存在", str(request.get("request_type")), option_id)
	if not bool(option.get("enabled")):
		return _choice_result(false, "OPTION_DISABLED", "选项不可用", str(request.get("request_type")), option_id)
	var request_type := str(request.get("request_type"))
	match request_type:
		"card_reward":
			return _resolve_card_reward_choice(request, option)
		_:
			return _choice_result(false, "UNSUPPORTED_REQUEST_TYPE", "暂不支持该选择类型", request_type, option_id)


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
				return terminal_result
	return none_result


func _resolve_card_reward_choice(request, option) -> Dictionary:
	var request_type := str(request.get("request_type"))
	var option_id := str(option.get("id"))
	var payload = option.get("payload")
	if not payload is Dictionary:
		return _choice_result(false, "INVALID_PAYLOAD", "奖励选项无效", request_type, option_id)
	var action := str(payload.get("action", ""))
	match action:
		"skip":
			clear_choice_request()
			_complete_choice_context_room(request)
			return _choice_result(true, "CARD_REWARD_SKIPPED", "跳过奖励", request_type, option_id)
		"take_card":
			var card = payload.get("card")
			if card == null or player == null or player.card_manager == null:
				return _choice_result(false, "INVALID_PAYLOAD", "奖励卡牌无效", request_type, option_id)
			player.card_manager.add_to_pile("deck", card, StmTypes.PilePosType.BOTTOM)
			clear_choice_request()
			_complete_choice_context_room(request)
			return _choice_result(true, "CARD_REWARD_TAKEN", "获得 %s" % _choice_card_display_name(card), request_type, option_id)
		_:
			return _choice_result(false, "INVALID_PAYLOAD", "奖励选项无效", request_type, option_id)


func _complete_choice_context_room(request) -> void:
	if request == null:
		return
	var context = request.get("context")
	if not context is Dictionary:
		return
	var room = context.get("room")
	if room != null and room.has_method("complete"):
		room.complete(self)


func _choice_card_display_name(card) -> String:
	if card == null:
		return "未知"
	var card_name = card.get("card_name")
	return str(card_name) if card_name != null else "未知"


func _choice_result(ok: bool, code: String, message: String, request_type: String = "", selected_option_id: String = "") -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"request_type": request_type,
		"selected_option_id": selected_option_id,
	}


func _try_new_global(class_name_text: String):
	for item in ProjectSettings.get_global_class_list():
		if item.get("class") == class_name_text:
			var path = item.get("path", "")
			if path != "":
				var script = load(path)
				if script != null:
					return script.new()
	return null
