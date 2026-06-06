extends GutTest

const PRESSURE_ENCOUNTER_STATE_PATH := "res://scripts/stm/encounters/pressure/pressure_encounter_state.gd"
const EventRoomScript := preload("res://scripts/stm/rooms/event_room.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")


func test_pressure_state_builds_initial_choice_request() -> void:
	# Given：一个新建的 PressureEncounterState。
	var script_exists := ResourceLoader.exists(PRESSURE_ENCOUNTER_STATE_PATH)
	assert_true(script_exists, "PressureEncounterState 脚本应该存在")
	if not script_exists:
		return
	var pressure_state_script = load(PRESSURE_ENCOUNTER_STATE_PATH)
	assert_not_null(pressure_state_script, "PressureEncounterState 脚本应该可以加载")
	if pressure_state_script == null:
		return
	var pressure_state = pressure_state_script.new()
	# When：初始化 debug_pressure_encounter 并生成选择请求。
	pressure_state.initialize("debug_pressure_encounter")
	var request = pressure_state.build_choice_request()
	# Then：请求类型和首批稳定选项符合压力遭遇 v1 的最小入口。
	assert_not_null(request)
	assert_eq(request.request_type, "pressure_encounter_choice")
	assert_true(str(request.title).contains("压力节点"))
	assert_not_null(request.get_option("grasp_observed_instability"))
	assert_not_null(request.get_option("discard_observed_instability"))
	assert_not_null(request.get_option("refresh"))


func test_pressure_event_enter_creates_first_pressure_encounter_choice_request() -> void:
	# Given：一个手动构造的 debug_pressure_encounter 事件房。
	var room = EventRoomScript.new()
	room.set_room_payload({"event_id": "debug_pressure_encounter"})
	var game_state = _create_game_state()
	# When：进入房间。
	room.enter(game_state)
	# Then：GameState 持有压力遭遇，并收到 pressure_encounter_choice。
	assert_not_null(game_state.current_pressure_encounter)
	assert_true(game_state.has_choice_request())
	var request = game_state.current_choice_request
	assert_eq(request.request_type, "pressure_encounter_choice")
	assert_eq(request.id, "debug_pressure_encounter")
	assert_eq(request.context.get("room"), room)
	assert_eq(request.context.get("event_id"), "debug_pressure_encounter")
	assert_true(str(request.title).contains("压力节点"))
	assert_not_null(request.get_option("grasp_observed_instability"))
	assert_not_null(request.get_option("discard_observed_instability"))
	assert_not_null(request.get_option("refresh"))


func test_pressure_choice_request_uses_stable_node_one_pool_and_payloads() -> void:
	# Given：一个已初始化的 debug_pressure_encounter 状态对象。
	var pressure_state = _create_pressure_state()
	# When：生成当前压力节点的选择请求。
	var request = pressure_state.build_choice_request()
	# Then：首节点固定候选池和操作 payload 保持稳定可测。
	assert_not_null(request.get_option("grasp_observed_instability"))
	assert_not_null(request.get_option("grasp_ally_waiting"))
	assert_not_null(request.get_option("grasp_hands_shaking"))
	assert_not_null(request.get_option("grasp_basic_procedure"))
	var grasp = request.get_option("grasp_observed_instability")
	assert_eq(grasp.payload.get("action"), "pressure_action")
	assert_eq(grasp.payload.get("pressure_action"), "grasp")
	assert_eq(grasp.payload.get("card_id"), "observed_instability")
	var discard = request.get_option("discard_observed_instability")
	assert_eq(discard.payload.get("action"), "pressure_action")
	assert_eq(discard.payload.get("pressure_action"), "discard")
	assert_eq(discard.payload.get("card_id"), "observed_instability")
	var refresh = request.get_option("refresh")
	assert_eq(refresh.payload.get("action"), "pressure_action")
	assert_eq(refresh.payload.get("pressure_action"), "refresh")
	assert_false(refresh.payload.has("card_id"))


func test_submit_pressure_choice_routes_through_choice_resolver_bridge() -> void:
	# Given：玩家通过事件房进入一个压力遭遇选择。
	var room = EventRoomScript.new()
	room.set_room_payload({"event_id": "debug_pressure_encounter"})
	var game_state = _create_game_state()
	room.enter(game_state)
	# When：通过 GameState 公共入口提交压力行动。
	var result: Dictionary = game_state.submit_choice("grasp_observed_instability")
	# Then：ChoiceResolver 只负责桥接，当前压力遭遇继续持有并刷新请求。
	assert_true(bool(result.get("ok", false)))
	assert_eq(result.get("code"), "PRESSURE_ACTION_HANDLED")
	assert_eq(result.get("request_type"), "pressure_encounter_choice")
	assert_eq(result.get("selected_option_id"), "grasp_observed_instability")
	assert_not_null(game_state.current_pressure_encounter)
	assert_true(game_state.has_choice_request())
	assert_eq(game_state.current_choice_request.request_type, "pressure_encounter_choice")
	assert_eq(game_state.current_choice_request.context.get("room"), room)
	assert_false(room.is_completed)


func test_pressure_choice_grasp_card_moves_card_to_working_memory() -> void:
	# Given：首节点浮现池中有 observed_instability。
	var pressure_state = _create_pressure_state()
	var before_focus: int = pressure_state.focus_points
	var before_observation: int = int(pressure_state.chain_counts.get("observation", 0))
	var before_forceful: int = int(pressure_state.action_tendency_tracks.get("forceful_response", 0))
	# When：处理 grasp_observed_instability。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "grasp",
		"card_id": "observed_instability",
	})
	# Then：该卡进入工作记忆，离开浮现池，消耗 1 点专注，并立刻形成观察压力。
	assert_true(bool(result.get("ok", false)))
	assert_eq(result.get("code"), "PRESSURE_ACTION_HANDLED")
	assert_eq(pressure_state.focus_points, before_focus - 1)
	assert_true(_card_ids(pressure_state.working_memory).has("observed_instability"))
	assert_false(_card_ids(pressure_state.emergence_pool).has("observed_instability"))
	assert_eq(int(pressure_state.chain_counts.get("observation", 0)), before_observation + 1)
	assert_eq(int(pressure_state.action_tendency_tracks.get("forceful_response", 0)), before_forceful + 1)


func test_pressure_choice_refresh_increases_pressure() -> void:
	# Given：observed_instability 已占用工作记忆。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({
		"pressure_action": "grasp",
		"card_id": "observed_instability",
	})
	var before_focus: int = pressure_state.focus_points
	var before_pressure: int = int(pressure_state.situation_tracks.get("pressure", 0))
	# When：重新浮现当前节点候选。
	var result: Dictionary = pressure_state.handle_pressure_action({"pressure_action": "refresh"})
	# Then：刷新有压力代价，并过滤仍在工作记忆中的候选。
	assert_true(bool(result.get("ok", false)))
	assert_eq(pressure_state.focus_points, before_focus - 1)
	assert_eq(int(pressure_state.situation_tracks.get("pressure", 0)), before_pressure + 1)
	assert_false(_card_ids(pressure_state.emergence_pool).has("observed_instability"))
	assert_true(_card_ids(pressure_state.emergence_pool).has("ally_waiting"))


func test_pressure_choice_discard_releases_working_memory_slot() -> void:
	# Given：observed_instability 已在工作记忆中。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({
		"pressure_action": "grasp",
		"card_id": "observed_instability",
	})
	var before_focus: int = pressure_state.focus_points
	# When：放弃该候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "discard",
		"card_id": "observed_instability",
	})
	# Then：工作记忆格子释放，discard 不消耗专注。
	assert_true(bool(result.get("ok", false)))
	assert_eq(pressure_state.focus_points, before_focus)
	assert_false(_card_ids(pressure_state.working_memory).has("observed_instability"))


func test_pressure_grasp_option_is_disabled_when_working_memory_is_full() -> void:
	# Given：工作记忆已经占满 3 个格子。
	var pressure_state = _create_pressure_state()
	pressure_state.working_memory = [
		{"id": "slot_a"},
		{"id": "slot_b"},
		{"id": "slot_c"},
	]
	# When：重新生成选择请求。
	var request = pressure_state.build_choice_request()
	# Then：仍在浮现池中的候选不能再被 grasp。
	var grasp_basic = request.get_option("grasp_basic_procedure")
	assert_not_null(grasp_basic)
	assert_false(bool(grasp_basic.enabled))


func test_pressure_quiet_emotion_can_create_insight_value() -> void:
	# Given：hands_shaking 已进入工作记忆。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "hands_shaking"})
	var before_steady: int = int(pressure_state.action_tendency_tracks.get("steady_response", 0))
	var before_focus: int = pressure_state.focus_points
	# When：安抚该情绪候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "quiet",
		"card_id": "hands_shaking",
	})
	# Then：quiet 把情绪转化为真实风险信息，至少形成 steady_response +1。
	assert_true(bool(result.get("ok", false)))
	assert_eq(pressure_state.focus_points, before_focus - 1)
	assert_eq(int(pressure_state.action_tendency_tracks.get("steady_response", 0)), before_steady + 1)
	assert_true(_card_ids(pressure_state.quieted_cards).has("hands_shaking"))


func test_pressure_quiet_prevents_panic_spiral_progress() -> void:
	# Given：emotion_unquieted 已经接近 panic_spiral 阈值，hands_shaking 在工作记忆中。
	var pressure_state = _create_pressure_state()
	pressure_state.chain_counts["emotion_unquieted"] = 1
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "hands_shaking"})
	# When：安抚该情绪候选。
	pressure_state.handle_pressure_action({
		"pressure_action": "quiet",
		"card_id": "hands_shaking",
	})
	# Then：该卡造成的未安抚情绪累计被移除，也不会触发 panic_spiral。
	assert_eq(int(pressure_state.chain_counts.get("emotion_unquieted", 0)), 1)
	assert_false(pressure_state.triggered_cores.has("panic_spiral"))


func test_pressure_grasp_emotion_adds_unquieted_risk_until_quieted() -> void:
	# Given：首节点浮现池中有 hands_shaking 情绪候选。
	var pressure_state = _create_pressure_state()
	var before_unquieted: int = int(pressure_state.chain_counts.get("emotion_unquieted", 0))
	var before_freeze: int = int(pressure_state.action_tendency_tracks.get("freeze_response", 0))
	# When：抓住该情绪候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "grasp",
		"card_id": "hands_shaking",
	})
	# Then：该候选在被 quiet 之前会推进未安抚情绪风险和僵住倾向。
	assert_true(bool(result.get("ok", false)))
	assert_eq(int(pressure_state.chain_counts.get("emotion_unquieted", 0)), before_unquieted + 1)
	assert_eq(int(pressure_state.action_tendency_tracks.get("freeze_response", 0)), before_freeze + 1)


func test_pressure_keep_carries_card_to_next_node() -> void:
	# Given：ally_waiting 已在工作记忆中，并且当前节点只剩 1 点专注。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "ally_waiting"})
	pressure_state.focus_points = 1
	# When：保留该候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "keep",
		"card_id": "ally_waiting",
	})
	# Then：进入下一压力节点，并且该候选继续占用工作记忆。
	assert_true(bool(result.get("ok", false)))
	assert_eq(pressure_state.node_index, 1)
	assert_eq(pressure_state.focus_points, 3)
	assert_true(_card_ids(pressure_state.working_memory).has("ally_waiting"))
	assert_true(_card_ids(pressure_state.kept_cards).has("ally_waiting"))


func test_pressure_express_card_moves_card_to_used_cards() -> void:
	# Given：observed_instability 已在工作记忆中。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "observed_instability"})
	var before_focus: int = pressure_state.focus_points
	var before_forceful: int = int(pressure_state.action_tendency_tracks.get("forceful_response", 0))
	# When：表达该观察候选。
	var result: Dictionary = pressure_state.handle_pressure_action({
		"pressure_action": "express",
		"card_id": "observed_instability",
	})
	# Then：候选进入 used_cards，离开工作记忆，并推动 forceful_response。
	assert_true(bool(result.get("ok", false)))
	assert_eq(pressure_state.focus_points, before_focus - 1)
	assert_true(_card_ids(pressure_state.used_cards).has("observed_instability"))
	assert_false(_card_ids(pressure_state.working_memory).has("observed_instability"))
	assert_eq(int(pressure_state.action_tendency_tracks.get("forceful_response", 0)), before_forceful + 1)


func test_pressure_choice_request_includes_working_memory_actions() -> void:
	# Given：工作记忆中有观察候选和情绪候选。
	var pressure_state = _create_pressure_state()
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "observed_instability"})
	pressure_state.handle_pressure_action({"pressure_action": "grasp", "card_id": "hands_shaking"})
	# When：重新生成选择请求。
	var request = pressure_state.build_choice_request()
	# Then：工作记忆候选可以 express / keep / discard，情绪候选额外可以 quiet。
	assert_not_null(request.get_option("express_observed_instability"))
	assert_not_null(request.get_option("keep_observed_instability"))
	assert_not_null(request.get_option("discard_observed_instability"))
	assert_not_null(request.get_option("express_hands_shaking"))
	assert_not_null(request.get_option("quiet_hands_shaking"))
	assert_not_null(request.get_option("keep_hands_shaking"))


func test_pressure_observation_window_triggers_forceful_bonus() -> void:
	# Given：observation 连锁已经达到核心阈值。
	var pressure_state = _create_pressure_state()
	pressure_state.chain_counts["observation"] = 2
	var before_forceful: int = int(pressure_state.action_tendency_tracks.get("forceful_response", 0))
	# When：检查核心触发。
	pressure_state.evaluate_core_triggers()
	# Then：observation_window 只触发一次，并推动 forceful_response。
	assert_true(pressure_state.triggered_cores.has("observation_window"))
	assert_eq(int(pressure_state.action_tendency_tracks.get("forceful_response", 0)), before_forceful + 1)
	pressure_state.evaluate_core_triggers()
	assert_eq(_count_value(pressure_state.triggered_cores, "observation_window"), 1)


func test_pressure_unquieted_emotion_triggers_panic_spiral() -> void:
	# Given：未安抚情绪已经达到核心阈值。
	var pressure_state = _create_pressure_state()
	pressure_state.chain_counts["emotion_unquieted"] = 2
	var before_freeze: int = int(pressure_state.action_tendency_tracks.get("freeze_response", 0))
	# When：检查核心触发。
	pressure_state.evaluate_core_triggers()
	# Then：panic_spiral 只触发一次，并推动 freeze_response。
	assert_true(pressure_state.triggered_cores.has("panic_spiral"))
	assert_eq(int(pressure_state.action_tendency_tracks.get("freeze_response", 0)), before_freeze + 1)
	pressure_state.evaluate_core_triggers()
	assert_eq(_count_value(pressure_state.triggered_cores, "panic_spiral"), 1)


func test_pressure_event_resolves_highest_action_tendency() -> void:
	# Given：forceful_response 高于其他行动倾向。
	var pressure_state = _create_pressure_state()
	pressure_state.action_tendency_tracks["steady_response"] = 1
	pressure_state.action_tendency_tracks["forceful_response"] = 3
	pressure_state.action_tendency_tracks["freeze_response"] = 0
	# When：进入固定自动结算。
	pressure_state.resolve_auto_resolution()
	# Then：最终结果由最高行动倾向自动生成。
	assert_true(pressure_state.is_completed())
	assert_eq(pressure_state.final_result.get("id"), "result_forceful")
	assert_eq(pressure_state.final_result.get("dominant_tendency"), "forceful_response")


func test_pressure_resolution_tie_uses_freeze_forceful_steady_priority() -> void:
	# Given：三条行动倾向数值相同。
	var pressure_state = _create_pressure_state()
	pressure_state.action_tendency_tracks["steady_response"] = 2
	pressure_state.action_tendency_tracks["forceful_response"] = 2
	pressure_state.action_tendency_tracks["freeze_response"] = 2
	# When：进入固定自动结算。
	pressure_state.resolve_auto_resolution()
	# Then：平局按 freeze > forceful > steady 的规格优先级结算。
	assert_eq(pressure_state.final_result.get("dominant_tendency"), "freeze_response")
	assert_eq(pressure_state.final_result.get("id"), "result_freeze")


func test_pressure_refresh_at_pressure_limit_triggers_auto_resolution() -> void:
	# Given：压力已经接近上限，但当前节点仍有不止 1 点专注。
	var pressure_state = _create_pressure_state()
	pressure_state.situation_tracks["pressure"] = 5
	pressure_state.focus_points = 3
	# When：重新浮现使压力达到上限。
	var result: Dictionary = pressure_state.handle_pressure_action({"pressure_action": "refresh"})
	# Then：遭遇立即进入固定自动结算，不等待专注点耗尽。
	assert_true(bool(result.get("ok", false)))
	assert_true(pressure_state.is_completed())
	assert_false(pressure_state.final_result.is_empty())


func test_pressure_auto_resolution_pipeline_writes_ordered_steps() -> void:
	# Given：一个可以进入最终结算的压力遭遇状态。
	var pressure_state = _create_pressure_state()
	# When：执行自动结算管线。
	pressure_state.resolve_auto_resolution()
	# Then：resolution_log 按固定顺序记录管线步骤。
	var expected_steps := [
		"LOCK_MEMORY",
		"CHECK_CORES",
		"SUMMARIZE_TENDENCIES",
		"CHOOSE_DOMINANT_TENDENCY",
		"APPLY_PRESSURE_MODIFIER",
		"APPLY_ALLY_TRUST_MODIFIER",
		"BUILD_FINAL_RESULT",
		"WRITE_RESOLUTION_LOG",
	]
	var previous_index := -1
	for step in expected_steps:
		var index := _first_log_index_with_prefix(pressure_state.resolution_log, step)
		assert_gt(index, previous_index)
		previous_index = index


func test_pressure_event_completion_marks_room_completed() -> void:
	# Given：压力遭遇已经处于第三节点最后 1 点专注。
	var room = EventRoomScript.new()
	room.set_room_payload({"event_id": "debug_pressure_encounter"})
	var game_state = _create_game_state()
	room.enter(game_state)
	game_state.current_pressure_encounter.node_index = 2
	game_state.current_pressure_encounter.focus_points = 1
	# When：通过 GameState 公共入口提交一个会消耗专注的压力行动。
	var result: Dictionary = game_state.submit_choice("refresh")
	# Then：resolver 清理选择与当前压力遭遇，并完成房间。
	assert_true(bool(result.get("ok", false)))
	assert_false(game_state.has_choice_request())
	assert_eq(game_state.current_pressure_encounter, null)
	assert_true(room.is_completed)
	assert_true(result.has("detail"))
	assert_true(result.has("state_summary"))


func test_submit_pressure_choice_invalid_payload_does_not_clear_choice_or_complete_room() -> void:
	# Given：压力遭遇选择中存在未知 pressure_action 选项。
	var room = EventRoomScript.new()
	room.set_room_payload({"event_id": "debug_pressure_encounter"})
	var game_state = _create_game_state()
	room.enter(game_state)
	game_state.current_choice_request.options.append(ChoiceOptionScript.new(
		"broken_pressure_action",
		"坏压力选项",
		"",
		{"action": "pressure_action", "pressure_action": "unknown"},
		true
	))
	# When：提交未知压力行动。
	var result: Dictionary = game_state.submit_choice("broken_pressure_action")
	# Then：返回失败，不清空 choice，不完成房间。
	assert_false(bool(result.get("ok", true)))
	assert_eq(result.get("code"), "INVALID_PAYLOAD")
	assert_true(game_state.has_choice_request())
	assert_not_null(game_state.current_pressure_encounter)
	assert_false(room.is_completed)


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


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


func _count_value(values: Array, expected) -> int:
	var count := 0
	for value in values:
		if value == expected:
			count += 1
	return count


func _first_log_index_with_prefix(logs: Array, prefix: String) -> int:
	for index in range(logs.size()):
		if str(logs[index]).begins_with(prefix):
			return index
	return -1
