extends GutTest

const StmGameState := preload("res://scripts/stm/engine/game_state.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const CardStrikeScript := preload("res://scripts/stm/cards/test/strike.gd")


func test_choice_option_stores_basic_fields_and_payload_copy() -> void:
	# Given：一个奖励选项 payload。
	var payload := {"action": "take_card", "card_id": "strike"}
	# When：创建 ChoiceOption。
	var option = ChoiceOptionScript.new("take_strike", "拿取打击", "加入牌组", payload, true)
	# Then：字段稳定保存，payload 为复制值。
	assert_eq(option.id, "take_strike")
	assert_eq(option.label, "拿取打击")
	assert_eq(option.detail, "加入牌组")
	assert_true(option.enabled)
	assert_eq(option.payload.get("action"), "take_card")
	payload["action"] = "changed"
	assert_eq(option.payload.get("action"), "take_card")


func test_choice_option_to_dict_returns_value_shape() -> void:
	# Given：一个 ChoiceOption。
	var option = ChoiceOptionScript.new("skip", "跳过", "不要奖励", {"action": "skip"}, false)
	# When：转换为字典。
	var data: Dictionary = option.to_dict()
	# Then：返回 UI 可用的稳定 shape。
	assert_eq(data.get("id"), "skip")
	assert_eq(data.get("label"), "跳过")
	assert_eq(data.get("detail"), "不要奖励")
	assert_eq(data.get("payload").get("action"), "skip")
	assert_false(data.get("enabled"))


func test_choice_request_stores_options_and_context_copy() -> void:
	# Given：两个选项和上下文。
	var options := [
		ChoiceOptionScript.new("take", "拿取", "", {"action": "take_card"}, true),
		ChoiceOptionScript.new("skip", "跳过", "", {"action": "skip"}, true),
	]
	var context := {"source": "combat_reward"}
	# When：创建 ChoiceRequest。
	var request = ChoiceRequestScript.new("reward", "选择奖励", "card_reward", options, 1, false, context)
	# Then：字段稳定保存，context 为复制值。
	assert_eq(request.id, "reward")
	assert_eq(request.title, "选择奖励")
	assert_eq(request.request_type, "card_reward")
	assert_eq(request.min_select, 1)
	assert_false(request.can_cancel)
	assert_eq(request.options.size(), 2)
	assert_eq(request.context.get("source"), "combat_reward")
	context["source"] = "changed"
	assert_eq(request.context.get("source"), "combat_reward")


func test_choice_request_get_option_returns_matching_option() -> void:
	# Given：一个包含 take / skip 的 ChoiceRequest。
	var take = ChoiceOptionScript.new("take", "拿取", "", {}, true)
	var skip = ChoiceOptionScript.new("skip", "跳过", "", {}, true)
	var request = ChoiceRequestScript.new("reward", "选择奖励", "card_reward", [take, skip])
	# When / Then：能按 id 找到选项，未知 id 返回 null。
	assert_eq(request.get_option("take"), take)
	assert_eq(request.get_option("skip"), skip)
	assert_null(request.get_option("missing"))


func test_game_state_choice_request_lifecycle() -> void:
	# Given：一个 GameState 和一个 ChoiceRequest。
	var game_state = StmGameState.new(null)
	var request = ChoiceRequestScript.new("reward", "选择奖励", "card_reward", [])
	# When / Then：可以设置、查询、清除选择请求。
	assert_false(game_state.has_choice_request())
	game_state.set_choice_request(request)
	assert_true(game_state.has_choice_request())
	assert_eq(game_state.current_choice_request, request)
	game_state.clear_choice_request()
	assert_false(game_state.has_choice_request())
	assert_null(game_state.current_choice_request)


func test_submit_choice_reports_missing_request_option_and_disabled_option() -> void:
	# Given：一个 request 只有 disabled option。
	var game_state = StmGameState.new(null)
	var disabled = ChoiceOptionScript.new("disabled", "不可选", "", {}, false)
	var request = ChoiceRequestScript.new("request", "标题", "unsupported", [disabled])
	game_state.set_choice_request(request)
	# When：提交 missing option。
	var missing_result: Dictionary = game_state.submit_choice("missing")
	# Then：返回 OPTION_NOT_FOUND。
	assert_false(missing_result.ok)
	assert_eq(missing_result.code, "OPTION_NOT_FOUND")
	# When：提交 disabled option。
	var disabled_result: Dictionary = game_state.submit_choice("disabled")
	# Then：返回 OPTION_DISABLED。
	assert_false(disabled_result.ok)
	assert_eq(disabled_result.code, "OPTION_DISABLED")


func test_submit_choice_reports_unsupported_request_type() -> void:
	# Given：当前 request 类型不是 v1 支持的 choice 类型。
	var game_state = StmGameState.new(null)
	var option = ChoiceOptionScript.new("option", "选项", "", {}, true)
	var request = ChoiceRequestScript.new("request", "标题", "mystery_choice", [option])
	game_state.set_choice_request(request)
	# When：提交该 option。
	var result: Dictionary = game_state.submit_choice("option")
	# Then：返回 UNSUPPORTED_REQUEST_TYPE。
	assert_false(result.ok)
	assert_eq(result.code, "UNSUPPORTED_REQUEST_TYPE")
	assert_eq(result.request_type, "mystery_choice")
