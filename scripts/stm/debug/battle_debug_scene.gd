class_name StmBattleDebugScene
extends Control

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const StmMapDataScript := preload("res://scripts/stm/map/map_data.gd")

var game_state
var combat
var enemy
var game_flow = null
var map_panel: VBoxContainer
var current_floor_label: Label
var room_choices_label: Label
var enter_room_button: Button
var next_floor_container: VBoxContainer
var victory_label: Label
var current_fixture_name: String = ""
var status_message: String = "等待行动"

var player_hp_label: Label
var energy_label: Label
var block_label: Label
var player_powers_label: Label
var enemy_hp_label: Label
var enemy_intent_label: Label
var enemy_attack_label: Label
var enemy_powers_label: Label
var hand_label: Label
var draw_pile_label: Label
var discard_pile_label: Label
var hand_buttons_container: GridContainer
var status_label: Label
var end_turn_button: Button
var player_hp_input: LineEdit
var energy_input: LineEdit
var block_input: LineEdit
var enemy_hp_input: LineEdit
var apply_values_button: Button
var reset_button: Button
var detailed_log_check_box: CheckBox
var log_label: TextEdit
var simple_log_entries: Array[String] = []
var detail_log_entries: Array[String] = []


func _ready() -> void:
	_build_ui()
	start_debug_combat()


func start_debug_combat() -> void:
	game_state = null
	combat = null
	enemy = null
	current_fixture_name = ""
	var bootstrap_script = load("res://scripts/stm/engine/game_bootstrap.gd")
	if bootstrap_script == null:
		_handle_fixture_failure()
		return
	var player_script = load("res://scripts/stm/player/player.gd")
	if player_script == null:
		_handle_fixture_failure()
		return
	var deck: Array = FixedBattleFixtureScript.new().create_deck()
	var player = player_script.new(deck)
	var bootstrap = bootstrap_script.new()
	game_state = bootstrap.create_game(player)
	if game_state == null:
		_handle_fixture_failure()
		return
	game_flow = GameFlowScript.new(game_state)
	status_message = "等待选择楼层"
	_reset_log()
	_append_log("地图加载完成", "地图加载完成：7 层固定测试地图已就绪，第 1 层为战斗房间。")
	_refresh_display()


func _apply_fixture_context(context: Dictionary) -> bool:
	if context.is_empty():
		return false
	if context.get("game_state") == null:
		return false
	if context.get("combat") == null:
		return false
	if context.get("player") == null:
		return false
	if context.get("enemy") == null:
		return false
	if context["game_state"].player == null:
		return false
	if context["game_state"].player != context["player"]:
		return false
	if not context["combat"].enemies.has(context["enemy"]):
		return false
	game_state = context["game_state"]
	combat = context["combat"]
	enemy = context["enemy"]
	current_fixture_name = str(context.get("name", ""))
	return true


func _handle_fixture_failure() -> void:
	game_state = null
	combat = null
	enemy = null
	current_fixture_name = ""
	_show_no_combat_display()
	status_message = "测试战斗创建失败"
	_reset_log()
	_append_log(status_message)
	if status_label != null:
		status_label.text = status_message
	if log_label != null:
		_refresh_log()
	if end_turn_button != null:
		end_turn_button.disabled = true
	if apply_values_button != null:
		apply_values_button.disabled = true


func _show_no_combat_display() -> void:
	if player_hp_label != null:
		player_hp_label.text = "玩家血量：无"
	if energy_label != null:
		energy_label.text = "能量：无"
	if block_label != null:
		block_label.text = "格挡：无"
	if player_powers_label != null:
		player_powers_label.text = "玩家状态效果：无"
	if enemy_hp_label != null:
		enemy_hp_label.text = "敌人血量：无"
	if enemy_intent_label != null:
		enemy_intent_label.text = "敌人意图：无"
	if enemy_attack_label != null:
		enemy_attack_label.text = "预计攻击：无"
	if enemy_powers_label != null:
		enemy_powers_label.text = "敌人状态效果：无"
	if hand_label != null:
		hand_label.text = "手牌（0）：无"
	if draw_pile_label != null:
		draw_pile_label.text = "抽牌堆（0）：无"
	if discard_pile_label != null:
		discard_pile_label.text = "弃牌堆（0）：无"
	if hand_buttons_container != null:
		for child in hand_buttons_container.get_children():
			hand_buttons_container.remove_child(child)
			child.queue_free()
	if player_hp_input != null:
		player_hp_input.text = ""
	if energy_input != null:
		energy_input.text = ""
	if block_input != null:
		block_input.text = ""
	if enemy_hp_input != null:
		enemy_hp_input.text = ""
	if current_floor_label != null:
		current_floor_label.text = "当前楼层：无"
	if room_choices_label != null:
		room_choices_label.text = "可选房间：无"
	if enter_room_button != null:
		enter_room_button.disabled = true
	if next_floor_container != null:
		for child in next_floor_container.get_children():
			next_floor_container.remove_child(child)
			child.free()
		next_floor_container.visible = false
	if victory_label != null:
		victory_label.visible = false


func _build_ui() -> void:
	if get_node_or_null("Layout") != null:
		return

	var layout = VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 24.0
	layout.offset_top = 24.0
	layout.offset_right = -24.0
	layout.offset_bottom = -24.0
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "战斗调试工具"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	var body = HBoxContainer.new()
	body.name = "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	layout.add_child(body)

	var main_panel = VBoxContainer.new()
	main_panel.name = "MainPanel"
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_theme_constant_override("separation", 12)
	body.add_child(main_panel)

	map_panel = VBoxContainer.new()
	map_panel.name = "MapPanel"
	map_panel.add_theme_constant_override("separation", 8)
	main_panel.add_child(map_panel)

	current_floor_label = _new_label("CurrentFloorLabel")
	map_panel.add_child(current_floor_label)

	room_choices_label = _new_label("RoomChoicesLabel")
	room_choices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_panel.add_child(room_choices_label)

	enter_room_button = _new_button("EnterRoomButton", "进入房间")
	enter_room_button.pressed.connect(_on_enter_room_pressed)
	map_panel.add_child(enter_room_button)

	next_floor_container = VBoxContainer.new()
	next_floor_container.name = "NextFloorContainer"
	next_floor_container.visible = false
	next_floor_container.add_theme_constant_override("separation", 6)
	map_panel.add_child(next_floor_container)

	victory_label = _new_label("VictoryLabel")
	victory_label.visible = false
	victory_label.text = "游戏通关！"
	victory_label.add_theme_font_size_override("font_size", 20)
	map_panel.add_child(victory_label)

	var metrics = HBoxContainer.new()
	metrics.name = "Metrics"
	metrics.add_theme_constant_override("separation", 16)
	main_panel.add_child(metrics)

	player_hp_label = _new_label("PlayerHpLabel")
	metrics.add_child(player_hp_label)
	energy_label = _new_label("EnergyLabel")
	metrics.add_child(energy_label)
	block_label = _new_label("BlockLabel")
	metrics.add_child(block_label)
	player_powers_label = _new_label("PlayerPowersLabel")
	metrics.add_child(player_powers_label)

	var enemy_panel = VBoxContainer.new()
	enemy_panel.name = "EnemyPanel"
	enemy_panel.add_theme_constant_override("separation", 8)
	main_panel.add_child(enemy_panel)

	enemy_hp_label = _new_label("EnemyHpLabel")
	enemy_panel.add_child(enemy_hp_label)
	enemy_intent_label = _new_label("EnemyIntentLabel")
	enemy_panel.add_child(enemy_intent_label)
	enemy_attack_label = _new_label("EnemyAttackLabel")
	enemy_panel.add_child(enemy_attack_label)
	enemy_powers_label = _new_label("EnemyPowersLabel")
	enemy_panel.add_child(enemy_powers_label)

	var piles_panel = VBoxContainer.new()
	piles_panel.name = "PilesPanel"
	piles_panel.add_theme_constant_override("separation", 6)
	main_panel.add_child(piles_panel)

	hand_label = _new_label("HandLabel")
	hand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(hand_label)

	hand_buttons_container = GridContainer.new()
	hand_buttons_container.name = "HandButtons"
	hand_buttons_container.columns = 4
	hand_buttons_container.add_theme_constant_override("h_separation", 8)
	hand_buttons_container.add_theme_constant_override("v_separation", 8)
	piles_panel.add_child(hand_buttons_container)

	draw_pile_label = _new_label("DrawPileLabel")
	draw_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(draw_pile_label)
	discard_pile_label = _new_label("DiscardPileLabel")
	discard_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(discard_pile_label)

	status_label = _new_label("StatusLabel")
	main_panel.add_child(status_label)

	var buttons = HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 8)
	main_panel.add_child(buttons)

	end_turn_button = _new_button("EndTurnButton", "结束回合")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	buttons.add_child(end_turn_button)

	reset_button = _new_button("ResetButton", "重开战斗")
	reset_button.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset_button)

	var value_editor = GridContainer.new()
	value_editor.name = "ValueEditor"
	value_editor.columns = 2
	value_editor.add_theme_constant_override("separation", 8)
	main_panel.add_child(value_editor)

	value_editor.add_child(_new_label_with_text("PlayerHpInputLabel", "玩家血量"))
	player_hp_input = _new_line_edit("PlayerHpInput")
	value_editor.add_child(player_hp_input)
	value_editor.add_child(_new_label_with_text("EnergyInputLabel", "玩家能量"))
	energy_input = _new_line_edit("EnergyInput")
	value_editor.add_child(energy_input)
	value_editor.add_child(_new_label_with_text("BlockInputLabel", "玩家格挡"))
	block_input = _new_line_edit("BlockInput")
	value_editor.add_child(block_input)
	value_editor.add_child(_new_label_with_text("EnemyHpInputLabel", "敌人血量"))
	enemy_hp_input = _new_line_edit("EnemyHpInput")
	value_editor.add_child(enemy_hp_input)
	apply_values_button = _new_button("ApplyValuesButton", "应用数值")
	apply_values_button.pressed.connect(_on_apply_values_pressed)
	value_editor.add_child(apply_values_button)
	var apply_values_spacer = Control.new()
	apply_values_spacer.name = "ApplyValuesSpacer"
	apply_values_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_editor.add_child(apply_values_spacer)

	var log_panel = VBoxContainer.new()
	log_panel.name = "LogPanel"
	log_panel.custom_minimum_size = Vector2(360.0, 0.0)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_constant_override("separation", 6)
	body.add_child(log_panel)

	detailed_log_check_box = CheckBox.new()
	detailed_log_check_box.name = "DetailedLogCheckBox"
	detailed_log_check_box.text = "显示详细日志"
	detailed_log_check_box.toggled.connect(_on_detailed_log_toggled)
	log_panel.add_child(detailed_log_check_box)

	log_label = TextEdit.new()
	log_label.name = "LogLabel"
	log_label.editable = false
	log_label.custom_minimum_size = Vector2(0.0, 360.0)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_label)


func _new_label(label_name: String) -> Label:
	var label = Label.new()
	label.name = label_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _new_label_with_text(label_name: String, label_text: String) -> Label:
	var label = _new_label(label_name)
	label.text = label_text
	return label


func _new_line_edit(input_name: String) -> LineEdit:
	var input = LineEdit.new()
	input.name = input_name
	input.custom_minimum_size = Vector2(120.0, 36.0)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return input


func _new_button(button_name: String, button_text: String) -> Button:
	var button = Button.new()
	button.name = button_name
	button.text = button_text
	button.custom_minimum_size = Vector2(120.0, 40.0)
	return button


func _on_end_turn_pressed() -> void:
	if game_state == null or combat == null:
		status_message = "战斗尚未开始"
		_append_log("结束回合失败", "结束回合失败：战斗尚未开始。")
		_refresh_display()
		return
	var before_player := _player_snapshot()
	var result = combat.end_turn(game_state)
	var after_player := _player_snapshot()
	var before_hp: int = int(before_player["hp"])
	var before_block: int = int(before_player["block"])
	var before_energy: int = int(before_player["energy"])
	var after_hp: int = int(after_player["hp"])
	var after_block: int = int(after_player["block"])
	var after_energy: int = int(after_player["energy"])
	var hp_loss: int = max(before_hp - after_hp, 0)
	status_message = _result_message(result, "敌人回合结算完成")
	_append_log(
		"结束回合：DummyEnemy 攻击造成 %d 点伤害" % hp_loss,
		"结束回合：玩家 HP %d -> %d；格挡 %d -> %d；能量 %d -> %d；敌人意图执行；进入下一玩家回合；结局检查=%d。"
			% [before_hp, after_hp, before_block, after_block, before_energy, after_energy, result]
	)
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		if game_flow != null and game_flow.get_current_room() != null:
			game_flow.complete_current_room()
			_on_room_completed()
			return
	_refresh_display()


func _play_card_from_hand(card) -> void:
	if game_state == null or combat == null or game_state.player == null:
		status_message = "战斗尚未开始"
		_append_log("出牌失败", "出牌失败：战斗尚未开始。")
		_refresh_display()
		return
	if game_state.player.card_manager == null or not game_state.player.card_manager.get_pile("hand").has(card):
		var missing_name := _card_display_name(card)
		status_message = "手牌中没有%s" % missing_name
		_append_log(status_message)
		_refresh_display()
		return
	if card != null and card.has_method("can_play") and not card.can_play(game_state):
		var blocked_name := _card_display_name(card)
		status_message = "无法打出%s" % blocked_name
		_append_log(status_message)
		_refresh_display()
		return
	var targets: Array = []
	if card != null and str(card.get("target_type")) == "enemy_select":
		var target = _first_alive_enemy()
		if target == null:
			status_message = "没有可选敌人"
			_append_log(status_message)
			_refresh_display()
			return
		targets.append(target)
	var before_player := _player_snapshot()
	var before_enemy_hp := _enemy_hp_value()
	var result = combat.play_card(game_state, card, targets)
	var card_name := _card_display_name(card)
	status_message = _result_message(result, "已打出%s" % card_name)
	_append_card_log(card, before_player, before_enemy_hp, result)
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		if game_flow != null and game_flow.get_current_room() != null:
			game_flow.complete_current_room()
			_on_room_completed()
			return
	_refresh_display()


func _refresh_display() -> void:
	if game_state == null or game_state.player == null:
		return

	# GameFlow 驱动的地图/通关状态检查
	if game_flow != null and game_flow.is_flow_completed():
		if map_panel != null:
			map_panel.visible = true
		if victory_label != null:
			victory_label.visible = true
		_show_map_panel_state()
		status_label.text = "游戏通关"
		return

	if game_flow != null and game_state.current_combat == null:
		if map_panel != null:
			map_panel.visible = true
		_show_map_panel_state()
		status_label.text = status_message
		return

	var player = game_state.player
	player_hp_label.text = "玩家血量：%d/%d" % [player.hp, player.max_hp]
	energy_label.text = "能量：%d/%d" % [player.energy, player.max_energy]
	block_label.text = "格挡：%d" % player.block
	player_powers_label.text = _power_text("玩家状态效果", player)
	enemy_hp_label.text = _enemy_hp_text()
	enemy_intent_label.text = _enemy_intent_text()
	enemy_attack_label.text = _enemy_attack_text()
	enemy_powers_label.text = _power_text("敌人状态效果", enemy)
	hand_label.text = _pile_text("手牌", "hand")
	draw_pile_label.text = _pile_text("抽牌堆", "draw_pile")
	discard_pile_label.text = _pile_text("弃牌堆", "discard_pile")
	_refresh_hand_buttons(player)
	status_label.text = status_message
	_sync_value_inputs()
	_refresh_log()

	end_turn_button.disabled = combat == null
	apply_values_button.disabled = game_state == null or game_state.player == null or enemy == null


func _refresh_hand_buttons(player) -> void:
	if hand_buttons_container == null:
		return
	for child in hand_buttons_container.get_children():
		hand_buttons_container.remove_child(child)
		child.queue_free()
	if player == null or player.card_manager == null:
		return
	var hand: Array = player.card_manager.get_pile("hand")
	for index in hand.size():
		var card = hand[index]
		var button = _new_button("HandCardButton%d" % index, _card_button_text(card))
		button.disabled = not _can_play_card_from_hand(card)
		button.pressed.connect(_play_card_from_hand.bind(card))
		hand_buttons_container.add_child(button)


func _card_button_text(card) -> String:
	var cost := 0
	if card != null and "cost" in card:
		cost = int(card.cost)
	return "%s（%d）" % [_card_display_name(card), cost]


func _can_play_card_from_hand(card) -> bool:
	if game_state == null or combat == null or game_state.player == null:
		return false
	if game_state.player.card_manager == null:
		return false
	if not game_state.player.card_manager.get_pile("hand").has(card):
		return false
	if card != null and card.has_method("can_play") and not card.can_play(game_state):
		return false
	if card != null and str(card.get("target_type")) == "enemy_select" and _first_alive_enemy() == null:
		return false
	return true


func _enemy_hp_text() -> String:
	if enemy == null:
		return "敌人血量：无"
	return "敌人血量：%d/%d" % [enemy.hp, enemy.max_hp]


func _enemy_intent_text() -> String:
	if enemy == null:
		return "敌人意图：无"
	if "current_intention" in enemy:
		var intention := str(enemy.current_intention)
		if intention == "attack":
			return "敌人意图：攻击"
		return "敌人意图：%s" % intention
	return "敌人意图：攻击"


func _enemy_attack_text() -> String:
	if enemy == null:
		return "预计攻击：无"
	if enemy.has_method("get_intended_damage"):
		return "预计攻击：%d" % int(enemy.get_intended_damage())
	if "intent_damage" in enemy:
		return "预计攻击：%d" % int(enemy.intent_damage)
	if "damage" in enemy:
		return "预计攻击：%d" % int(enemy.damage)
	return "预计攻击：无"


func _power_text(title: String, creature) -> String:
	if creature == null or not creature.has_method("power_summary_text"):
		return "%s：无" % title
	var summary := str(creature.power_summary_text())
	if summary.is_empty():
		summary = "无"
	return "%s：%s" % [title, summary]


func _pile_text(title: String, pile_name: String) -> String:
	if game_state == null or game_state.player == null:
		return "%s（0）：无" % title
	var pile = game_state.player.card_manager.get_pile(pile_name)
	if pile.is_empty():
		return "%s（0）：无" % title
	var names := PackedStringArray()
	for card in pile:
		names.append(_card_display_name(card))
	return "%s（%d）：%s" % [title, pile.size(), ", ".join(names)]


func _sync_value_inputs() -> void:
	if game_state == null or game_state.player == null or enemy == null:
		return
	player_hp_input.text = str(game_state.player.hp)
	energy_input.text = str(game_state.player.energy)
	block_input.text = str(game_state.player.block)
	enemy_hp_input.text = str(enemy.hp)


func _card_display_name(card) -> String:
	if card == null:
		return "未知"
	if "card_name" in card:
		return str(card.card_name)
	return "未知"


func _first_alive_enemy():
	if combat == null:
		return null
	for candidate in combat.enemies:
		if candidate == null:
			continue
		if candidate.has_method("is_dead") and candidate.is_dead():
			continue
		return candidate
	return null


func _player_snapshot() -> Dictionary:
	if game_state == null or game_state.player == null:
		return {"hp": 0, "energy": 0, "block": 0}
	var player = game_state.player
	return {"hp": player.hp, "energy": player.energy, "block": player.block}


func _enemy_hp_value() -> int:
	if enemy == null:
		return 0
	return enemy.hp


func _show_map_panel_state() -> void:
	if game_flow == null:
		return
	var floor_index = game_flow.get_current_floor_index()
	var floor_name = _get_floor_display_name(floor_index)
	current_floor_label.text = "当前楼层：%s" % floor_name

	var room_types: Array = game_flow.get_current_floor_room_types()
	var room_names: Array = []
	for rt in room_types:
		match str(rt):
			"combat":
				room_names.append("战斗房间")
			"rest":
				room_names.append("休息房间")
			"boss":
				room_names.append("BOSS 房间")
			_:
				room_names.append(str(rt))
	room_choices_label.text = "可选房间：%s" % ", ".join(room_names)

	enter_room_button.disabled = room_types.is_empty()

	for child in next_floor_container.get_children():
		next_floor_container.remove_child(child)
		child.free()
	next_floor_container.visible = false

	var next_floors: Array = game_flow.get_available_next_floors()
	if not next_floors.is_empty():
		for option in next_floors:
			var btn = _new_button("NextFloorButton%d" % option["floor_index"], "→ %s" % option["floor_name"])
			btn.pressed.connect(_on_next_floor_selected.bind(option["floor_index"]))
			next_floor_container.add_child(btn)


func _get_floor_display_name(floor_index: int) -> String:
	var floors = StmMapDataScript.FLOORS
	if floor_index >= 0 and floor_index < floors.size():
		return str(floors[floor_index].get("name", "第 %d 层" % (floor_index + 1)))
	return "第 %d 层" % (floor_index + 1)


func _append_card_log(card, before_player: Dictionary, before_enemy_hp: int, result: int) -> void:
	var card_name := _card_display_name(card)
	var after_player := _player_snapshot()
	var after_enemy_hp := _enemy_hp_value()
	var damage: int = max(before_enemy_hp - after_enemy_hp, 0)
	var block_gain: int = max(int(after_player["block"]) - int(before_player["block"]), 0)
	var energy_before: int = int(before_player["energy"])
	var energy_after: int = int(after_player["energy"])
	if damage > 0:
		_append_log(
			"打出 %s，敌人受到 %d 点伤害" % [card_name, damage],
			"打出 %s：能量 %d -> %d；敌人 HP %d -> %d；%s 进入弃牌堆；结局检查 %d。"
				% [card_name, energy_before, energy_after, before_enemy_hp, after_enemy_hp, card_name, result]
		)
	elif block_gain > 0:
		_append_log(
			"打出 %s，获得 %d 点格挡" % [card_name, block_gain],
			"打出 %s：能量 %d -> %d；格挡 %d -> %d；%s 进入弃牌堆；结局检查 %d。"
				% [card_name, energy_before, energy_after, int(before_player["block"]), int(after_player["block"]), card_name, result]
		)
	else:
		_append_log(
			"打出 %s" % card_name,
			"打出 %s：能量 %d -> %d；结局检查 %d。"
				% [card_name, energy_before, energy_after, result]
		)


func _result_message(result: int, fallback: String) -> String:
	match result:
		TypesScript.TerminalResult.COMBAT_WIN:
			return "战斗结果：胜利"
		TypesScript.TerminalResult.COMBAT_LOSE:
			return "战斗结果：失败"
		_:
			return fallback


func _reset_log() -> void:
	simple_log_entries.clear()
	detail_log_entries.clear()


func _append_log(simple_text: String, detail_text: String = "") -> void:
	simple_log_entries.append(simple_text)
	if detail_text.is_empty():
		detail_log_entries.append(simple_text)
	else:
		detail_log_entries.append(detail_text)


func _refresh_log() -> void:
	if log_label == null:
		return
	var entries := detail_log_entries if detailed_log_check_box != null and detailed_log_check_box.button_pressed else simple_log_entries
	log_label.text = "\n".join(entries)


func _parse_non_negative_int(field_name: String, raw_text: String, max_value: int = -1) -> Dictionary:
	var stripped := raw_text.strip_edges()
	if stripped.is_empty():
		return {"ok": false, "error": "输入错误：%s不能为空" % field_name}
	if not stripped.is_valid_int():
		return {"ok": false, "error": "输入错误：%s必须是整数" % field_name}
	var value := int(stripped)
	if value < 0:
		return {"ok": false, "error": "输入错误：%s不能小于 0" % field_name}
	if max_value >= 0 and value > max_value:
		return {"ok": false, "error": "输入错误：%s不能超过 %d" % [field_name, max_value]}
	return {"ok": true, "value": value}


func _collect_value_inputs() -> Dictionary:
	if game_state == null or game_state.player == null or enemy == null:
		return {"ok": false, "error": "输入错误：战斗尚未开始"}
	var player = game_state.player
	var player_hp_result := _parse_non_negative_int("玩家血量", player_hp_input.text, player.max_hp)
	if not player_hp_result.ok:
		return player_hp_result
	var energy_result := _parse_non_negative_int("玩家能量", energy_input.text)
	if not energy_result.ok:
		return energy_result
	var block_result := _parse_non_negative_int("玩家格挡", block_input.text)
	if not block_result.ok:
		return block_result
	var enemy_hp_result := _parse_non_negative_int("敌人血量", enemy_hp_input.text, enemy.max_hp)
	if not enemy_hp_result.ok:
		return enemy_hp_result
	return {
		"ok": true,
		"player_hp": player_hp_result.value,
		"energy": energy_result.value,
		"block": block_result.value,
		"enemy_hp": enemy_hp_result.value,
	}


func _on_detailed_log_toggled(_pressed: bool) -> void:
	_refresh_log()


func _on_reset_pressed() -> void:
	start_debug_combat()


func _on_apply_values_pressed() -> void:
	var values := _collect_value_inputs()
	if not values.ok:
		status_message = values.error
		_append_log(values.error, "%s；本次输入没有写入任何战斗状态。" % values.error)
		_refresh_display()
		return
	var player = game_state.player
	player.hp = values.player_hp
	player.energy = values.energy
	player.block = values.block
	enemy.hp = values.enemy_hp
	status_message = "数值已应用"
	_append_log(
		"应用数值：玩家 HP 设为 %d，敌人 HP 设为 %d" % [player.hp, enemy.hp],
		"应用数值：玩家 HP=%d/%d，能量 %d/%d，格挡 %d，敌人 HP=%d/%d。"
			% [player.hp, player.max_hp, player.energy, player.max_energy, player.block, enemy.hp, enemy.max_hp]
	)
	_refresh_display()


func _on_enter_room_pressed() -> void:
	if game_flow == null:
		status_message = "流程尚未初始化"
		_append_log(status_message)
		_refresh_display()
		return
	game_flow.enter_current_room()
	var room = game_flow.get_current_room()
	if room == null:
		status_message = "进入房间失败"
		_append_log(status_message)
		_refresh_display()
		return
	var room_type = room.get_room_type()
	if room_type == "rest":
		var player = game_state.player
		var before_hp: int = player.hp if player != null else 0
		game_flow.complete_current_room()
		var after_hp: int = player.hp if player != null else 0
		var healed: int = after_hp - before_hp
		status_message = "休息房间已完成"
		_append_log(
			"休息房间：恢复 %d 点 HP（%d → %d）" % [healed, before_hp, after_hp],
			"休息房间：HP %d → %d。" % [before_hp, after_hp]
		)
		_on_room_completed()
		return
	map_panel.visible = false
	enemy = room.get_enemy() if room.has_method("get_enemy") else null
	combat = room.get_combat() if room.has_method("get_combat") else null
	status_message = "等待行动"
	_append_log("战斗开始", "战斗开始：玩家进入%s。" % _get_room_type_cn(room_type))
	_refresh_display()


func _on_room_completed() -> void:
	if game_flow == null:
		return
	if game_flow.is_flow_completed():
		map_panel.visible = true
		victory_label.visible = true
		_show_map_panel_state()
		status_message = "游戏通关"
		_append_log("游戏通关！", "游戏通关：BOSS 已被击败。")
		_rebuild_hand_buttons()
		_refresh_display()
		return
	map_panel.visible = true
	next_floor_container.visible = true
	var next_floors: Array = game_flow.get_available_next_floors()
	var floor_names: Array = []
	for option in next_floors:
		floor_names.append(str(option.get("floor_name", "")))
	status_message = "房间完成，选择下一层"
	_append_log("房间完成", "可选下一层：%s。" % ", ".join(floor_names))
	_show_map_panel_state()
	_rebuild_hand_buttons()
	_refresh_display()


func _on_next_floor_selected(floor_index: int) -> void:
	if game_flow == null:
		return
	game_flow.advance_to_next_floor(floor_index)
	enemy = null
	combat = null
	game_state.current_combat = null
	status_message = "已到达 %s" % _get_floor_display_name(floor_index)
	_append_log(status_message, "推进到 %s。" % _get_floor_display_name(floor_index))
	_refresh_display()


func _get_room_type_cn(room_type: String) -> String:
	match room_type:
		"combat":
			return "战斗房间"
		"rest":
			return "休息房间"
		"boss":
			return "BOSS 房间"
		_:
			return room_type


func _rebuild_hand_buttons() -> void:
	if hand_buttons_container == null:
		return
	for child in hand_buttons_container.get_children():
		hand_buttons_container.remove_child(child)
		child.free()
	if game_state != null and game_state.player != null:
		_refresh_hand_buttons(game_state.player)
