extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")


func test_choice_panel_is_hidden_without_choice_request() -> void:
	# Given：调试场景处于地图状态，没有等待处理的选择请求。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：读取 ChoicePanel。
	var panel = _debug_node_or_null(scene, "Layout/ChoicePanel")
	# Then：ChoicePanel 存在但隐藏。
	assert_not_null(panel)
	if panel == null:
		return
	assert_false(panel.visible)


func test_combat_victory_shows_card_reward_choice_panel() -> void:
	# Given：调试战斗中敌人只剩 6 点 HP，手牌有打击。
	var scene = _scene_one_strike_from_victory()
	# When：打出打击获得战斗胜利。
	_press_hand_card_button(scene, "打击")
	# Then：胜利后先显示奖励选择，而不是直接显示下一层。
	var panel = _debug_node_or_null(scene, "Layout/ChoicePanel")
	assert_not_null(panel)
	assert_true(panel.visible)
	assert_true(_label_text(scene, "Layout/ChoicePanel/ChoiceTitleLabel").contains("选择一张奖励卡牌"))
	assert_eq(_choice_button_count(scene), 4)
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("打击")))
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("防御")))
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("痛击")))
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("跳过奖励")))
	assert_false(scene.game_flow.get_current_room().is_completed)
	assert_false(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)


func test_combat_reward_stage_disables_battle_actions() -> void:
	# Given：战斗胜利后进入奖励选择阶段。
	var scene = _scene_one_strike_from_victory()
	_press_hand_card_button(scene, "打击")
	# Then：奖励阶段不能继续出牌、自动出牌、结束回合或改战斗数值。
	assert_true(_button(scene, "Layout/Buttons/AutoPlayButton").disabled)
	assert_true(_button(scene, "Layout/Buttons/EndTurnButton").disabled)
	assert_true(_button(scene, "Layout/ValueEditor/ApplyValuesButton").disabled)
	for child in _debug_node_or_null(scene, "Layout/PilesPanel/HandButtons").get_children():
		if child is Button:
			assert_true(child.disabled)


func test_clicking_reward_card_adds_card_to_deck_and_returns_to_map() -> void:
	# Given：奖励阶段显示三张奖励卡。
	var scene = _scene_one_strike_from_victory()
	var deck_before: int = scene.game_state.player.card_manager.get_pile("deck").size()
	_press_hand_card_button(scene, "打击")
	# When：点击奖励卡“打击”。
	_press_choice_button(scene, "打击")
	# Then：获得卡牌，奖励面板隐藏，房间完成，下一层可选。
	assert_eq(scene.game_state.player.card_manager.get_pile("deck").size(), deck_before + 1)
	assert_false(scene.game_state.has_choice_request())
	assert_false(_debug_node_or_null(scene, "Layout/ChoicePanel").visible)
	assert_true(scene.game_flow.get_current_room().is_completed)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("获得 打击"))


func test_clicking_skip_reward_keeps_deck_size_and_returns_to_map() -> void:
	# Given：奖励阶段显示跳过奖励按钮。
	var scene = _scene_one_strike_from_victory()
	var deck_before: int = scene.game_state.player.card_manager.get_pile("deck").size()
	_press_hand_card_button(scene, "打击")
	# When：点击跳过奖励。
	_press_choice_button(scene, "跳过奖励")
	# Then：deck 不变，奖励面板隐藏，房间完成，下一层可选。
	assert_eq(scene.game_state.player.card_manager.get_pile("deck").size(), deck_before)
	assert_false(scene.game_state.has_choice_request())
	assert_false(_debug_node_or_null(scene, "Layout/ChoicePanel").visible)
	assert_true(scene.game_flow.get_current_room().is_completed)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("跳过奖励"))


func _scene_one_strike_from_victory():
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return null
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	scene.enemy.hp = 6
	_replace_hand(scene, [StrikeScript.new()])
	scene.game_state.player.energy = 3
	scene._refresh_display()
	return scene


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


func _button(scene: Node, node_path: String):
	return _debug_node_or_null(scene, node_path)


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


func _press_choice_button(scene: Node, label_prefix: String) -> void:
	var button = _choice_button(scene, label_prefix)
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


func _choice_button(scene: Node, label_prefix: String):
	var container = _debug_node_or_null(scene, "Layout/ChoicePanel/ChoiceOptionsContainer")
	if container == null:
		return null
	for child in container.get_children():
		if child is Button and str(child.text).begins_with(label_prefix):
			return child
	return null


func _choice_button_count(scene: Node) -> int:
	var container = _debug_node_or_null(scene, "Layout/ChoicePanel/ChoiceOptionsContainer")
	return container.get_child_count() if container != null else 0


func _choice_button_texts(scene: Node) -> Array:
	var result: Array = []
	var container = _debug_node_or_null(scene, "Layout/ChoicePanel/ChoiceOptionsContainer")
	if container == null:
		return result
	for child in container.get_children():
		if child is Button:
			result.append(str(child.text))
	return result


func _replace_hand(scene: Node, cards: Array) -> void:
	scene.game_state.player.card_manager.hand = cards


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
	if node_path.begins_with("Layout/AutoPlayPreviewLabel"):
		return node_path.replace("Layout/AutoPlayPreviewLabel", "Layout/Body/MainPanel/AutoPlayPreviewLabel")
	if node_path.begins_with("Layout/ChoicePanel"):
		return node_path.replace("Layout/ChoicePanel", "Layout/Body/MainPanel/ChoicePanel")
	if node_path.begins_with("Layout/Buttons"):
		return node_path.replace("Layout/Buttons", "Layout/Body/MainPanel/Buttons")
	if node_path.begins_with("Layout/ValueEditor"):
		return node_path.replace("Layout/ValueEditor", "Layout/Body/MainPanel/ValueEditor")
	if node_path.begins_with("Layout/LogPanel"):
		return node_path.replace("Layout/LogPanel", "Layout/Body/LogPanel")
	if node_path.begins_with("Layout/MainPanel"):
		return node_path.replace("Layout/MainPanel", "Layout/Body/MainPanel")
	return node_path
