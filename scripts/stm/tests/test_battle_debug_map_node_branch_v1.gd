extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"


func test_fourth_floor_completion_shows_two_fifth_floor_node_buttons() -> void:
	# Given：调试场景位于第 4 层休息房，并完成 rest_choice。
	var scene = _scene_after_completed_fourth_floor_rest()
	# When：读取下一节点按钮。
	var texts := _next_node_button_texts(scene)
	# Then：第 4 层后显示两个第 5 层节点，而不是第 5 / 第 6 层。
	assert_eq(texts.size(), 2)
	assert_eq(_count_texts_containing(texts, "第 5 层"), 2)
	assert_eq(_count_texts_containing(texts, "第 6 层"), 0)
	assert_true(_any_text_contains_all(texts, ["第 5 层", "战斗房间"]))
	assert_true(_any_text_contains_all(texts, ["第 5 层", "休息房间"]))


func test_clicking_fifth_floor_combat_node_enters_combat_branch() -> void:
	# Given：第 4 层休息完成后出现第 5 层两个节点。
	var scene = _scene_after_completed_fourth_floor_rest()
	# When：点击第 5 层战斗房间节点。
	_press_next_node_button(scene, ["第 5 层", "战斗房间"])
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：进入第 5 层 node 0 combat。
	assert_eq(scene.game_flow.get_current_floor_index(), 4)
	assert_eq(scene.game_flow.get_current_node_index(), 0)
	assert_eq(scene.game_flow.get_current_room().get_room_type(), "combat")
	assert_not_null(scene.combat)


func test_clicking_fifth_floor_rest_node_enters_rest_branch_choice() -> void:
	# Given：第 4 层休息完成后出现第 5 层两个节点。
	var scene = _scene_after_completed_fourth_floor_rest()
	# When：点击第 5 层休息房间节点。
	_press_next_node_button(scene, ["第 5 层", "休息房间"])
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：进入第 5 层 node 1 rest，并显示 rest_choice。
	assert_eq(scene.game_flow.get_current_floor_index(), 4)
	assert_eq(scene.game_flow.get_current_node_index(), 1)
	assert_eq(scene.game_flow.get_current_room().get_room_type(), "rest")
	assert_true(scene.game_state.has_choice_request())
	assert_eq(scene.game_state.current_choice_request.request_type, "rest_choice")
	assert_true(_debug_node_or_null(scene, "Layout/ChoicePanel").visible)


func _scene_after_completed_fourth_floor_rest():
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return null
	assert_true(scene.game_flow.debug_navigate_to_node_for_test(3, 0))
	scene._refresh_display()
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_press_choice_button(scene, "跳过")
	assert_true(scene.game_flow.get_current_room().is_completed)
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


func _press_next_node_button(scene: Node, required_parts: Array) -> void:
	var button = _next_node_button(scene, required_parts)
	assert_not_null(button)
	if button == null:
		return
	button.emit_signal("pressed")


func _next_node_button(scene: Node, required_parts: Array):
	var container = _debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer")
	if container == null:
		return null
	for child in container.get_children():
		if child is Button and _text_contains_all(str(child.text), required_parts):
			return child
	return null


func _next_node_button_texts(scene: Node) -> Array:
	var result: Array = []
	var container = _debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer")
	if container == null:
		return result
	for child in container.get_children():
		if child is Button and child.visible:
			result.append(str(child.text))
	return result


func _count_texts_containing(texts: Array, part: String) -> int:
	var count := 0
	for text in texts:
		if str(text).contains(part):
			count += 1
	return count


func _any_text_contains_all(texts: Array, required_parts: Array) -> bool:
	for text in texts:
		if _text_contains_all(str(text), required_parts):
			return true
	return false


func _text_contains_all(text: String, required_parts: Array) -> bool:
	for part in required_parts:
		if not text.contains(str(part)):
			return false
	return true


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
