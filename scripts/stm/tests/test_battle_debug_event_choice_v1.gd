extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"


func test_battle_debug_scene_shows_event_choice_panel() -> void:
	# Given：调试场景注入最小 event 测试地图。
	var scene = _scene_at_event_room(40)
	# When：点击进入事件房。
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：显示 event_choice，不立即完成房间或显示下一节点。
	assert_true(scene.game_state.has_choice_request())
	assert_eq(scene.game_state.current_choice_request.request_type, "event_choice")
	assert_false(scene.game_flow.get_current_room().is_completed)
	assert_true(_debug_node_or_null(scene, "Layout/ChoicePanel").visible)
	assert_eq(_label_text(scene, "Layout/ChoicePanel/ChoiceTitleLabel"), "清泉")
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("饮用泉水")))
	assert_true(_choice_button_texts(scene).any(func(text): return text.contains("离开")))
	assert_false(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)


func test_battle_debug_scene_submits_event_choice_through_game_state() -> void:
	# Given：调试场景进入事件选择，玩家受伤。
	var scene = _scene_at_event_room(40)
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# When：点击“饮用泉水”。
	_press_choice_button(scene, "饮用泉水")
	# Then：ChoiceResolver 结算 HP，选择面板隐藏，房间完成，下一节点出现。
	assert_eq(scene.game_state.player.hp, 45)
	assert_false(scene.game_state.has_choice_request())
	assert_false(_debug_node_or_null(scene, "Layout/ChoicePanel").visible)
	assert_true(scene.game_flow.get_current_room().is_completed)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel").visible)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("恢复"))


func _scene_at_event_room(player_hp: int):
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return null
	scene.game_state.player.hp = player_hp
	assert_true(scene.game_flow.debug_set_map_floors_for_test(_event_test_floors()))
	scene._refresh_display()
	return scene


func _event_test_floors() -> Array:
	return [
		{
			"name": "测试第 1 层",
			"nodes": [
				{"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [{"floor_index": 1, "node_index": 0}]}
			]
		},
		{
			"name": "测试第 2 层",
			"nodes": [
				{"type": "rest", "room_payload": {}, "next_nodes": []}
			]
		}
	]


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


func _press_choice_button(scene: Node, label_prefix: String) -> void:
	var button = _choice_button(scene, label_prefix)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


func _choice_button(scene: Node, label_prefix: String):
	var container = _debug_node_or_null(scene, "Layout/ChoicePanel/ChoiceOptionsContainer")
	if container == null:
		return null
	for child in container.get_children():
		if child is Button and str(child.text).begins_with(label_prefix):
			return child
	return null


func _choice_button_texts(scene: Node) -> Array:
	var result: Array = []
	var container = _debug_node_or_null(scene, "Layout/ChoicePanel/ChoiceOptionsContainer")
	if container == null:
		return result
	for child in container.get_children():
		if child is Button:
			result.append(str(child.text))
	return result


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
