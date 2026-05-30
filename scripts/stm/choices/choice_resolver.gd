class_name StmChoiceResolver
extends RefCounted


func resolve(game_state, request, option) -> Dictionary:
	if request == null:
		return _choice_result(false, "NO_CHOICE_REQUEST", "当前没有等待处理的选择")
	if option == null:
		return _choice_result(false, "OPTION_NOT_FOUND", "选项不存在", str(request.get("request_type")))
	var request_type: String = str(request.get("request_type"))
	match request_type:
		"card_reward":
			return _resolve_card_reward_choice(game_state, request, option)
		"rest_choice":
			return _resolve_rest_choice(game_state, request, option)
		"event_choice":
			return _resolve_event_choice(game_state, request, option)
		_:
			return _choice_result(false, "UNSUPPORTED_REQUEST_TYPE", "暂不支持该选择类型", request_type, str(option.get("id")))


func unsupported_choice_result(request, option_id: String, message: String = "暂不支持该选择类型") -> Dictionary:
	var request_type: String = ""
	if request != null:
		request_type = str(request.get("request_type"))
	return _choice_result(false, "UNSUPPORTED_REQUEST_TYPE", message, request_type, option_id)


func choice_result(ok: bool, code: String, message: String, request_type: String = "", selected_option_id: String = "") -> Dictionary:
	return _choice_result(ok, code, message, request_type, selected_option_id)


func _resolve_card_reward_choice(game_state, request, option) -> Dictionary:
	var request_type: String = str(request.get("request_type"))
	var option_id: String = str(option.get("id"))
	var payload_variant = option.get("payload")
	if not payload_variant is Dictionary:
		return _choice_result(false, "INVALID_PAYLOAD", "奖励选项无效", request_type, option_id)
	var payload: Dictionary = payload_variant
	var action: String = str(payload.get("action", ""))
	match action:
		"skip":
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "CARD_REWARD_SKIPPED", "跳过奖励", request_type, option_id)
		"take_card":
			var card = payload.get("card")
			if card == null or game_state == null or game_state.player == null or game_state.player.card_manager == null:
				return _choice_result(false, "INVALID_PAYLOAD", "奖励卡牌无效", request_type, option_id)
			game_state.player.card_manager.add_to_pile("deck", card, StmTypes.PilePosType.BOTTOM)
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "CARD_REWARD_TAKEN", "获得 %s" % _choice_card_display_name(card), request_type, option_id)
		_:
			return _choice_result(false, "INVALID_PAYLOAD", "奖励选项无效", request_type, option_id)


func _resolve_rest_choice(game_state, request, option) -> Dictionary:
	var request_type: String = str(request.get("request_type"))
	var option_id: String = str(option.get("id"))
	var payload_variant = option.get("payload")
	if not payload_variant is Dictionary:
		return _choice_result(false, "INVALID_PAYLOAD", "休息选项无效", request_type, option_id)
	var payload: Dictionary = payload_variant
	var action: String = str(payload.get("action", ""))
	match action:
		"rest":
			if game_state == null or game_state.player == null:
				return _choice_result(false, "INVALID_PAYLOAD", "休息选项无效", request_type, option_id)
			var before_hp: int = int(game_state.player.hp)
			var heal_amount: int = int(float(game_state.player.max_hp) * 0.3)
			game_state.player.hp = min(game_state.player.max_hp, game_state.player.hp + heal_amount)
			var after_hp: int = int(game_state.player.hp)
			_record_rest_result(request, before_hp, after_hp)
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "REST_TAKEN", "休息：恢复 %d 点 HP（%d → %d）" % [max(0, after_hp - before_hp), before_hp, after_hp], request_type, option_id)
		"skip":
			var current_hp: int = int(game_state.player.hp) if game_state != null and game_state.player != null else 0
			_record_rest_result(request, current_hp, current_hp)
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "REST_SKIPPED", "跳过休息", request_type, option_id)
		_:
			return _choice_result(false, "INVALID_PAYLOAD", "休息选项无效", request_type, option_id)


func _resolve_event_choice(game_state, request, option) -> Dictionary:
	var request_type: String = str(request.get("request_type"))
	var option_id: String = str(option.get("id"))
	var payload_variant = option.get("payload")
	if not payload_variant is Dictionary:
		return _choice_result(false, "INVALID_PAYLOAD", "事件选项无效", request_type, option_id)
	var payload: Dictionary = payload_variant
	var action: String = str(payload.get("action", ""))
	match action:
		"heal":
			if game_state == null or game_state.player == null:
				return _choice_result(false, "INVALID_PAYLOAD", "事件选项无效", request_type, option_id)
			var before_hp: int = int(game_state.player.hp)
			var heal_amount: int = int(max(0, int(payload.get("amount", 0))))
			game_state.player.hp = min(game_state.player.max_hp, game_state.player.hp + heal_amount)
			var after_hp: int = int(game_state.player.hp)
			_record_event_result(request, before_hp, after_hp, "heal")
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "EVENT_HEAL_TAKEN", "饮用泉水：恢复 %d 点 HP（%d → %d）" % [max(0, after_hp - before_hp), before_hp, after_hp], request_type, option_id)
		"leave":
			var current_hp: int = int(game_state.player.hp) if game_state != null and game_state.player != null else 0
			_record_event_result(request, current_hp, current_hp, "leave")
			game_state.clear_choice_request()
			_complete_choice_context_room(game_state, request)
			return _choice_result(true, "EVENT_LEFT", "离开清泉", request_type, option_id)
		_:
			return _choice_result(false, "INVALID_PAYLOAD", "事件选项无效", request_type, option_id)


func _record_rest_result(request, before_hp: int, after_hp: int) -> void:
	if request == null:
		return
	var context_variant = request.get("context")
	if not context_variant is Dictionary:
		return
	var context: Dictionary = context_variant
	var room = context.get("room")
	if room == null:
		return
	room.last_hp_before = before_hp
	room.last_hp_after = after_hp
	room.last_heal_amount = max(0, after_hp - before_hp)


func _record_event_result(request, before_hp: int, after_hp: int, action: String) -> void:
	if request == null:
		return
	var context_variant = request.get("context")
	if not context_variant is Dictionary:
		return
	var context: Dictionary = context_variant
	var room = context.get("room")
	if room == null:
		return
	room.last_hp_before = before_hp
	room.last_hp_after = after_hp
	room.last_event_action = action


func _complete_choice_context_room(game_state, request) -> void:
	if request == null:
		return
	var context_variant = request.get("context")
	if not context_variant is Dictionary:
		return
	var context: Dictionary = context_variant
	var room = context.get("room")
	if room != null and room.has_method("complete"):
		room.complete(game_state)


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
