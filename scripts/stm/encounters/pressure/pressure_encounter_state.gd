class_name StmPressureEncounterState
extends RefCounted

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")

const DEFAULT_REFRESH_PAGE_SIZE := 4
const OUTCOME_BASE_RATE := 50
const OUTCOME_TRACK_MULTIPLIER := 5
const OUTCOME_CORE_BONUS := 8
const OUTCOME_ALLY_TRUST_BONUS := 5
const OUTCOME_PRESSURE_PENALTY := 5
const OUTCOME_UNRESOLVED_EMOTION_PENALTY := 8
const OUTCOME_PANIC_SPIRAL_PENALTY := 5

var encounter_id: String = ""
var node_index: int = 0
var focus_points: int = 3
var max_working_memory: int = 3
var pressure_nodes: Array = []
var candidate_stock: Array = []
var candidate_piles: Dictionary = {}
var emergence_pool: Array = []
var working_memory: Array = []
var used_cards: Array = []
var kept_cards: Array = []
var quieted_cards: Array = []
var discarded_cards: Array = []
var action_tendency_tracks: Dictionary = {}
var situation_tracks: Dictionary = {}
var chain_counts: Dictionary = {}
var counted_observation_cards: Array[String] = []
var unquieted_emotion_cards: Array[String] = []
var triggered_cores: Array[String] = []
var locked_auto_execution_snapshot: Dictionary = {}
var dominant_action: String = ""
var outcome_rate: int = 0
var auto_execution_events: Array = []
var final_consequence: Dictionary = {}
var value_summary: Dictionary = {}
var final_result: Dictionary = {}
var resolution_log: Array[String] = []
var completed: bool = false
var refresh_seed: int = 1
var refresh_roll_index: int = 0
var refresh_page_size: int = DEFAULT_REFRESH_PAGE_SIZE


func initialize(p_encounter_id: String) -> void:
	encounter_id = p_encounter_id
	node_index = 0
	focus_points = 3
	completed = false
	pressure_nodes = _debug_pressure_nodes()
	candidate_stock = _current_node_cards()
	emergence_pool = candidate_stock.duplicate(true)
	working_memory.clear()
	used_cards.clear()
	kept_cards.clear()
	quieted_cards.clear()
	discarded_cards.clear()
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
	locked_auto_execution_snapshot = {}
	dominant_action = ""
	outcome_rate = 0
	auto_execution_events.clear()
	final_consequence = {}
	value_summary = {}
	final_result = {}
	resolution_log.clear()
	refresh_roll_index = 0
	refresh_page_size = DEFAULT_REFRESH_PAGE_SIZE
	_sync_candidate_piles()


func set_refresh_seed(p_seed: int) -> void:
	refresh_seed = p_seed
	refresh_roll_index = 0


func set_refresh_page_size(p_page_size: int) -> void:
	refresh_page_size = max(1, p_page_size)


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
	resolution_log.append("LOCK_IN")
	resolution_log.append("CHECK_CORES")
	evaluate_core_triggers()
	resolution_log.append("SUMMARIZE_TENDENCIES:%s" % str(action_tendency_tracks))
	locked_auto_execution_snapshot = _build_auto_execution_snapshot()
	var dominant_tendency := _dominant_action_tendency_from_snapshot(locked_auto_execution_snapshot)
	dominant_action = dominant_tendency
	resolution_log.append("CHOOSE_DOMINANT_TENDENCY:%s" % dominant_tendency)
	resolution_log.append("CHOOSE_DOMINANT_ACTION:%s" % dominant_action)
	outcome_rate = _calculate_outcome_rate(locked_auto_execution_snapshot, dominant_action)
	resolution_log.append("SHOW_OUTCOME_RATE:%d%%" % outcome_rate)
	resolution_log.append("APPLY_PRESSURE_MODIFIER:pressure=%d/%d" % [
		int(situation_tracks.get("pressure", 0)),
		int(situation_tracks.get("pressure_limit", 6)),
	])
	resolution_log.append("APPLY_ALLY_TRUST_MODIFIER:ally_trust=%d" % int(situation_tracks.get("ally_trust", 0)))
	auto_execution_events = _build_auto_execution_events(locked_auto_execution_snapshot, dominant_action, outcome_rate)
	resolution_log.append("BUILD_EXECUTION_EVENTS:%d" % auto_execution_events.size())
	resolution_log.append("EXECUTE_SEQUENCE")
	final_consequence = _build_final_consequence(dominant_action, outcome_rate, auto_execution_events)
	resolution_log.append("FINAL_CONSEQUENCE:%s" % str(final_consequence.get("result_id", "")))
	value_summary = _build_value_summary(auto_execution_events)
	resolution_log.append("VALUE_SUMMARY:%d" % int(value_summary.get("summary_items", []).size()))
	resolution_log.append("CAUSE_SUMMARY")
	final_result = {
		"id": _result_id_for_tendency(dominant_tendency),
		"dominant_tendency": dominant_tendency,
		"dominant_action": dominant_action,
		"outcome_rate": outcome_rate,
		"action_tendency_tracks": action_tendency_tracks.duplicate(true),
		"situation_tracks": situation_tracks.duplicate(true),
		"triggered_cores": triggered_cores.duplicate(),
		"auto_execution_events": auto_execution_events.duplicate(true),
		"final_consequence": final_consequence.duplicate(true),
		"value_summary": value_summary.duplicate(true),
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
	_remove_card_by_id(emergence_pool, card_id)
	_remove_card_by_id(candidate_stock, card_id)
	working_memory.append(card)
	_apply_grasp_effects(card)
	resolution_log.append("GRASP:%s" % card_id)
	_sync_candidate_piles()
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "抓住候选：%s" % _card_name(card))


func _handle_refresh() -> Dictionary:
	situation_tracks["pressure"] = int(situation_tracks.get("pressure", 0)) + 1
	resolution_log.append("REFRESH:pressure+1")
	if not _spend_focus():
		emergence_pool = _draw_emergence_page()
		_sync_candidate_piles()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "重新浮现候选")


func _handle_discard(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_IN_WORKING_MEMORY", "只能放弃已抓住的候选")
	working_memory.erase(card)
	_remove_card_by_id(kept_cards, card_id)
	discarded_cards.append(card)
	_add_card_to_stock_if_missing(card)
	resolution_log.append("DISCARD:%s" % card_id)
	_sync_candidate_piles()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "放弃候选：%s" % _card_name(card))


func _handle_quiet(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	working_memory.erase(card)
	_remove_card_by_id(kept_cards, card_id)
	quieted_cards.append(card)
	if str(card.get("chain_tag", "")) == "emotion":
		_remove_unquieted_emotion(str(card.get("id", "")))
	if card_id == "hands_shaking":
		action_tendency_tracks["steady_response"] = int(action_tendency_tracks.get("steady_response", 0)) + 1
		resolution_log.append("QUIET_INSIGHT:%s steady_response+1" % card_id)
	else:
		resolution_log.append("QUIET:%s" % card_id)
	_sync_candidate_piles()
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "安抚候选：%s" % _card_name(card))


func _handle_keep(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	if _find_card(kept_cards, card_id) == null:
		kept_cards.append(card)
	resolution_log.append("KEEP:%s" % card_id)
	_sync_candidate_piles()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "保留候选：%s" % _card_name(card))


func _handle_express(card_id: String) -> Dictionary:
	var card = _find_card(working_memory, card_id)
	if card == null:
		return _pressure_result(false, "PRESSURE_CARD_NOT_FOUND", "压力候选不存在")
	working_memory.erase(card)
	_remove_card_by_id(kept_cards, card_id)
	used_cards.append(card)
	_apply_express_effects(card)
	resolution_log.append("EXPRESS:%s" % card_id)
	_sync_candidate_piles()
	_spend_focus()
	return _pressure_result(true, "PRESSURE_ACTION_HANDLED", "表达候选：%s" % _card_name(card))


func _apply_grasp_effects(card: Dictionary) -> void:
	var card_id := str(card.get("id", ""))
	match str(card.get("chain_tag", "")):
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
	candidate_stock = _filter_out_working_memory(_current_node_cards())
	emergence_pool = _draw_emergence_page()
	resolution_log.append("ADVANCE_NODE:%d" % node_index)
	_sync_candidate_piles()


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


func _remove_card_by_id(cards: Array, card_id: String):
	for card in cards:
		if str(card.get("id", "")) == card_id:
			cards.erase(card)
			return card
	return null


func _add_card_to_stock_if_missing(card: Dictionary) -> void:
	var card_id := str(card.get("id", ""))
	if card_id.is_empty():
		return
	if _find_card(candidate_stock, card_id) != null:
		return
	candidate_stock.append(card)


func _draw_emergence_page() -> Array:
	var available := _stock_available_for_refresh()
	var ranked: Array = []
	for card in available:
		ranked.append({
			"card": card,
			"score": _stable_candidate_score(str(card.get("id", "")), refresh_seed, refresh_roll_index),
		})
	ranked.sort_custom(func(a, b): return int(a.get("score", 0)) < int(b.get("score", 0)))
	var page: Array = []
	var page_limit: int = min(refresh_page_size, ranked.size())
	for index in range(page_limit):
		page.append(ranked[index].get("card").duplicate(true))
	refresh_roll_index += 1
	return page


func _stock_available_for_refresh() -> Array:
	var blocked_ids := _working_memory_ids()
	for card in used_cards:
		blocked_ids.append(str(card.get("id", "")))
	var result: Array = []
	for card in candidate_stock:
		if not blocked_ids.has(str(card.get("id", ""))):
			result.append(card)
	return result


func _stable_candidate_score(card_id: String, seed: int, roll_index: int) -> int:
	var source := "%d:%d:%s" % [seed, roll_index, card_id]
	var score := 0
	for index in range(source.length()):
		score = int((score * 131 + source.unicode_at(index)) % 2147483647)
	return score


func _sync_candidate_piles() -> void:
	candidate_piles = {
		"stock": candidate_stock.duplicate(true),
		"emergence_pool": emergence_pool.duplicate(true),
		"working_memory": working_memory.duplicate(true),
		"used": used_cards.duplicate(true),
		"discarded": discarded_cards.duplicate(true),
	}


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
	return _dominant_action_tendency_from_tracks(action_tendency_tracks)


func _dominant_action_tendency_from_snapshot(snapshot: Dictionary) -> String:
	var tracks: Dictionary = snapshot.get("action_tendency_tracks", {})
	return _dominant_action_tendency_from_tracks(tracks)


func _dominant_action_tendency_from_tracks(tracks: Dictionary) -> String:
	var priority := ["freeze_response", "forceful_response", "steady_response"]
	var selected := ""
	var selected_value := -2147483648
	for tendency in priority:
		var value := int(tracks.get(tendency, 0))
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


func _build_auto_execution_snapshot() -> Dictionary:
	return {
		"working_memory": working_memory.duplicate(true),
		"used_cards": used_cards.duplicate(true),
		"kept_cards": kept_cards.duplicate(true),
		"quieted_cards": quieted_cards.duplicate(true),
		"triggered_cores": triggered_cores.duplicate(),
		"action_tendency_tracks": action_tendency_tracks.duplicate(true),
		"situation_tracks": situation_tracks.duplicate(true),
		"chain_counts": chain_counts.duplicate(true),
		"unquieted_emotion_cards": unquieted_emotion_cards.duplicate(),
	}


func _calculate_outcome_rate(snapshot: Dictionary, p_dominant_action: String) -> int:
	var tracks: Dictionary = snapshot.get("action_tendency_tracks", {})
	var situations: Dictionary = snapshot.get("situation_tracks", {})
	var chains: Dictionary = snapshot.get("chain_counts", {})
	var cores: Array = snapshot.get("triggered_cores", [])
	var pressure := int(situations.get("pressure", 0))
	var ally_trust := int(situations.get("ally_trust", 0))
	var unresolved_emotion := int(chains.get("emotion_unquieted", 0))
	var panic_spiral_count := 1 if cores.has("panic_spiral") else 0
	var rate := OUTCOME_BASE_RATE
	rate += int(tracks.get(p_dominant_action, 0)) * OUTCOME_TRACK_MULTIPLIER
	rate += cores.size() * OUTCOME_CORE_BONUS
	rate += ally_trust * OUTCOME_ALLY_TRUST_BONUS
	rate -= pressure * OUTCOME_PRESSURE_PENALTY
	rate -= unresolved_emotion * OUTCOME_UNRESOLVED_EMOTION_PENALTY
	rate -= panic_spiral_count * OUTCOME_PANIC_SPIRAL_PENALTY
	return _clamp_int(rate, 0, 100)


func _build_auto_execution_events(snapshot: Dictionary, p_dominant_action: String, p_outcome_rate: int) -> Array:
	var events: Array = []
	var main_goal_success := p_outcome_rate >= 50
	events.append(_auto_execution_event(
		"objective_%s" % p_dominant_action,
		"objective_progress",
		"主目标%s：%s 成果率 %d%%。" % ["推进" if main_goal_success else "受阻", p_dominant_action, p_outcome_rate],
		"positive" if main_goal_success else "negative",
		{"objective_progress": 1 if main_goal_success else 0},
		[p_dominant_action],
		["objective"],
		"dominant_action=%s" % p_dominant_action
	))
	var situations: Dictionary = snapshot.get("situation_tracks", {})
	var ally_trust := int(situations.get("ally_trust", 0))
	if ally_trust > 0:
		events.append(_auto_execution_event(
			"relationship_synergy_ally_trust",
			"relationship_synergy",
			"同伴信任在自动执行中提供了行动窗口。",
			"positive",
			{"ally_trust": 1},
			_source_ids_for_chain(snapshot, "relationship"),
			["relationship", "ally"],
			"ally_trust=%d" % ally_trust
		))
	var chains: Dictionary = snapshot.get("chain_counts", {})
	var unresolved_emotion := int(chains.get("emotion_unquieted", 0))
	var cores: Array = snapshot.get("triggered_cores", [])
	if unresolved_emotion > 0 or cores.has("panic_spiral"):
		events.append(_auto_execution_event(
			"emotion_interference_unquieted",
			"emotion_interference",
			"未安抚情绪在关键时刻制造了迟疑和噪音。",
			"negative",
			{"pressure": 1},
			_source_ids_for_chain(snapshot, "emotion"),
			["emotion"],
			"emotion_unquieted=%d" % unresolved_emotion
		))
	elif not snapshot.get("quieted_cards", []).is_empty():
		events.append(_auto_execution_event(
			"emotion_insight_quieted",
			"emotion_interference",
			"被安抚的情绪转化成了可用的风险信息。",
			"positive",
			{"steady_response": 1},
			_card_ids_from_cards(snapshot.get("quieted_cards", [])),
			["emotion", "insight"],
			"quieted_emotion"
		))
	var pressure := int(situations.get("pressure", 0))
	if pressure >= 3:
		events.append(_auto_execution_event(
			"cost_or_setup_pressure",
			"cost_or_setup",
			"高压力没有完全释放，给下一轮留下代价。",
			"negative",
			{},
			[],
			["pressure", "setup"],
			"pressure=%d" % pressure,
			{"pressure": 1}
		))
	if _events_have_no_value(events):
		events.append(_auto_execution_event(
			"neutral_no_extra_value",
			"cost_or_setup",
			"本轮没有获得额外优势，也没有留下新的明显代价。",
			"neutral",
			{},
			[],
			["neutral"],
			"no_extra_value"
		))
	return events


func _build_final_consequence(p_dominant_action: String, p_outcome_rate: int, events: Array) -> Dictionary:
	var main_goal_success := p_outcome_rate >= 50
	return {
		"result_id": _result_id_for_tendency(p_dominant_action),
		"dominant_action": p_dominant_action,
		"outcome_rate": p_outcome_rate,
		"main_goal_success": main_goal_success,
		"display_text": "%s 主目标%s，成果率 %d%%。" % [
			p_dominant_action,
			"达成" if main_goal_success else "受阻",
			p_outcome_rate,
		],
		"objective_event_count": _count_events_by_type(events, "objective_progress"),
	}


func _build_value_summary(events: Array) -> Dictionary:
	var value_delta := {}
	var next_round_delta := {}
	var summary_items: Array = []
	for event in events:
		var event_value: Dictionary = event.get("value_delta", {})
		var event_next: Dictionary = event.get("next_round_delta", {})
		_merge_int_dictionary(value_delta, event_value)
		_merge_int_dictionary(next_round_delta, event_next)
		if not event_value.is_empty() or not event_next.is_empty() or str(event.get("severity", "")) == "neutral":
			summary_items.append(str(event.get("display_text", "")))
	if summary_items.is_empty():
		summary_items.append("本轮没有获得额外优势，也没有留下新的明显代价。")
	return {
		"value_delta": value_delta,
		"next_round_delta": next_round_delta,
		"summary_items": summary_items,
	}


func _auto_execution_event(
	event_id: String,
	event_type: String,
	display_text: String,
	severity: String,
	value_delta: Dictionary,
	source_ids: Array,
	event_tags: Array = [],
	trigger_reason: String = "",
	next_round_delta: Dictionary = {}
) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": event_type,
		"display_text": display_text,
		"severity": severity,
		"value_delta": value_delta.duplicate(true),
		"source_ids": source_ids.duplicate(),
		"event_tags": event_tags.duplicate(),
		"trigger_reason": trigger_reason,
		"next_round_delta": next_round_delta.duplicate(true),
	}


func _source_ids_for_chain(snapshot: Dictionary, chain_tag: String) -> Array:
	var ids: Array = []
	for pile_name in ["used_cards", "working_memory", "kept_cards", "quieted_cards"]:
		for card in snapshot.get(pile_name, []):
			if str(card.get("chain_tag", "")) == chain_tag:
				ids.append(str(card.get("id", "")))
	return ids


func _card_ids_from_cards(cards: Array) -> Array:
	var ids: Array = []
	for card in cards:
		ids.append(str(card.get("id", "")))
	return ids


func _events_have_no_value(events: Array) -> bool:
	for event in events:
		var value_delta: Dictionary = event.get("value_delta", {})
		var next_round_delta: Dictionary = event.get("next_round_delta", {})
		if not value_delta.is_empty() or not next_round_delta.is_empty():
			return false
	return true


func _merge_int_dictionary(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = int(target.get(key, 0)) + int(source.get(key, 0))


func _count_events_by_type(events: Array, event_type: String) -> int:
	var count := 0
	for event in events:
		if str(event.get("event_type", "")) == event_type:
			count += 1
	return count


func _clamp_int(value: int, minimum: int, maximum: int) -> int:
	return min(max(value, minimum), maximum)


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
