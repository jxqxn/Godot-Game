extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")


func test_preview_label_exists_and_reports_no_combat_before_entering_room() -> void:
	# Given：调试场景停留在地图选择状态。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：读取自动出牌预览 Label。
	var label = _debug_node_or_null(scene, "Layout/AutoPlayPreviewLabel")
	# Then：Label 存在，并提示战斗尚未开始。
	assert_not_null(label)
	if label == null:
		return
	assert_true(str(label.text).contains("自动出牌预览"))
	assert_true(str(label.text).contains("战斗尚未开始"))


func test_preview_label_reports_selected_card_after_entering_combat() -> void:
	# Given：进入战斗后，打击比防御优先级更高且可打。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [DefendScript.new(), StrikeScript.new()])
	scene.game_state.player.energy = 3
	# When：刷新显示。
	scene._refresh_display()
	# Then：预览显示将自动打出打击。
	var text := _label_text(scene, "Layout/AutoPlayPreviewLabel")
	assert_true(text.contains("自动出牌预览"))
	assert_true(text.contains("将打出 打击"))


func test_preview_label_reports_skipped_expensive_card_reason() -> void:
	# Given：痛击优先级更高但能量不足，打击可打。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), BashScript.new()])
	scene.game_state.player.energy = 1
	# When：刷新显示。
	scene._refresh_display()
	# Then：预览显示将打出打击，并说明跳过痛击是因为能量不足。
	var text := _label_text(scene, "Layout/AutoPlayPreviewLabel")
	assert_true(text.contains("将打出 打击"))
	assert_true(text.contains("跳过：痛击"))
	assert_true(text.contains("能量不足"))


func test_preview_label_reports_no_playable_card_reason() -> void:
	# Given：所有手牌都费用不足。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), BashScript.new()])
	scene.game_state.player.energy = 0
	# When：刷新显示。
	scene._refresh_display()
	# Then：预览显示没有可自动打出的牌，并给出能量不足原因。
	var text := _label_text(scene, "Layout/AutoPlayPreviewLabel")
	assert_true(text.contains("没有可自动打出的牌"))
	assert_true(text.contains("能量不足"))


func test_auto_play_button_executes_the_card_shown_by_preview() -> void:
	# Given：预览显示痛击费用不足，自动出牌将打出打击。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), BashScript.new()])
	scene.game_state.player.energy = 1
	scene._refresh_display()
	assert_true(_label_text(scene, "Layout/AutoPlayPreviewLabel").contains("将打出 打击"))
	# When：点击自动出牌。
	_press_button(scene, "Layout/Buttons/AutoPlayButton")
	# Then：实际打出打击，敌人血量按打击伤害下降。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击"))


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


func _press_button(scene: Node, node_path: String) -> void:
	var button = _debug_node_or_null(scene, node_path)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


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
	if node_path.begins_with("Layout/Buttons"):
		return node_path.replace("Layout/Buttons", "Layout/Body/MainPanel/Buttons")
	if node_path.begins_with("Layout/LogPanel"):
		return node_path.replace("Layout/LogPanel", "Layout/Body/LogPanel")
	if node_path.begins_with("Layout/MainPanel"):
		return node_path.replace("Layout/MainPanel", "Layout/Body/MainPanel")
	return node_path
