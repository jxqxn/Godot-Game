class_name StmBattleDebugScene
extends Control

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

var game_state
var combat
var enemy
var current_fixture_name: String = ""
var status_message: String = "等待行动"

var player_hp_label: Label
var energy_label: Label
var block_label: Label
var enemy_hp_label: Label
var enemy_intent_label: Label
var enemy_attack_label: Label
var hand_label: Label
var draw_pile_label: Label
var discard_pile_label: Label
var status_label: Label
var strike_button: Button
var defend_button: Button
var end_turn_button: Button
var player_hp_input: LineEdit
var energy_input: LineEdit
var block_input: LineEdit
var enemy_hp_input: LineEdit
var apply_values_button: Button
var reset_button: Button
var detailed_log_check_box: CheckBox
var log_label: Label
var simple_log_entries: Array[String] = []
var detail_log_entries: Array[String] = []


func _ready() -> void:
	_build_ui()
	start_debug_combat()


func start_debug_combat() -> void:
	var fixture = FixedBattleFixtureScript.new()
	var context: Dictionary = fixture.create_context()
	if not _apply_fixture_context(context):
		_handle_fixture_failure()
		return
	status_message = "等待行动"
	combat.start(game_state)
	_reset_log()
	_append_log("战斗开始", "战斗开始：玩家抽取起始手牌，敌人 DummyEnemy 准备攻击。")
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
	status_message = "测试战斗创建失败"
	_reset_log()
	_append_log(status_message)
	if status_label != null:
		status_label.text = status_message
	if log_label != null:
		_refresh_log()
	if strike_button != null:
		strike_button.disabled = true
	if defend_button != null:
		defend_button.disabled = true
	if end_turn_button != null:
		end_turn_button.disabled = true


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
	enemy_intent_label = _new_label("EnemyIntentLabel")
	enemy_panel.add_child(enemy_intent_label)
	enemy_attack_label = _new_label("EnemyAttackLabel")
	enemy_panel.add_child(enemy_attack_label)

	var piles_panel = VBoxContainer.new()
	piles_panel.name = "PilesPanel"
	piles_panel.add_theme_constant_override("separation", 6)
	layout.add_child(piles_panel)

	hand_label = _new_label("HandLabel")
	hand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(hand_label)
	draw_pile_label = _new_label("DrawPileLabel")
	draw_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(draw_pile_label)
	discard_pile_label = _new_label("DiscardPileLabel")
	discard_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piles_panel.add_child(discard_pile_label)

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

	reset_button = _new_button("ResetButton", "重开战斗")
	reset_button.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset_button)

	var value_editor = GridContainer.new()
	value_editor.name = "ValueEditor"
	value_editor.columns = 2
	value_editor.add_theme_constant_override("separation", 8)
	layout.add_child(value_editor)

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
	log_panel.add_theme_constant_override("separation", 6)
	layout.add_child(log_panel)

	detailed_log_check_box = CheckBox.new()
	detailed_log_check_box.name = "DetailedLogCheckBox"
	detailed_log_check_box.text = "显示详细日志"
	detailed_log_check_box.toggled.connect(_on_detailed_log_toggled)
	log_panel.add_child(detailed_log_check_box)

	log_label = _new_label("LogLabel")
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _on_strike_pressed() -> void:
	_play_first_card_named("Strike")


func _on_defend_pressed() -> void:
	_play_first_card_named("Defend")


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
		"结束回合，DummyEnemy 攻击造成 %d 点伤害" % hp_loss,
		"结束回合：玩家 HP %d -> %d；格挡 %d -> %d；能量 %d -> %d；敌人意图执行；进入下一玩家回合；结局检查=%d。"
			% [before_hp, after_hp, before_block, after_block, before_energy, after_energy, result]
	)
	_refresh_display()


func _play_first_card_named(card_name: String) -> void:
	if game_state == null or combat == null:
		status_message = "战斗尚未开始"
		_append_log("出牌失败", "出牌失败：战斗尚未开始。")
		_refresh_display()
		return
	var card = _find_card_by_name(card_name)
	if card == null:
		status_message = "手牌中没有%s" % card_name
		_append_log(status_message)
		_refresh_display()
		return
	var targets: Array = []
	if str(card.get("target_type")) == "enemy_select":
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
	status_message = _result_message(result, "已打出%s" % card_name)
	_append_card_log(card_name, before_player, before_enemy_hp, result)
	_refresh_display()


func _refresh_display() -> void:
	if game_state == null or game_state.player == null:
		return

	var player = game_state.player
	player_hp_label.text = "玩家血量：%d/%d" % [player.hp, player.max_hp]
	energy_label.text = "能量：%d/%d" % [player.energy, player.max_energy]
	block_label.text = "格挡：%d" % player.block
	enemy_hp_label.text = _enemy_hp_text()
	enemy_intent_label.text = _enemy_intent_text()
	enemy_attack_label.text = _enemy_attack_text()
	hand_label.text = _pile_text("手牌", "hand")
	draw_pile_label.text = _pile_text("抽牌堆", "draw_pile")
	discard_pile_label.text = _pile_text("弃牌堆", "discard_pile")
	status_label.text = status_message
	_sync_value_inputs()
	_refresh_log()

	strike_button.disabled = _find_card_by_name("Strike") == null or _first_alive_enemy() == null
	defend_button.disabled = _find_card_by_name("Defend") == null
	end_turn_button.disabled = combat == null


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
		return "预计攻击：0"
	if enemy.has_method("get_intended_damage"):
		return "预计攻击：%d" % int(enemy.get_intended_damage())
	if "intent_damage" in enemy:
		return "预计攻击：%d" % int(enemy.intent_damage)
	if "damage" in enemy:
		return "预计攻击：%d" % int(enemy.damage)
	return "预计攻击：6"


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


func _player_snapshot() -> Dictionary:
	if game_state == null or game_state.player == null:
		return {"hp": 0, "energy": 0, "block": 0}
	var player = game_state.player
	return {"hp": player.hp, "energy": player.energy, "block": player.block}


func _enemy_hp_value() -> int:
	if enemy == null:
		return 0
	return enemy.hp


func _append_card_log(card_name: String, before_player: Dictionary, before_enemy_hp: int, result: int) -> void:
	var after_player := _player_snapshot()
	var after_enemy_hp := _enemy_hp_value()
	var before_energy: int = int(before_player["energy"])
	var before_block: int = int(before_player["block"])
	var after_energy: int = int(after_player["energy"])
	var after_block: int = int(after_player["block"])
	if card_name == "Strike":
		var damage: int = max(before_enemy_hp - after_enemy_hp, 0)
		_append_log(
			"打出 Strike，敌人受到 %d 点伤害" % damage,
			"打出 Strike：能量 %d -> %d；敌人 HP %d -> %d；Strike 进入弃牌堆；结局检查=%d。"
				% [before_energy, after_energy, before_enemy_hp, after_enemy_hp, result]
		)
	elif card_name == "Defend":
		var block_gain: int = max(after_block - before_block, 0)
		_append_log(
			"打出 Defend，获得 %d 点格挡" % block_gain,
			"打出 Defend：能量 %d -> %d；格挡 %d -> %d；Defend 进入弃牌堆；结局检查=%d。"
				% [before_energy, after_energy, before_block, after_block, result]
		)
	else:
		_append_log("打出 %s" % card_name, "打出 %s：结局检查=%d。" % [card_name, result])


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
		"应用数值：玩家 HP=%d/%d，能量=%d/%d，格挡=%d，敌人 HP=%d/%d。"
			% [player.hp, player.max_hp, player.energy, player.max_energy, player.block, enemy.hp, enemy.max_hp]
	)
	_refresh_display()
