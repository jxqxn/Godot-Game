class_name StmPressureEncounterState
extends RefCounted

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")

var encounter_id: String = ""
var node_index: int = 0
var focus_points: int = 3
var max_working_memory: int = 3
var pressure_nodes: Array = []
var emergence_pool: Array = []
var working_memory: Array = []
var used_cards: Array = []
var kept_cards: Array = []
var quieted_cards: Array = []
var action_tendency_tracks: Dictionary = {}
var situation_tracks: Dictionary = {}
var chain_counts: Dictionary = {}
var counted_observation_cards: Array[String] = []
var unquieted_emotion_cards: Array[String] = []
var triggered_cores: Array[String] = []
var final_result: Dictionary = {}
var resolution_log: Array[String] = []
var completed: bool = false


func initialize(p_encounter_id: String) -> void:
	encounter_id = p_encounter_id
	node_index = 0
	focus_points = 3
	completed = false
	pressure_nodes = _debug_pressure_nodes()
	emergence_pool = _current_node_cards()
	working_memory.clear()
	used_cards.clear()
	kept_cards.clear()
	quieted_cards.clear()
	action_tendency_tracks = {
		"steady_response": 0,
		"forceful_response": 0,
		"freeze_response": 0,
	}
	situation_tracks = {"pressure": 0, "pressure_limit": 6, "ally_trust": 0}
	chain_counts = {"observation": 0, "emotion_unquieted": 0}
	counted_observation_cards.clear()
	unquieted_emotion_cards.clear()
	triggered_cores.clear()
	final_result = {}
	resolution_log.clear()


func build_choice_request(context: Dictionary = {}):
	return ChoiceRequestScript.new(
		encounter_id,
		"压力节点 %d/%d：%s" % [node_index + 1, pressure_nodes.size(), _current_node_title()],
		"pressure_encounter_choice",
		_build_choice_options(),
		1,
		false,
		context
	)


func is_completed() -> bool:
	return completed


func evaluate_core_triggers() -> void:
	if int(chain_counts.get("observation", 0)) >= 2 and not triggered_cores.has("observation_window"):
		triggered_cores.append("observation_window")
		action_tendency_tracks["forceful_response"] = int(action_tendency_tracks.get("forceful_response", 0)) + 1
		resolution_log.append("CORE:observation_window forceful_response+1")
	if int(chain_counts.get("emotion_unquieted", 0)) >= 2 and not triggered_cores.has("panic_spiral"):
		triggered_cores.append("panic_spiral")
		action_tendency_tracks["freeze_response"] = int(action_tendency_tracks.get("freeze_response", 0)) + 1
		resolution_log.append("CORE:panic_spiral freeze_response+1")


func resolve_auto_resolution() -> void:
	if completed and not final_result.is_empty():
		return
	resolution_log.append("LOCK_MEMORY:working_memory=%d/%d" % [working_memory.size(), max_working_memory])
	resolution_log.append("CHECK_CORES")
	evaluate_core_triggers()
	resolution_log.append("SUMMARIZE_TENDENCIES:%s" % str(action_tendency_tracks))
	var dominant_tendency := _dominant_action_tendency()
	resolution_log.append("CHOOSE_DOMINANT_TENDENCY:%s" % dominant_tendency)
	resolution_log.append("APPLY_PRESSURE_MODIFIER:pressure=%d/%d" % [
		int(situation_tracks.get("pressure", 0)),
		int(situation_tracks.get("pressure_limit", 6)),
	])
	resolution_log.append("APPLY_ALLY_TRUST_MODIFIER:ally_trust=%d" % int(situation_tracks.get("ally_trust", 0)))
	final_result = {
		"id": _result_id_for_tendency(dominant_tendency),
		"dominant_tendency": dominant_tendency,
		"action_tendency_tracks": action_tendency_tracks.duplicate(true),
		"situation_tracks": situation_tracks.duplicate(true),
		"triggered_cores": triggered_cores.duplicate(),
	}
	resolution_log.append("BUILD_FINAL_RESULT:%s" % str(final_result.get("id", "")))
	resolution_log.append("WRITE_RESOLUTION_LOG")
	completed = true


func handle_pressure_action(payload: Dictionary) -> Dictionary:
	var pressure_action := str(payload.get("pressure_action", ""))
	if pressure_action.is_empty():
		return {"ok": false, "code": "INVALID_PAYLOAD", "message": "压力行动无效", "completed": completed}
	if completed:
		return _pressure_result(false, "PRESSURE_ENCOUNTER_COMPLETED", "压力遭遇已完成")
	match pressure_action:
		"grasp":
			return _handle_grasp(str(payload.get("card_id", "")))
		"refresh":
			return _handle_refresh()
		"discard":
			return _handle_discard(str(payload.get("card_id", "")))
		"quiet":
			return _handle_quiet(str(payload.get("card_id", "")))
		"keep":
			return _handle_keep(str(payload.get("card_id", "")))
		"express":
			return _handle_express(str(payload.get("card_id", "")))
		_:
			return _pressure_result(false, "INVALID_PAYLOAD", "压力行动无效")


func _handle_grasp(card_id: String) -> Dictionary:
	if working_memory.size() >= max_working_memory:
		return _pressure_result(false, "WORKING_MEMORY_FULL", "工作记忆已满")
	var card = _find_card(emergence_pool, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	emergence_pool.erase(card)
	working_memory.append(card)
	_apply_grasp_effects(card)
	resolution_log.append("GRASP:%s" % card_id)
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "抓住候选：%s" % _card_name(card))


func _handle_refresh() -> Dictionary:
	situation_tracks["pressure"] = int(situation_tracks.get("pressure", 0)) + 1
	resolution_log.append("REFRESH:pressure+1")
	if not _spend_focus():
		emergence_pool = _filter_out_working_memory(_current_node_cards())
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "重新浮现候选")


func _handle_discard(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card != null:
		working_memory.erase(card)
		resolution_log.append("DISCARD:%s" % card_id)
		return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "放弃候选：%s" % _card_name(card))
	card = _find_card(emergence_pool, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	emergence_pool.erase(card)
	resolution_log.append("DISCARD:%s" % card_id)
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "放弃候选：%s" % _card_name(card))


func _handle_quiet(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	working_memory.erase(card)
	quieted_cards.append(card)
	if str(card.get("chain_tag", "")) == "emotion":
		_remove_unquieted_emotion(str(card.get("id", "")))
	if card_id == "hands_shaking":
		action_tendency_tracks["steady_response"] = int(action_tendency_tracks.get("steady_response", 0)) + 1
		resolution_log.append("QUIET_INSIGHT:%s steady_response+1" % card_id)
	else:
		resolution_log.append("QUIET:%s" % card_id)
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "安抚候选：%s" % _card_name(card))


func _handle_keep(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	if _find_card(kept_cards, card_id) == null:
		kept_cards.append(card)
	resolution_log.append("KEEP:%s" % card_id)
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "保留候选：%s" % _card_name(card))


func _handle_express(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	working_memory.erase(card)
	used_cards.append(card)
	_apply_express_effects(card)
	resolution_log.append("EXPRESS:%s" % card_id)
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "表达候选：%s" % _card_name(card))


func _apply_grasp_effects(card: Dictionary) -> void:
	var card_id := str(card.get("id", ""))
	match str(card.get("chain_tag", "")):
		"observation":
			_register_observation_progress(card_id)
			action_tendency_tracks["forceful_response"] = int(action_tendency_tracks.get("forceful_response", 0)) + 1
		"emotion":
			_register_unquieted_emotion(card_id)
			action_tendency_tracks["freeze_response"] = int(action_tendency_tracks.get("freeze_response", 0)) + 1


func _apply_express_effects(card: Dictionary) -> void:
	var card_id := str(card.get("id", ""))
	match str(card.get("chain_tag", "")):
		"observation":
			_register_observation_progress(card_id)
			action_tendency_tracks["forceful_response"] = int(action_tendency_tracks.get("forceful_response", 0)) + 1
		"evidence":
			action_tendency_tracks["forceful_response"] = int(action_tendency_tracks.get("forceful_response", 0)) + 1
		"technique":
			action_tendency_tracks["steady_response"] = int(action_tendency_tracks.get("steady_response", 0)) + 1
		"relationship":
			situation_tracks["ally_trust"] = int(situation_tracks.get("ally_trust", 0)) + 1
		"emotion":
			_register_unquieted_emotion(card_id)
			action_tendency_tracks["freeze_response"] = int(action_tendency_tracks.get("freeze_response", 0)) + 1


func _spend_focus() -> bool:
	focus_points -= 1
	if completed:
		return false
	if int(situation_tracks.get("pressure", 0)) >= int(situation_tracks.get("pressure_limit", 6)):
		resolve_auto_resolution()
		return true
	if focus_points > 0:
		return false
	if node_index >= pressure_nodes.size() - 1:
		resolve_auto_resolution()
		return true
	_advance_to_next_node()
	return true


func _advance_to_next_node() -> void:
	node_index += 1
	focus_points = 3
	working_memory = _filter_to_kept_cards(working_memory)
	emergence_pool = _filter_out_working_memory(_current_node_cards())
	resolution_log.append("ADVANCE_NODE:%d" % node_index)


func _pressure_result(ok: bool, code: String, message: String) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"completed": completed,
		"detail": resolution_log[-1] if not resolution_log.is_empty() else "",
		"state_summary": _state_summary_text(),
	}


func _build_choice_options() -> Array:
	var options: Array = []
	for card in emergence_pool:
		var card_id := str(card.get("id", ""))
		var card_name := str(card.get("name", card_id))
		var grasp_enabled := working_memory.size() < max_working_memory
		options.append(ChoiceOptionScript.new(
			"grasp_%s" % card_id,
			"抓住：%s" % card_name,
			str(card.get("detail", "")) if grasp_enabled else "工作记忆已满",
			{"action": "pressure_action", "pressure_action": "grasp", "card_id": card_id},
			grasp_enabled
		))
		options.append(ChoiceOptionScript.new(
			"discard_%s" % card_id,
			"放弃：%s" % card_name,
			"",
			{"action": "pressure_action", "pressure_action": "discard", "card_id": card_id},
			true
		))
	for card in working_memory:
		var card_id := str(card.get("id", ""))
		var card_name := str(card.get("name", card_id))
		options.append(ChoiceOptionScript.new(
			"express_%s" % card_id,
			"表达：%s" % card_name,
			"",
			{"action": "pressure_action", "pressure_action": "express", "card_id": card_id},
			true
		))
		if str(card.get("chain_tag", "")) == "emotion":
			options.append(ChoiceOptionScript.new(
				"quiet_%s" % card_id,
				"安抚：%s" % card_name,
				"",
				{"action": "pressure_action", "pressure_action": "quiet", "card_id": card_id},
				true
			))
		options.append(ChoiceOptionScript.new(
			"keep_%s" % card_id,
			"保留：%s" % card_name,
			"",
			{"action": "pressure_action", "pressure_action": "keep", "card_id": card_id},
			true
		))
		options.append(ChoiceOptionScript.new(
			"discard_%s" % card_id,
			"放弃：%s" % card_name,
			"",
			{"action": "pressure_action", "pressure_action": "discard", "card_id": card_id},
			true
		))
	options.append(ChoiceOptionScript.new(
		"refresh",
		"重新浮现",
		"消耗 1 专注，压力 +1",
		{"action": "pressure_action", "pressure_action": "refresh"},
		true
	))
	return options


func _current_node_title() -> String:
	if node_index < 0 or node_index >= pressure_nodes.size():
		return "未知局面"
	return str(pressure_nodes[node_index].get("title", "未知局面"))


func _current_node_cards() -> Array:
	if node_index < 0 or node_index >= pressure_nodes.size():
		return []
	return pressure_nodes[node_index].get("cards", []).duplicate(true)


func _find_card(cards: Array, card_id: String):
	for card in cards:
		if str(card.get("id", "")) == card_id:
			return card
	return null


func _filter_out_working_memory(cards: Array) -> Array:
	var working_ids := _working_memory_ids()
	var result: Array = []
	for card in cards:
		if not working_ids.has(str(card.get("id", ""))):
			result.append(card)
	return result


func _filter_to_kept_cards(cards: Array) -> Array:
	var kept_ids: Array = []
	for card in kept_cards:
		kept_ids.append(str(card.get("id", "")))
	var result: Array = []
	for card in cards:
		if kept_ids.has(str(card.get("id", ""))):
			result.append(card)
	return result


func _working_memory_ids() -> Array:
	var ids: Array = []
	for card in working_memory:
		ids.append(str(card.get("id", "")))
	return ids


func _card_name(card) -> String:
	if card == null:
		return "未知"
	return str(card.get("name", card.get("id", "未知")))


func _state_summary_text() -> String:
	return "focus=%d, working_memory=%d/%d, pressure=%d/%d, ally_trust=%d, tendencies=steady:%d forceful:%d freeze:%d, cores=observation:%d/2 panic:%d/2" % [
		focus_points,
		working_memory.size(),
		max_working_memory,
		int(situation_tracks.get("pressure", 0)),
		int(situation_tracks.get("pressure_limit", 6)),
		int(situation_tracks.get("ally_trust", 0)),
		int(action_tendency_tracks.get("steady_response", 0)),
		int(action_tendency_tracks.get("forceful_response", 0)),
		int(action_tendency_tracks.get("freeze_response", 0)),
		int(chain_counts.get("observation", 0)),
		int(chain_counts.get("emotion_unquieted", 0)),
	]


func _dominant_action_tendency() -> String:
	var priority := ["freeze_response", "forceful_response", "steady_response"]
	var selected := ""
	var selected_value := -2147483648
	for tendency in priority:
		var value := int(action_tendency_tracks.get(tendency, 0))
		if value > selected_value:
			selected = tendency
			selected_value = value
	return selected


func _register_observation_progress(card_id: String) -> void:
	if counted_observation_cards.has(card_id):
		return
	counted_observation_cards.append(card_id)
	chain_counts["observation"] = int(chain_counts.get("observation", 0)) + 1


func _register_unquieted_emotion(card_id: String) -> void:
	if unquieted_emotion_cards.has(card_id):
		return
	unquieted_emotion_cards.append(card_id)
	chain_counts["emotion_unquieted"] = int(chain_counts.get("emotion_unquieted", 0)) + 1


func _remove_unquieted_emotion(card_id: String) -> void:
	if not unquieted_emotion_cards.has(card_id):
		return
	unquieted_emotion_cards.erase(card_id)
	chain_counts["emotion_unquieted"] = max(0, int(chain_counts.get("emotion_unquieted", 0)) - 1)


func _result_id_for_tendency(tendency: String) -> String:
	match tendency:
		"forceful_response":
			return "result_forceful"
		"freeze_response":
			return "result_freeze"
		_:
			return "result_steady"


func _debug_pressure_nodes() -> Array:
	return [
		{
			"title": "看清局面",
			"cards": [
				{"id": "observed_instability", "name": "对方快失控了", "detail": "观察", "chain_tag": "observation"},
				{"id": "ally_waiting", "name": "同伴在等你的判断", "detail": "关系", "chain_tag": "relationship"},
				{"id": "hands_shaking", "name": "手在发抖", "detail": "情绪", "chain_tag": "emotion"},
				{"id": "basic_procedure", "name": "按流程来", "detail": "技术", "chain_tag": "technique"},
			],
		},
		{
			"title": "说出关键信息",
			"cards": [
				{"id": "evidence_not_simple", "name": "事情不是表面那样", "detail": "证据", "chain_tag": "evidence"},
				{"id": "situation_closing_in", "name": "局势正在收紧", "detail": "观察", "chain_tag": "observation"},
				{"id": "self_doubt", "name": "我可能又搞砸了", "detail": "情绪", "chain_tag": "emotion"},
				{"id": "keep_talking", "name": "继续拖住局面", "detail": "技术", "chain_tag": "technique"},
			],
		},
		{
			"title": "临界前一秒",
			"cards": [
				{"id": "act_now", "name": "现在必须行动", "detail": "技术", "chain_tag": "technique"},
				{"id": "ally_can_hear_you", "name": "同伴听得见你", "detail": "关系", "chain_tag": "relationship"},
				{"id": "body_locks_up", "name": "身体僵住了", "detail": "情绪", "chain_tag": "emotion"},
			],
		},
	]
