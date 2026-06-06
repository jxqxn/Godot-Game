extends GutTest

const PRESSURE_ENCOUNTER_STATE_PATH := "res://scripts/stm/encounters/pressure/pressure_encounter_state.gd"


func test_pressure_v1_1_refresh_uses_seeded_stock_without_losing_ungrasped_candidates() -> void:
	# Given：压力遭遇使用固定 seed 和较小浮现页，且当前候选都还没有被 grasp。
	var pressure_state = _create_pressure_state()
	if not _configure_seeded_refresh(pressure_state, 2, 7):
		return
	# When：连续两次用同一 seed 重新浮现。
	pressure_state.handle_pressure_action({"pressure_action": "refresh"})
	var first_page := _card_ids(pressure_state.emergence_pool)
	if not _set_refresh_seed(pressure_state, 7):
		return
	pressure_state.focus_points = 3
	pressure_state.handle_pressure_action({"pressure_action": "refresh"})
	var second_page := _card_ids(pressure_state.emergence_pool)
	# Then：未抓住的候选不会永久消失，同一 seed 下结果稳定。
	assert_eq(first_page.size(), 2)
	assert_eq(second_page, first_page)


func test_pressure_v1_1_grasp_removes_candidate_from_stock_until_discard_returns_it() -> void:
	# Given：observed_instability 在当前浮现页和库存中。
	var pressure_state = _create_pressure_state()
	assert_true(_candidate_stock_ids(pressure_state).has("observed_instability"))
	# When：抓住该候选。
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "observed_instability"})
	# Then：候选进入 working_memory，并离开当前库存可抽范围。
	assert_true(_card_ids(pressure_state.working_memory).has("observed_instability"))
	assert_false(_candidate_stock_ids(pressure_state).has("observed_instability"))
	# When：从 working_memory 放弃该候选。
	pressure_state.handle_pressure_action({"pressure_action": "discard", "card_id": "observed_instability"})
	# Then：候选释放格子并回到 stock。
	assert_false(_card_ids(pressure_state.working_memory).has("observed_instability"))
	assert_true(_candidate_stock_ids(pressure_state).has("observed_instability"))


func test_pressure_v1_1_discard_only_accepts_working_memory_candidates() -> void:
	# Given：observed_instability 只在当前浮现页，还没有进入 working_memory。
	var pressure_state = _create_pressure_state()
	assert_true(_card_ids(pressure_state.emergence_pool).has("observed_instability"))
	# When：尝试直接 discard 浮现页候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "discard",
		"card_id": "observed_instability",
	})
	# Then：discard 失败，浮现页候选不会被当成已买入候选处理。
	assert_false(bool(result.get("ok", true)))
	assert_eq(result.get("code"), "PRESSURE_CARD_NOT_IN_WORKING_MEMORY")
	assert_true(_card_ids(pressure_state.emergence_pool).has("observed_instability"))


func test_pressure_v1_1_express_moves_candidate_to_used_and_keeps_it_out_of_stock() -> void:
	# Given：observed_instability 已经进入 working_memory。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "observed_instability"})
	# When：表达该候选。
	pressure_state.handle_pressure_action({"pressure_action": "express", "card_id": "observed_instability"})
	# Then：候选进入 used，不回到当前 stock。
	assert_true(_card_ids(pressure_state.used_cards).has("observed_instability"))
	assert_true(_candidate_pile_ids(pressure_state, "used").has("observed_instability"))
	assert_false(_candidate_stock_ids(pressure_state).has("observed_instability"))


func test_pressure_v1_1_auto_execution_generates_action_rate_events_and_summaries() -> void:
	# Given：一个有行动倾向、关系信任和压力的压力遭遇。
	var pressure_state = _create_pressure_state()
	pressure_state.action_tendency_tracks["forceful_response"] = 3
	pressure_state.situation_tracks["ally_trust"] = 1
	pressure_state.situation_tracks["pressure"] = 2
	# When：进入自动执行。
	pressure_state.resolve_auto_resolution()
	# Then：自动执行结果包含 dominant_action、outcome_rate、事件流、主结果和价值汇总。
	assert_eq(pressure_state.final_result.get("dominant_action"), "forceful_response")
	assert_true(pressure_state.final_result.has("outcome_rate"))
	assert_true(_dict_int(pressure_state.final_result, "outcome_rate") >= 0)
	assert_true(_dict_int(pressure_state.final_result, "outcome_rate") <= 100)
	assert_true(_event_types(_auto_execution_events(pressure_state)).has("objective_progress"))
	assert_true(_event_types(_auto_execution_events(pressure_state)).has("relationship_synergy"))
	assert_false(_object_dictionary(pressure_state, "final_consequence").is_empty())
	assert_false(_object_dictionary(pressure_state, "value_summary").is_empty())


func test_pressure_v1_1_outcome_rate_uses_pressure_and_ally_trust_and_clamps() -> void:
	# Given：两个 dominant_action 相同但局势压力不同的压力遭遇。
	var supported_state = _create_pressure_state()
	supported_state.action_tendency_tracks["steady_response"] = 4
	supported_state.situation_tracks["ally_trust"] = 2
	supported_state.situation_tracks["pressure"] = 0
	var pressured_state = _create_pressure_state()
	pressured_state.action_tendency_tracks["steady_response"] = 4
	pressured_state.situation_tracks["ally_trust"] = 0
	pressured_state.situation_tracks["pressure"] = 6
	pressured_state.chain_counts["emotion_unquieted"] = 2
	# When：分别自动执行。
	supported_state.resolve_auto_resolution()
	pressured_state.resolve_auto_resolution()
	# Then：支持更高、压力更低的一方 outcome_rate 更高，且二者都被限制在 0..100。
	var supported_rate := _dict_int(supported_state.final_result, "outcome_rate")
	var pressured_rate := _dict_int(pressured_state.final_result, "outcome_rate")
	assert_gt(supported_rate, pressured_rate)
	assert_true(supported_rate >= 0 and supported_rate <= 100)
	assert_true(pressured_rate >= 0 and pressured_rate <= 100)


func test_pressure_v1_1_auto_execution_locks_snapshot_and_rejects_late_input() -> void:
	# Given：压力遭遇已经进入自动执行并生成结果。
	var pressure_state = _create_pressure_state()
	pressure_state.action_tendency_tracks["forceful_response"] = 4
	pressure_state.resolve_auto_resolution()
	var locked_rate := _dict_int(pressure_state.final_result, "outcome_rate")
	# When：自动执行后再尝试操作或篡改源字段。
	var late_result: Dictionary = pressure_state.handle_pressure_action({"pressure_action": "refresh"})
	pressure_state.action_tendency_tracks["forceful_response"] = 99
	pressure_state.situation_tracks["pressure"] = 99
	pressure_state.resolve_auto_resolution()
	# Then：输入被锁定，最终结果仍来自自动执行快照。
	assert_false(bool(late_result.get("ok", true)))
	assert_eq(late_result.get("code"), "PRESSURE_ENCOUNTER_COMPLETED")
	assert_eq(_dict_int(pressure_state.final_result, "outcome_rate"), locked_rate)
	assert_false(_object_dictionary(pressure_state, "locked_auto_execution_snapshot").is_empty())


func test_pressure_v1_1_auto_execution_events_have_extensible_schema() -> void:
	# Given：一个会生成多类自动执行事件的压力遭遇。
	var pressure_state = _create_pressure_state()
	pressure_state.action_tendency_tracks["freeze_response"] = 3
	pressure_state.chain_counts["emotion_unquieted"] = 1
	pressure_state.quieted_cards.append({"id": "hands_shaking", "chain_tag": "emotion"})
	# When：进入自动执行。
	pressure_state.resolve_auto_resolution()
	# Then：每条事件都有 v1.1 最小字段，event_type 使用可扩展字符串。
	var events := _auto_execution_events(pressure_state)
	assert_gt(events.size(), 0)
	for event in events:
		assert_true(event.has("event_id"))
		assert_true(event.has("event_type"))
		assert_true(event.has("display_text"))
		assert_true(event.has("severity"))
		assert_true(event.has("value_delta"))
		assert_true(event.has("source_ids"))
		assert_eq(typeof(event.get("event_type")), TYPE_STRING)


func _create_pressure_state():
	var pressure_state_script = load(PRESSURE_ENCOUNTER_STATE_PATH)
	var pressure_state = pressure_state_script.new()
	pressure_state.initialize("debug_pressure_encounter")
	return pressure_state


func _card_ids(cards: Array) -> Array:
	var ids: Array = []
	for card in cards:
		ids.append(str(card.get("id", "")))
	return ids


func _candidate_stock_ids(pressure_state) -> Array:
	return _candidate_pile_ids(pressure_state, "stock")


func _candidate_pile_ids(pressure_state, pile_name: String) -> Array:
	var candidate_piles := _object_dictionary(pressure_state, "candidate_piles")
	if not candidate_piles.has(pile_name):
		return []
	return _card_ids(candidate_piles.get(pile_name, []))


func _event_types(events: Array) -> Array:
	var types: Array = []
	for event in events:
		types.append(str(event.get("event_type", "")))
	return types


func _configure_seeded_refresh(pressure_state, page_size: int, seed: int) -> bool:
	if not pressure_state.has_method("set_refresh_page_size"):
		assert_true(false, "PressureEncounterState 应支持 set_refresh_page_size")
		return false
	if not pressure_state.has_method("set_refresh_seed"):
		assert_true(false, "PressureEncounterState 应支持 set_refresh_seed")
		return false
	pressure_state.set_refresh_page_size(page_size)
	pressure_state.set_refresh_seed(seed)
	return true


func _set_refresh_seed(pressure_state, seed: int) -> bool:
	if not pressure_state.has_method("set_refresh_seed"):
		assert_true(false, "PressureEncounterState 应支持 set_refresh_seed")
		return false
	pressure_state.set_refresh_seed(seed)
	return true


func _object_dictionary(object, property_name: String) -> Dictionary:
	var value = object.get(property_name)
	if value is Dictionary:
		return value
	return {}


func _object_array(object, property_name: String) -> Array:
	var value = object.get(property_name)
	if value is Array:
		return value
	return []


func _auto_execution_events(pressure_state) -> Array:
	return _object_array(pressure_state, "auto_execution_events")


func _dict_int(values: Dictionary, key: String) -> int:
	var value = values.get(key)
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		return int(value)
	return -1
