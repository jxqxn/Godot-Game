extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")


func test_debug_scene_displays_hand_buttons_sorted_by_priority() -> void:
	# Given：调试战斗手牌原始顺序不是优先级顺序。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [InflameScript.new(), DefendScript.new(), BashScript.new(), StrikeScript.new()])
	# When：刷新显示。
	scene._refresh_display()
	# Then：按钮从左到右按 play_priority 升序排列。
	assert_eq(_hand_button_texts(scene), ["防御（1）", "打击（1）", "痛击（2）", "燃烧（1）"])


func test_auto_play_button_plays_highest_priority_playable_card() -> void:
	# Given：燃烧优先级最高且可打。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), InflameScript.new(), DefendScript.new()])
	scene.game_state.player.energy = 3
	scene._refresh_display()
	# When：点击自动出牌。
	_press_button(scene, "Layout/Buttons/AutoPlayButton")
	# Then：自动打出燃烧，玩家获得力量。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 燃烧"))


func test_auto_play_button_skips_unplayable_high_priority_card() -> void:
	# Given：痛击优先级高但费用不足，打击可打。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), BashScript.new()])
	scene.game_state.player.energy = 1
	scene._refresh_display()
	# When：点击自动出牌。
	_press_button(scene, "Layout/Buttons/AutoPlayButton")
	# Then：自动跳过痛击，打出打击。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击"))


func test_auto_play_button_reports_when_no_card_is_playable() -> void:
	# Given：所有手牌都费用不足。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_replace_hand(scene, [StrikeScript.new(), BashScript.new()])
	scene.game_state.player.energy = 0
	scene._refresh_display()
	# When：点击自动出牌。
	_press_button(scene, "Layout/Buttons/AutoPlayButton")
	# Then：显示无可自动打出的牌，且敌人血量不变。
	assert_true(_label_text(scene, "Layout/StatusLabel").contains("没有可自动打出的牌"))
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")


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


func _hand_button_texts(scene: Node) -> Array:
	var container = _debug_node_or_null(scene, "Layout/PilesPanel/HandButtons")
	var texts: Array = []
	if container == null:
		return texts
	for child in container.get_children():
		if child is Button:
			texts.append(str(child.text))
	return texts


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
	if node_path.begins_with("Layout/Buttons"):
		return node_path.replace("Layout/Buttons", "Layout/Body/MainPanel/Buttons")
	if node_path.begins_with("Layout/LogPanel"):
		return node_path.replace("Layout/LogPanel", "Layout/Body/LogPanel")
	if node_path.begins_with("Layout/MainPanel"):
		return node_path.replace("Layout/MainPanel", "Layout/Body/MainPanel")
	return node_path
