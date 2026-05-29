extends GutTest

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")


func test_choice_option_stores_fields() -> void:
	# Given：一个选择项包含显示文本、详情、payload 和 enabled。
	var payload := {"action": "skip"}
	# When：创建 ChoiceOption。
	var option = ChoiceOptionScript.new("skip_reward", "跳过奖励", "不获得卡牌", payload, false)
	# Then：字段按原样保存。
	assert_eq(option.id, "skip_reward")
	assert_eq(option.label, "跳过奖励")
	assert_eq(option.detail, "不获得卡牌")
	assert_eq(option.payload, payload)
	assert_false(option.enabled)


func test_choice_request_finds_options_by_id() -> void:
	# Given：一个包含两个 option 的选择请求。
	var take = ChoiceOptionScript.new("take_strike", "打击", "1 费", {"action": "take_card"}, true)
	var skip = ChoiceOptionScript.new("skip_reward", "跳过奖励", "", {"action": "skip"}, true)
	var request = ChoiceRequestScript.new(
		"combat_card_reward",
		"选择一张奖励卡牌",
		"card_reward",
		[take, skip],
		1,
		false,
		{"room": null}
	)
	# When/Then：能通过 id 查找 option。
	assert_eq(request.id, "combat_card_reward")
	assert_eq(request.title, "选择一张奖励卡牌")
	assert_eq(request.request_type, "card_reward")
	assert_eq(request.max_select, 1)
	assert_false(request.must_select)
	assert_eq(request.context.get("room"), null)
	assert_eq(request.get_option("take_strike"), take)
	assert_eq(request.get_option("skip_reward"), skip)
	assert_null(request.get_option("missing"))
	assert_true(request.has_option("take_strike"))
	assert_false(request.has_option("missing"))


func test_choice_request_enabled_options_filters_disabled_options() -> void:
	# Given：一个 enabled option 和一个 disabled option。
	var enabled = ChoiceOptionScript.new("enabled", "可选", "", {}, true)
	var disabled = ChoiceOptionScript.new("disabled", "不可选", "", {}, false)
	var request = ChoiceRequestScript.new("request", "标题", "test", [enabled, disabled])
	# When：读取 enabled options。
	var options: Array = request.enabled_options()
	# Then：只返回 enabled 项。
	assert_eq(options.size(), 1)
	assert_eq(options[0], enabled)


func test_game_state_sets_and_clears_choice_request() -> void:
	# Given：一个 GameState 和一个 ChoiceRequest。
	var game_state = StmGameState.new(null)
	var request = ChoiceRequestScript.new("request", "标题", "unsupported", [])
	# When：设置当前选择请求。
	game_state.set_choice_request(request)
	# Then：GameState 进入等待选择状态。
	assert_true(game_state.has_choice_request())
	assert_eq(game_state.current_choice_request, request)
	# When：清空选择请求。
	game_state.clear_choice_request()
	# Then：等待选择状态结束。
	assert_false(game_state.has_choice_request())
	assert_null(game_state.current_choice_request)


func test_submit_choice_reports_no_request() -> void:
	# Given：没有当前选择请求。
	var game_state = StmGameState.new(null)
	# When：提交选择。
	var result: Dictionary = game_state.submit_choice("anything")
	# Then：返回 NO_CHOICE_REQUEST。
	assert_false(result.ok)
	assert_eq(result.code, "NO_CHOICE_REQUEST")


func test_submit_choice_reports_missing_option() -> void:
	# Given：当前 request 不包含目标 option。
	var game_state = StmGameState.new(null)
	var request = ChoiceRequestScript.new("request", "标题", "unsupported", [])
	game_state.set_choice_request(request)
	# When：提交不存在的 option。
	var result: Dictionary = game_state.submit_choice("missing")
	# Then：返回 OPTION_NOT_FOUND。
	assert_false(result.ok)
	assert_eq(result.code, "OPTION_NOT_FOUND")


func test_submit_choice_reports_disabled_option() -> void:
	# Given：当前 request 中 option 被禁用。
	var game_state = StmGameState.new(null)
	var disabled = ChoiceOptionScript.new("disabled", "不可选", "", {}, false)
	var request = ChoiceRequestScript.new("request", "标题", "unsupported", [disabled])
	game_state.set_choice_request(request)
	# When：提交 disabled option。
	var result: Dictionary = game_state.submit_choice("disabled")
	# Then：返回 OPTION_DISABLED。
	assert_false(result.ok)
	assert_eq(result.code, "OPTION_DISABLED")


func test_submit_choice_reports_unsupported_request_type() -> void:
	# Given：当前 request 类型不是 v1 支持的 card_reward。
	var game_state = StmGameState.new(null)
	var option = ChoiceOptionScript.new("option", "选项", "", {}, true)
	var request = ChoiceRequestScript.new("request", "标题", "event_choice", [option])
	game_state.set_choice_request(request)
	# When：提交该 option。
	var result: Dictionary = game_state.submit_choice("option")
	# Then：返回 UNSUPPORTED_REQUEST_TYPE。
	assert_false(result.ok)
	assert_eq(result.code, "UNSUPPORTED_REQUEST_TYPE")
	assert_eq(result.request_type, "event_choice")
