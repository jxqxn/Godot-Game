extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")


func test_debug_scene_shows_initial_combat_state() -> void:
	# Given：一个策划用于查看最小战斗状态的调试场景。
	var scene = _instantiate_debug_scene()
	# When：场景启动并创建测试战斗。
	assert_not_null(scene)
	if scene == null:
		return
	# Then：界面显示玩家血量、能量、格挡、手牌和敌人血量。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("Strike"))
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("Defend"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/StrikeButton"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/DefendButton"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/EndTurnButton"))


func test_debug_scene_shows_planner_tool_surface() -> void:
	# Given：策划打开固定测试战斗的调试工具。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化并刷新所有调试面板。
	var title_text := _label_text(scene, "Layout/TitleLabel")
	# Then：界面展示玩家状态、敌人意图、手牌、抽牌堆、弃牌堆、数值输入、重开按钮和详细日志开关。
	assert_eq(title_text, "战斗调试工具")
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyIntentLabel"), "敌人意图：攻击")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyAttackLabel"), "预计攻击：6")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DrawPileLabel").contains("抽牌堆（0）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("弃牌堆（0）："))
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "70")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "3")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "0")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "20")
	var value_editor = scene.get_node_or_null("Layout/ValueEditor")
	assert_not_null(value_editor)
	assert_true(value_editor is GridContainer)
	if value_editor is GridContainer:
		assert_eq(value_editor.columns, 2)
	assert_not_null(scene.get_node_or_null("Layout/ValueEditor/ApplyValuesSpacer"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/ResetButton"))
	assert_not_null(scene.get_node_or_null("Layout/LogPanel/DetailedLogCheckBox"))
	assert_false(_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))


func test_debug_scene_records_fixed_battle_fixture_name() -> void:
	# Given：策划打开依赖固定战斗夹具的调试场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化并创建测试战斗。
	var fixture_name := str(scene.current_fixture_name)
	# Then：场景记录基础测试战斗，并仍然连接 debug 战斗和 DummyEnemy。
	assert_eq(fixture_name, "基础测试战斗")
	assert_not_null(scene.combat)
	assert_not_null(scene.enemy)
	assert_eq(scene.combat.combat_type, "debug")
	assert_eq(scene.enemy.enemy_name, "DummyEnemy")


func test_debug_scene_rejects_inconsistent_fixture_context_without_changing_state() -> void:
	# Given：调试场景已经有一场正常固定测试战斗。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	var original_game_state = scene.game_state
	var original_combat = scene.combat
	var original_enemy = scene.enemy
	var original_fixture_name := str(scene.current_fixture_name)
	var fixture = FixedBattleFixtureScript.new()
	var other_context: Dictionary = fixture.create_context()
	var mismatched_context := {
		"name": "错配测试战斗",
		"game_state": other_context["game_state"],
		"combat": other_context["combat"],
		"player": original_game_state.player,
		"enemy": original_enemy,
	}
	# When：传入一个 game_state/player 不一致、combat/enemy 不一致的 fixture context。
	var accepted: bool = scene._apply_fixture_context(mismatched_context)
	# Then：_apply_fixture_context() 返回 false，且原来的状态保持不变。
	assert_false(accepted)
	assert_true(scene.game_state == original_game_state)
	assert_true(scene.combat == original_combat)
	assert_true(scene.enemy == original_enemy)
	assert_eq(scene.current_fixture_name, original_fixture_name)


func test_debug_scene_fixture_failure_clears_old_display_and_disables_all_actions() -> void:
	# Given：调试场景已经显示一场正常战斗。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	# When：触发 _handle_fixture_failure()。
	scene._handle_fixture_failure()
	# Then：界面显示无战斗状态，并禁用全部操作按钮与应用数值按钮。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：无")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：无")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyIntentLabel"), "敌人意图：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyAttackLabel"), "预计攻击：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/HandLabel"), "手牌（0）：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/DrawPileLabel"), "抽牌堆（0）：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel"), "弃牌堆（0）：无")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "")
	assert_true(_button_disabled(scene, "Layout/Buttons/StrikeButton"))
	assert_true(_button_disabled(scene, "Layout/Buttons/DefendButton"))
	assert_true(_button_disabled(scene, "Layout/Buttons/EndTurnButton"))
	assert_true(_button_disabled(scene, "Layout/ValueEditor/ApplyValuesButton"))
	assert_eq(_label_text(scene, "Layout/StatusLabel"), "测试战斗创建失败")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("测试战斗创建失败"))


func test_debug_scene_recovers_apply_values_button_after_fixture_failure_and_restart() -> void:
	# Given：调试场景经历了一次固定战斗夹具创建失败。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	scene._handle_fixture_failure()
	assert_true(_button_disabled(scene, "Layout/ValueEditor/ApplyValuesButton"))
	# When：再次启动固定测试战斗。
	scene.start_debug_combat()
	# Then：界面恢复到可编辑战斗状态，应用数值按钮重新可用。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "70")
	assert_false(_button_disabled(scene, "Layout/ValueEditor/ApplyValuesButton"))
	assert_eq(_label_text(scene, "Layout/StatusLabel"), "等待行动")


func test_apply_values_updates_combat_state_and_display() -> void:
	# Given：策划在调试工具中输入一组合法的玩家和敌人数值。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "10")
	# When：点击应用数值按钮。
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	# Then：战斗状态、界面显示和简洁日志同时反映这次数值修改。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：40/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：9")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：10/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值：玩家 HP 设为 40，敌人 HP 设为 10"))


func test_apply_values_rejects_invalid_input_without_partial_state_change() -> void:
	# Given：当前战斗已有明确状态，策划输入一个非法敌人血量。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "不是数字")
	# When：点击应用数值按钮。
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	# Then：玩家和敌人的所有数值保持原样，并显示输入错误日志。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("输入错误：敌人血量必须是整数"))


func test_strike_button_plays_strike_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有 Strike，敌人是 DummyEnemy。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击 Strike 按钮。
	_press_button(scene, "Layout/Buttons/StrikeButton")
	# Then：敌人受到 6 点伤害，玩家消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（3）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("Strike"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))


func test_defend_button_plays_defend_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有 Defend。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击 Defend 按钮。
	_press_button(scene, "Layout/Buttons/DefendButton")
	# Then：玩家获得 5 点格挡，消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：5")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（3）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("Defend"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Defend，获得 5 点格挡"))


func test_end_turn_button_starts_next_player_turn_and_reenables_card_buttons() -> void:
	# Given：调试场景中玩家已打出 Defend 并获得 5 点格挡。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/DefendButton")
	# When：点击结束回合按钮。
	_press_button(scene, "Layout/Buttons/EndTurnButton")
	# Then：DummyEnemy 的攻击被格挡抵消 5 点，玩家只损失 1 点血量，日志刷新，并进入可继续出牌的新玩家回合。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：69/70")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("结束回合，DummyEnemy 攻击造成 1 点伤害"))
	assert_false(_button_disabled(scene, "Layout/Buttons/StrikeButton"))
	assert_false(_button_disabled(scene, "Layout/Buttons/DefendButton"))


func test_detailed_log_toggle_switches_between_simple_and_detailed_entries() -> void:
	# Given：策划已经打出 Strike，简洁日志只显示关键结果。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/StrikeButton")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	# When：打开详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", true)
	# Then：日志显示规则过程细节。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("Strike 进入弃牌堆"))
	# When：关闭详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", false)
	# Then：日志回到简洁结果。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))


func test_reset_button_restarts_fixed_debug_battle() -> void:
	# Given：策划已经打出卡牌并修改了战斗数值。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/StrikeButton")
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "10")
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值"))
	# When：点击重开战斗按钮。
	_press_button(scene, "Layout/Buttons/ResetButton")
	# Then：固定测试战斗、输入框和日志都回到新战斗开始状态。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "70")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "3")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "0")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值"))


func _instantiate_debug_scene():
	if not ResourceLoader.exists(DEBUG_SCENE_PATH):
		return null
	var packed_scene = load(DEBUG_SCENE_PATH)
	if packed_scene == null:
		return null
	var scene = packed_scene.instantiate()
	add_child_autofree(scene)
	return scene


func _label_text(scene: Node, node_path: String) -> String:
	var label = scene.get_node_or_null(node_path)
	if label == null:
		return ""
	return str(label.text)


func _line_edit_text(scene: Node, node_path: String) -> String:
	var input = scene.get_node_or_null(node_path)
	if input == null:
		return ""
	return str(input.text)


func _set_line_edit_text(scene: Node, node_path: String, value: String) -> void:
	var input = scene.get_node_or_null(node_path)
	assert_not_null(input)
	if input == null:
		return
	input.text = value


func _check_box_pressed(scene: Node, node_path: String) -> bool:
	var check_box = scene.get_node_or_null(node_path)
	if check_box == null:
		return false
	return check_box.button_pressed


func _set_check_box_pressed(scene: Node, node_path: String, pressed: bool) -> void:
	var check_box = scene.get_node_or_null(node_path)
	assert_not_null(check_box)
	if check_box == null:
		return
	check_box.button_pressed = pressed
	check_box.emit_signal("toggled", pressed)


func _press_button(scene: Node, node_path: String) -> void:
	var button = scene.get_node_or_null(node_path)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


func _button_disabled(scene: Node, node_path: String) -> bool:
	var button = scene.get_node_or_null(node_path)
	if button == null:
		return true
	return button.disabled
