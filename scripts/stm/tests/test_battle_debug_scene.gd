extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const StrengthScript := preload("res://scripts/stm/powers/strength.gd")
const VulnerableScript := preload("res://scripts/stm/powers/vulnerable.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")


func test_debug_scene_shows_initial_combat_state() -> void:
	# Given：策划打开固定调试战斗场景。
	var scene = _instantiate_debug_scene()
	# When：场景初始化完成。
	assert_not_null(scene)
	if scene == null:
		return
	# Then：界面显示玩家血量、能量、格挡、手牌和敌人血量，并为当前手牌生成可点击按钮。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（"))
	assert_not_null(_debug_node_or_null(scene, "Layout/PilesPanel/HandButtons"))
	assert_eq(_hand_card_button_count(scene), 5)
	assert_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/StrikeButton"))
	assert_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/DefendButton"))
	assert_not_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/EndTurnButton"))


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
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/EnemyPanel/EnemyIntentLabel"), "敌人意图：攻击")
	assert_eq(_label_text(scene, "Layout/Body/MainPanel/EnemyPanel/EnemyAttackLabel"), "预计攻击：6")
	assert_true(_label_text(scene, "Layout/Body/MainPanel/PilesPanel/HandLabel").contains("手牌（"))
	assert_true(_label_text(scene, "Layout/Body/MainPanel/PilesPanel/DrawPileLabel").contains("抽牌堆（"))
	assert_true(_label_text(scene, "Layout/Body/MainPanel/PilesPanel/DiscardPileLabel").contains("弃牌堆（"))
	assert_eq(_line_edit_text(scene, "Layout/Body/MainPanel/ValueEditor/PlayerHpInput"), "70")
	assert_eq(_line_edit_text(scene, "Layout/Body/MainPanel/ValueEditor/EnergyInput"), "3")
	assert_eq(_line_edit_text(scene, "Layout/Body/MainPanel/ValueEditor/BlockInput"), "0")
	assert_eq(_line_edit_text(scene, "Layout/Body/MainPanel/ValueEditor/EnemyHpInput"), "20")
	var value_editor = scene.get_node_or_null("Layout/Body/MainPanel/ValueEditor")
	assert_not_null(value_editor)
	assert_true(value_editor is GridContainer)
	if value_editor is GridContainer:
		assert_eq(value_editor.columns, 2)
	assert_not_null(scene.get_node_or_null("Layout/Body/MainPanel/ValueEditor/ApplyValuesSpacer"))
	assert_not_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/ResetButton"))
	assert_not_null(scene.get_node_or_null("Layout/Body/LogPanel/DetailedLogCheckBox"))
	assert_false(_check_box_pressed(scene, "Layout/Body/LogPanel/DetailedLogCheckBox"))
	assert_true(_label_text(scene, "Layout/Body/LogPanel/LogLabel").contains("战斗开始"))


func test_debug_scene_places_log_in_right_side_column() -> void:
	# Given：策划需要在同一屏同时查看战斗状态和多行战斗日志。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：调试场景完成初始化。
	var body = scene.get_node_or_null("Layout/Body")
	var main_panel = scene.get_node_or_null("Layout/Body/MainPanel")
	var log_panel = scene.get_node_or_null("Layout/Body/LogPanel")
	var log_view = scene.get_node_or_null("Layout/Body/LogPanel/LogLabel")
	# Then：主体区域使用左右分栏，日志栏位于右侧并获得稳定宽度和高度。
	assert_not_null(body)
	assert_true(body is HBoxContainer)
	assert_not_null(main_panel)
	assert_true(main_panel is VBoxContainer)
	assert_not_null(log_panel)
	assert_true(log_panel is VBoxContainer)
	if body != null and log_panel != null:
		assert_eq(body.get_child(body.get_child_count() - 1), log_panel)
	if log_panel is Control:
		assert_true(log_panel.custom_minimum_size.x >= 320.0)
		assert_eq(log_panel.size_flags_vertical, Control.SIZE_EXPAND_FILL)
	assert_not_null(log_view)
	assert_true(log_view is TextEdit)
	if log_view is TextEdit:
		assert_true(log_view.custom_minimum_size.y >= 360.0)
		assert_eq(log_view.size_flags_vertical, Control.SIZE_EXPAND_FILL)


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
	# When：传入一个 game_state/player 与 combat/enemy 不一致的 fixture context。
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
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyIntentLabel"), "敌人意图：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyAttackLabel"), "预计攻击：无")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/HandLabel"), "手牌（0）：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/DrawPileLabel"), "抽牌堆（0）：无")
	assert_eq(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel"), "弃牌堆（0）：无")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "")
	assert_eq(_hand_card_button_count(scene), 0)
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
	# Given：策划在调试工具中输入一组合规的玩家和敌人数值。
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


func test_clicking_hand_attack_card_plays_that_card_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有打击，敌人是 DummyEnemy。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "打击")
	# When：点击手牌中的打击。
	_press_hand_card_button(scene, "打击")
	# Then：敌人受到 6 点伤害，玩家消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("打击"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))


func test_clicking_hand_skill_card_plays_that_card_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有防御。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "防御")
	# When：点击手牌中的防御。
	_press_hand_card_button(scene, "防御")
	# Then：玩家获得 5 点格挡，消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：5")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("防御"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 防御，获得 5 点格挡"))


func test_clicking_bash_applies_vulnerable_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有痛击且敌人没有易伤。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [BashScript.new()])
	scene._refresh_display()
	# When：点击手牌中的痛击。
	_press_hand_card_button(scene, "痛击")
	# Then：敌人受到 8 点伤害，并获得 2 层易伤。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：12/20")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：易伤 2")


func test_clicking_inflame_applies_strength_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有燃烧且没有力量。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [InflameScript.new()])
	scene._refresh_display()
	# When：点击手牌中的燃烧。
	_press_hand_card_button(scene, "燃烧")
	# Then：玩家获得 2 点力量，燃烧进入弃牌堆。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("燃烧"))


func test_clicking_shrug_it_off_gains_block_and_draws_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有耸肩无视，抽牌堆顶有打击。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [ShrugItOffScript.new()])
	scene.game_state.player.card_manager.draw_pile = [StrikeScript.new()]
	scene._refresh_display()
	# When：点击手牌中的耸肩无视。
	_press_hand_card_button(scene, "耸肩无视")
	# Then：玩家获得 8 点格挡，并抽到打击。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：8")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("打击"))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("耸肩无视"))


func test_end_turn_button_starts_next_player_turn_and_reenables_card_buttons() -> void:
	# Given：调试场景中玩家已打出防御并获得 5 点格挡。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "防御")
	_press_hand_card_button(scene, "防御")
	# When：点击结束回合按钮。
	_press_button(scene, "Layout/Buttons/EndTurnButton")
	# Then：DummyEnemy 的攻击被格挡抵消 5 点，玩家只损失 1 点血量，日志刷新，并进入可继续出牌的新玩家回合。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：69/70")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("结束回合：DummyEnemy 攻击造成 1 点伤害"))
	assert_true(_hand_card_button_count(scene) > 0)


func test_detailed_log_toggle_switches_between_simple_and_detailed_entries() -> void:
	# Given：策划已经打出打击，简洁日志只显示关键结果。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "打击")
	_press_hand_card_button(scene, "打击")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	# When：打开详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", true)
	# Then：日志显示规则过程细节。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打击 进入弃牌堆"))
	# When：关闭详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", false)
	# Then：日志回到简洁结果。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))


func test_log_panel_uses_read_only_multiline_debug_view() -> void:
	# Given：策划需要阅读多条战斗日志来调试规则过程。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：调试场景完成初始化。
	var log_view = scene.get_node_or_null("Layout/Body/LogPanel/LogLabel")
	# Then：日志区域是只读的多行调试视图，而不是一行普通标签。
	assert_not_null(log_view)
	assert_true(log_view is TextEdit)
	if log_view is TextEdit:
		assert_false(log_view.editable)
		assert_true(log_view.custom_minimum_size.y >= 160.0)


func test_reset_button_restarts_fixed_debug_battle() -> void:
	# Given：策划已经打出卡牌并修改了战斗数值。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "打击")
	_press_hand_card_button(scene, "打击")
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


func test_debug_scene_displays_player_and_enemy_power_summaries() -> void:
	# Given：调试场景已初始化，玩家和敌人分别拥有力量与易伤效果。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	scene.game_state.player.add_power(StrengthScript.new(2))
	scene.enemy.add_power(VulnerableScript.new(3))
	# When：刷新调试场景显示。
	scene._refresh_display()
	# Then：玩家与敌人的状态效果摘要应正确显示。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：易伤 3")


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
	var label = _debug_node_or_null(scene, node_path)
	if label == null:
		return ""
	return str(label.text)


func _line_edit_text(scene: Node, node_path: String) -> String:
	var input = _debug_node_or_null(scene, node_path)
	if input == null:
		return ""
	return str(input.text)


func _set_line_edit_text(scene: Node, node_path: String, value: String) -> void:
	var input = _debug_node_or_null(scene, node_path)
	assert_not_null(input)
	if input == null:
		return
	input.text = value


func _check_box_pressed(scene: Node, node_path: String) -> bool:
	var check_box = _debug_node_or_null(scene, node_path)
	if check_box == null:
		return false
	return check_box.button_pressed


func _set_check_box_pressed(scene: Node, node_path: String, pressed: bool) -> void:
	var check_box = _debug_node_or_null(scene, node_path)
	assert_not_null(check_box)
	if check_box == null:
		return
	check_box.button_pressed = pressed
	check_box.emit_signal("toggled", pressed)


func _press_button(scene: Node, node_path: String) -> void:
	var button = _debug_node_or_null(scene, node_path)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


func _press_hand_card_button(scene: Node, card_name: String) -> void:
	var button = _hand_card_button(scene, card_name)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


func _hand_card_button(scene: Node, card_name: String):
	var container = _debug_node_or_null(scene, "Layout/PilesPanel/HandButtons")
	if container == null:
		return null
	for child in container.get_children():
		if child is Button and str(child.text).begins_with(card_name):
			return child
	return null


func _hand_card_button_count(scene: Node) -> int:
	var container = _debug_node_or_null(scene, "Layout/PilesPanel/HandButtons")
	if container == null:
		return 0
	return container.get_child_count()


func _replace_hand(scene: Node, cards: Array) -> void:
	scene.game_state.player.card_manager.hand = cards


func _ensure_card_in_hand(scene: Node, card_name: String) -> void:
	var manager = scene.game_state.player.card_manager
	for pile_name in ["hand", "draw_pile", "discard_pile", "deck"]:
		for card in manager.get_pile(pile_name):
			if card != null and card.card_name == card_name:
				if pile_name != "hand":
					manager.remove_from_pile(pile_name, card)
					manager.hand.append(card)
				scene._refresh_display()
				return
	assert_true(false, "未找到测试需要的手牌：" + card_name)


func _button_disabled(scene: Node, node_path: String) -> bool:
	var button = _debug_node_or_null(scene, node_path)
	if button == null:
		return true
	return button.disabled


func _debug_node_or_null(scene: Node, node_path: String):
	var node = scene.get_node_or_null(node_path)
	if node != null:
		return node
	var relocated_path := _relocated_debug_path(node_path)
	if relocated_path == node_path:
		return null
	return scene.get_node_or_null(relocated_path)


func _relocated_debug_path(node_path: String) -> String:
	if node_path.begins_with("Layout/Metrics"):
		return node_path.replace("Layout/Metrics", "Layout/Body/MainPanel/Metrics")
	if node_path.begins_with("Layout/EnemyPanel"):
		return node_path.replace("Layout/EnemyPanel", "Layout/Body/MainPanel/EnemyPanel")
	if node_path.begins_with("Layout/PilesPanel"):
		return node_path.replace("Layout/PilesPanel", "Layout/Body/MainPanel/PilesPanel")
	if node_path.begins_with("Layout/StatusLabel"):
		return node_path.replace("Layout/StatusLabel", "Layout/Body/MainPanel/StatusLabel")
	if node_path.begins_with("Layout/Buttons"):
		return node_path.replace("Layout/Buttons", "Layout/Body/MainPanel/Buttons")
	if node_path.begins_with("Layout/ValueEditor"):
		return node_path.replace("Layout/ValueEditor", "Layout/Body/MainPanel/ValueEditor")
	if node_path.begins_with("Layout/LogPanel"):
		return node_path.replace("Layout/LogPanel", "Layout/Body/LogPanel")
	return node_path
