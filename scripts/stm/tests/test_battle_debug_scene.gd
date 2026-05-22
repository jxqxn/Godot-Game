extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"


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
	assert_true(_label_text(scene, "Layout/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/HandLabel").contains("Strike"))
	assert_true(_label_text(scene, "Layout/HandLabel").contains("Defend"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/StrikeButton"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/DefendButton"))
	assert_not_null(scene.get_node_or_null("Layout/Buttons/EndTurnButton"))


func test_strike_button_plays_strike_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有 Strike，敌人是 DummyEnemy。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击 Strike 按钮。
	_press_button(scene, "Layout/Buttons/StrikeButton")
	# Then：敌人受到 6 点伤害，玩家消耗 1 点能量，界面刷新到最新状态。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/HandLabel").contains("手牌（3）："))


func test_defend_button_plays_defend_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有 Defend。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击 Defend 按钮。
	_press_button(scene, "Layout/Buttons/DefendButton")
	# Then：玩家获得 5 点格挡，消耗 1 点能量，界面刷新到最新状态。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：5")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/HandLabel").contains("手牌（3）："))


func test_end_turn_button_starts_next_player_turn_and_reenables_card_buttons() -> void:
	# Given：调试场景中玩家已打出 Defend 并获得 5 点格挡。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/DefendButton")
	# When：点击结束回合按钮。
	_press_button(scene, "Layout/Buttons/EndTurnButton")
	# Then：DummyEnemy 的攻击被格挡抵消 5 点，玩家只损失 1 点血量，并进入可继续出牌的新玩家回合。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：69/70")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_true(_label_text(scene, "Layout/HandLabel").contains("手牌（"))
	assert_false(_button_disabled(scene, "Layout/Buttons/StrikeButton"))
	assert_false(_button_disabled(scene, "Layout/Buttons/DefendButton"))


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
