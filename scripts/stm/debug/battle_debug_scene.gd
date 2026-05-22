class_name StmBattleDebugScene
extends Control

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

var game_state
var combat
var enemy
var status_message: String = "等待行动"

var player_hp_label: Label
var energy_label: Label
var block_label: Label
var enemy_hp_label: Label
var hand_label: Label
var status_label: Label
var strike_button: Button
var defend_button: Button
var end_turn_button: Button


func _ready() -> void:
	_build_ui()
	start_debug_combat()


func start_debug_combat() -> void:
	var deck: Array = [
		StrikeScript.new(),
		DefendScript.new(),
		StrikeScript.new(),
		DefendScript.new(),
	]
	var player = PlayerScript.new(deck)
	var bootstrap = GameBootstrapScript.new()
	game_state = bootstrap.create_game(player)
	enemy = DummyEnemyScript.new()
	combat = bootstrap.create_combat(game_state, [enemy], "debug")
	status_message = "等待行动"
	combat.start(game_state)
	_refresh_display()


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
	title.text = "最小战斗调试"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	var metrics = HBoxContainer.new()
	metrics.name = "Metrics"
	metrics.add_theme_constant_override("separation", 16)
	layout.add_child(metrics)

	player_hp_label = _new_label("PlayerHpLabel")
	metrics.add_child(player_hp_label)
	energy_label = _new_label("EnergyLabel")
	metrics.add_child(energy_label)
	block_label = _new_label("BlockLabel")
	metrics.add_child(block_label)

	var enemy_panel = VBoxContainer.new()
	enemy_panel.name = "EnemyPanel"
	enemy_panel.add_theme_constant_override("separation", 8)
	layout.add_child(enemy_panel)

	enemy_hp_label = _new_label("EnemyHpLabel")
	enemy_panel.add_child(enemy_hp_label)

	hand_label = _new_label("HandLabel")
	hand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hand_label)

	status_label = _new_label("StatusLabel")
	layout.add_child(status_label)

	var buttons = HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 8)
	layout.add_child(buttons)

	strike_button = _new_button("StrikeButton", "Strike")
	strike_button.pressed.connect(_on_strike_pressed)
	buttons.add_child(strike_button)

	defend_button = _new_button("DefendButton", "Defend")
	defend_button.pressed.connect(_on_defend_pressed)
	buttons.add_child(defend_button)

	end_turn_button = _new_button("EndTurnButton", "结束回合")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	buttons.add_child(end_turn_button)


func _new_label(label_name: String) -> Label:
	var label = Label.new()
	label.name = label_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _new_button(button_name: String, button_text: String) -> Button:
	var button = Button.new()
	button.name = button_name
	button.text = button_text
	button.custom_minimum_size = Vector2(120.0, 40.0)
	return button


func _on_strike_pressed() -> void:
	_play_first_card_named("Strike")


func _on_defend_pressed() -> void:
	_play_first_card_named("Defend")


func _on_end_turn_pressed() -> void:
	if game_state == null or combat == null:
		status_message = "战斗尚未开始"
		_refresh_display()
		return
	var result = combat.end_turn(game_state)
	status_message = _result_message(result, "敌人回合结算完成")
	_refresh_display()


func _play_first_card_named(card_name: String) -> void:
	if game_state == null or combat == null:
		status_message = "战斗尚未开始"
		_refresh_display()
		return
	var card = _find_card_by_name(card_name)
	if card == null:
		status_message = "手牌中没有 %s" % card_name
		_refresh_display()
		return
	var targets: Array = []
	if str(card.get("target_type")) == "enemy_select":
		var target = _first_alive_enemy()
		if target == null:
			status_message = "没有可选敌人"
			_refresh_display()
			return
		targets.append(target)
	var result = combat.play_card(game_state, card, targets)
	status_message = _result_message(result, "已打出 %s" % card_name)
	_refresh_display()


func _refresh_display() -> void:
	if game_state == null or game_state.player == null:
		return

	var player = game_state.player
	player_hp_label.text = "玩家血量：%d/%d" % [player.hp, player.max_hp]
	energy_label.text = "能量：%d/%d" % [player.energy, player.max_energy]
	block_label.text = "格挡：%d" % player.block
	enemy_hp_label.text = _enemy_hp_text()
	hand_label.text = _hand_text()
	status_label.text = status_message

	strike_button.disabled = _find_card_by_name("Strike") == null or _first_alive_enemy() == null
	defend_button.disabled = _find_card_by_name("Defend") == null
	end_turn_button.disabled = combat == null


func _enemy_hp_text() -> String:
	if enemy == null:
		return "敌人血量：无"
	return "敌人血量：%d/%d" % [enemy.hp, enemy.max_hp]


func _hand_text() -> String:
	var hand = game_state.player.card_manager.get_pile("hand")
	if hand.is_empty():
		return "手牌（0）：无"
	var names := PackedStringArray()
	for card in hand:
		names.append(_card_display_name(card))
	return "手牌（%d）：%s" % [hand.size(), ", ".join(names)]


func _card_display_name(card) -> String:
	if card == null:
		return "未知"
	if "card_name" in card:
		return str(card.card_name)
	return "未知"


func _find_card_by_name(card_name: String):
	if game_state == null or game_state.player == null:
		return null
	var hand = game_state.player.card_manager.get_pile("hand")
	for card in hand:
		if _card_display_name(card) == card_name:
			return card
	return null


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


func _result_message(result: int, fallback: String) -> String:
	match result:
		TypesScript.TerminalResult.COMBAT_WIN:
			return "战斗结果：胜利"
		TypesScript.TerminalResult.COMBAT_LOSE:
			return "战斗结果：失败"
		_:
			return fallback
