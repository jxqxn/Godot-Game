extends GutTest

const DEBUG_SCENE_PATH := "res://scenes/stm/battle_debug_scene.tscn"
const TypesScript := preload("res://scripts/stm/utils/types.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")
const StrengthScript := preload("res://scripts/stm/powers/strength.gd")
const VulnerableScript := preload("res://scripts/stm/powers/vulnerable.gd")


func test_debug_scene_starts_with_map_navigation_panel() -> void:
	# Given：策划打开调试场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化。
	# Then：显示地图导航面板，不直接进入战斗。
	assert_not_null(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel"))
	assert_true(_label_text(scene, "Layout/MainPanel/MapPanel/CurrentFloorLabel").contains("第 1 层"))
	assert_true(_label_text(scene, "Layout/MainPanel/MapPanel/RoomChoicesLabel").contains("战斗房间"))
	assert_not_null(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/EnterRoomButton"))
	assert_null(scene.combat)


func test_debug_scene_enter_combat_room_shows_battle_ui() -> void:
	# Given：调试场景处于第 1 层地图面板。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击进入房间。
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：战斗上下文创建，手牌按钮、敌人、日志都可见。
	assert_not_null(scene.combat)
	assert_not_null(scene.enemy)
	assert_eq(scene.enemy.enemy_name, "DummyEnemy")
	assert_true(_hand_card_button_count(scene) > 0)
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))


func test_clicking_hand_attack_card_plays_that_card_and_refreshes_display() -> void:
	# Given：调试战斗中手牌有打击。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	_ensure_card_in_hand(scene, "打击")
	# When：点击打击。
	_press_hand_card_button(scene, "打击")
	# Then：敌人扣血、玩家消耗能量、日志刷新。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))


func test_debug_scene_uses_game_flow_combat_result_for_room_completion() -> void:
	# Given：调试战斗中敌人只剩 6 点 HP，手牌有打击。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	scene.enemy.hp = 6
	_ensure_card_in_hand(scene, "打击")
	# When：打出打击获得 COMBAT_WIN。
	_press_hand_card_button(scene, "打击")
	# Then：当前房间完成，地图面板显示下一层选择。
	assert_true(scene.game_flow.get_current_room().is_completed)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel").visible)
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/NextFloorContainer").visible)
	assert_true(_label_text(scene, "Layout/StatusLabel").contains("房间完成"))


func test_debug_scene_boss_victory_shows_flow_victory() -> void:
	# Given：调试场景的流程进入 Boss 层。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	var flow = scene.game_flow
	flow._map_manager.navigate_to_floor(6)
	flow.enter_current_room()
	# When：通过战斗胜利结果完成 Boss 房间，而不是直接 complete_current_room()。
	flow.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN)
	scene._on_room_completed()
	scene._refresh_display()
	# Then：流程通关并显示通关标签。
	assert_true(flow.is_flow_completed())
	assert_true(_debug_node_or_null(scene, "Layout/MainPanel/MapPanel/VictoryLabel").visible)


func test_debug_scene_rest_room_log_uses_recorded_heal_amount() -> void:
	# Given：玩家受伤后直接来到第 4 层休息房。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	scene.game_state.player.hp = 40
	scene.game_flow._map_manager.navigate_to_floor(3)
	# When：进入休息房。
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：日志使用 RestRoom 记录的真实恢复量，而不是进入后再计算出的 0。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("休息房间：恢复 21 点 HP（40 → 61）"))


func test_debug_scene_failed_next_floor_advance_keeps_current_state() -> void:
	# Given：玩家还在第 1 层，房间没有完成。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：调试代码尝试直接前往 Boss 层。
	scene._on_next_floor_selected(6)
	# Then：UI 报告失败，楼层不变。
	assert_eq(scene.game_flow.get_current_floor_index(), 0)
	assert_true(_label_text(scene, "Layout/StatusLabel").contains("无法前往"))


func test_debug_scene_displays_power_summaries() -> void:
	# Given：调试战斗中玩家和敌人分别有力量与易伤。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	scene.game_state.player.add_power(StrengthScript.new(2))
	scene.enemy.add_power(VulnerableScript.new(3))
	# When：刷新显示。
	scene._refresh_display()
	# Then：状态效果摘要可见。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：易伤 3")


func test_clicking_bash_inflame_and_shrug_it_off_from_hand() -> void:
	# Given：调试战斗分别放入痛击、燃烧、耸肩无视。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# When/Then：痛击造成伤害并施加易伤。
	_replace_hand(scene, [BashScript.new()])
	scene._refresh_display()
	_press_hand_card_button(scene, "痛击")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：易伤 2")
	# When/Then：燃烧给玩家力量。
	_replace_hand(scene, [InflameScript.new()])
	scene.game_state.player.energy = 3
	scene._refresh_display()
	_press_hand_card_button(scene, "燃烧")
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	# When/Then：耸肩无视获得格挡并抽牌。
	_replace_hand(scene, [ShrugItOffScript.new()])
	scene.game_state.player.energy = 3
	scene.game_state.player.card_manager.draw_pile = [StrikeScript.new()]
	scene._refresh_display()
	_press_hand_card_button(scene, "耸肩无视")
	assert_true(_label_text(scene, "Layout/Metrics/BlockLabel").contains("格挡："))
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("打击"))


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
	if node_path.begins_with("Layout/MainPanel"):
		return node_path.replace("Layout/MainPanel", "Layout/Body/MainPanel")
	return node_path
