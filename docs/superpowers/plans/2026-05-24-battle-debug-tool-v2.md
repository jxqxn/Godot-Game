# 策划战斗调试工具 v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有最小战斗调试场景上，做出策划可直接测试的单屏调试工具，能查看玩家/敌人/牌堆/日志，并能打牌、结束回合、重开战斗、应用基础数值。

**Architecture:** 只增强 `StmBattleDebugScene` 这一层，让它负责构建调试 UI、读取输入、调用现有规则层并刷新显示；战斗规则仍归 `scripts/stm/engine`、`cards`、`player`、`enemies` 等模块所有。测试继续放在现有 GUT 场景测试里，先用中文 Given-When-Then 行为注释描述行为，再写断言和实现。

**Tech Stack:** Godot 4.6.2、GDScript、GUT、现有 `scripts/stm` 规则层、现有 `addons/gut/gut_cmdln.gd`。

---

## 文件结构

- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`
  - 负责策划调试场景的行为测试。
  - 每个新增测试方法先写中文 Given-When-Then 注释，再写测试代码。
  - 继续复用 `_instantiate_debug_scene()`、`_label_text()`、`_press_button()` 等测试辅助函数，并新增输入框、勾选框读取辅助函数。

- Modify: `scripts/stm/debug/battle_debug_scene.gd`
  - 负责调试场景 UI、按钮回调、数值输入校验、简洁/详细日志显示。
  - 不新增正式卡牌库、敌人库、选择器或存档能力。
  - 不修改规则层，只通过 `Combat.start()`、`Combat.play_card()`、`Combat.end_turn()` 和当前对象状态读取来驱动显示。

- Unchanged: `scenes/stm/battle_debug_scene.tscn`
  - 继续保持一个挂载脚本的 `Control` 场景，不在本轮把动态 UI 改成手工节点树。

## 安全、边界、依赖

- 不修改 `slay-the-model-main/`。
- 不引入网络请求、Python 运行时或新的 Godot 插件。
- 不把该场景升级成正式战斗 UI。
- 固定使用当前测试内容：`Strike`、`Defend`、`DummyEnemy`。
- 数值应用先完整校验所有输入，再一次性写入状态，避免半应用。
- 运行测试使用：

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

---

### Task 1: 初始调试界面覆盖测试

**Files:**
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`

- [ ] **Step 1: 写出失败测试的方法名和中文 BDD 注释**

在 `test_debug_scene_shows_initial_combat_state()` 后新增方法骨架。先只写方法名和 Given-When-Then 注释。

```gdscript
func test_debug_scene_shows_planner_tool_surface() -> void:
	# Given：策划打开固定测试战斗的调试工具。
	# When：场景完成初始化并刷新所有调试面板。
	# Then：界面展示玩家状态、敌人意图、手牌、抽牌堆、弃牌堆、数值输入、重开按钮和详细日志开关。
```

- [ ] **Step 2: 补充测试断言**

把上一步的方法补成完整测试：

```gdscript
func test_debug_scene_shows_planner_tool_surface() -> void:
	# Given：策划打开固定测试战斗的调试工具。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化并刷新所有调试面板。
	var title_text := _label_text(scene, "Layout/TitleLabel")
	# Then：界面展示玩家状态、敌人意图、手牌、抽牌堆、弃牌堆、数值输入、重开按钮和详细日志开关。
	assert_eq(title_text, "战斗调试工具")
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyIntentLabel"), "敌人意图：攻击")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyAttackLabel"), "预计攻击：6")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DrawPileLabel").contains("抽牌堆（0）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("弃牌堆（0）："))
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "70")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "3")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "0")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "20")
	assert_not_null(scene.get_node_or_null("Layout/Buttons/ResetButton"))
	assert_false(_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))
```

同时新增测试辅助函数：

```gdscript
func _line_edit_text(scene: Node, node_path: String) -> String:
	var input = scene.get_node_or_null(node_path)
	if input == null:
		return ""
	return str(input.text)


func _set_line_edit_text(scene: Node, node_path: String, value: String) -> void:
	var input = scene.get_node_or_null(node_path)
	assert_not_null(input)
	if input == null:
		return
	input.text = value


func _check_box_pressed(scene: Node, node_path: String) -> bool:
	var check_box = scene.get_node_or_null(node_path)
	if check_box == null:
		return false
	return check_box.button_pressed


func _set_check_box_pressed(scene: Node, node_path: String, pressed: bool) -> void:
	var check_box = scene.get_node_or_null(node_path)
	assert_not_null(check_box)
	if check_box == null:
		return
	check_box.button_pressed = pressed
	check_box.emit_signal("toggled", pressed)
```

- [ ] **Step 3: 运行测试确认失败**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL，缺少 `EnemyIntentLabel`、`PilesPanel`、`ValueEditor`、`ResetButton` 或 `LogPanel` 等节点。

---

### Task 2: 实现调试界面基础面板

**Files:**
- Modify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: 增加节点变量和日志状态**

在现有按钮变量附近补充：

```gdscript
var enemy_intent_label: Label
var enemy_attack_label: Label
var draw_pile_label: Label
var discard_pile_label: Label
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
```

- [ ] **Step 2: 修改战斗启动文案并初始化日志**

把 `start_debug_combat()` 中状态文案改为中文可读文本，并在 `combat.start(game_state)` 后初始化日志：

```gdscript
	status_message = "等待行动"
	combat.start(game_state)
	_reset_log()
	_append_log("战斗开始", "战斗开始：玩家抽取起始手牌，敌人 DummyEnemy 准备攻击。")
	_refresh_display()
```

- [ ] **Step 3: 扩展 `_build_ui()` 的面板结构**

保留 `_build_ui()` 开头的 `Layout` 判空和根节点创建代码。根节点创建后，按下面顺序创建标题区、玩家状态区、敌人区、牌堆区、状态提示、按钮区、数值编辑区和日志区。旧的 `Layout/HandLabel` 不保留，手牌标签只放在 `Layout/PilesPanel/HandLabel`。

```gdscript
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
```

接着创建完整按钮区，四个按钮都放在 `Layout/Buttons` 下：

```gdscript
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
```

在按钮区之后加入数值编辑区：

```gdscript
	var value_editor = GridContainer.new()
	value_editor.name = "ValueEditor"
	value_editor.columns = 2
	value_editor.add_theme_constant_override("h_separation", 8)
	value_editor.add_theme_constant_override("v_separation", 6)
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
	value_editor.add_child(_new_label_with_text("ApplyValuesSpacer", ""))
	value_editor.add_child(apply_values_button)
```

在最后加入日志区：

```gdscript
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
```

- [ ] **Step 4: 增加 UI 工厂函数**

```gdscript
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
```

- [ ] **Step 5: 扩展刷新函数**

把 `_refresh_display()` 中的中文显示统一成可读中文，并补充敌人意图、牌堆、输入框、日志刷新：

```gdscript
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
```

新增文本辅助函数：

```gdscript
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
```

- [ ] **Step 6: 增加日志函数和空回调**

```gdscript
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


func _on_detailed_log_toggled(_pressed: bool) -> void:
	_refresh_log()


func _on_reset_pressed() -> void:
	start_debug_combat()


func _on_apply_values_pressed() -> void:
	status_message = "数值编辑尚未执行"
	_refresh_display()
```

- [ ] **Step 7: 运行测试确认 Task 1 通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: Task 1 新增测试 PASS；后续未实现的数值应用测试尚未存在。

- [ ] **Step 8: 提交界面基础面板**

```powershell
git add scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd
git commit -m "feat(debug): expand battle debug tool surface"
```

---

### Task 3: 数值应用的行为测试

**Files:**
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`

- [ ] **Step 1: 先写合法输入测试的方法名和中文 BDD 注释**

```gdscript
func test_apply_values_updates_combat_state_and_display() -> void:
	# Given：策划在调试工具中输入一组合法的玩家和敌人数值。
	# When：点击应用数值按钮。
	# Then：战斗状态、界面显示和简洁日志同时反映这次数值修改。
```

- [ ] **Step 2: 补全合法输入测试**

```gdscript
func test_apply_values_updates_combat_state_and_display() -> void:
	# Given：策划在调试工具中输入一组合法的玩家和敌人数值。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "10")
	# When：点击应用数值按钮。
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	# Then：战斗状态、界面显示和简洁日志同时反映这次数值修改。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：40/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：9")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：10/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值：玩家 HP 设为 40，敌人 HP 设为 10"))
```

- [ ] **Step 3: 先写非法输入测试的方法名和中文 BDD 注释**

```gdscript
func test_apply_values_rejects_invalid_input_without_partial_state_change() -> void:
	# Given：当前战斗已有明确状态，策划输入一个非法敌人血量。
	# When：点击应用数值按钮。
	# Then：玩家和敌人的所有数值保持原样，并显示输入错误日志。
```

- [ ] **Step 4: 补全非法输入测试**

```gdscript
func test_apply_values_rejects_invalid_input_without_partial_state_change() -> void:
	# Given：当前战斗已有明确状态，策划输入一个非法敌人血量。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "不是数字")
	# When：点击应用数值按钮。
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	# Then：玩家和敌人的所有数值保持原样，并显示输入错误日志。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("输入错误：敌人血量必须是整数"))
```

- [ ] **Step 5: 运行测试确认失败**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL，`_on_apply_values_pressed()` 还没有真正校验和写入数值。

---

### Task 4: 实现数值应用和原子校验

**Files:**
- Modify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: 新增输入解析函数**

```gdscript
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
```

- [ ] **Step 2: 新增输入收集函数**

```gdscript
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
```

- [ ] **Step 3: 实现 `_on_apply_values_pressed()`**

```gdscript
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
```

- [ ] **Step 4: 运行测试确认通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: Task 3 新增两个测试 PASS。

- [ ] **Step 5: 提交数值编辑能力**

```powershell
git add scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd
git commit -m "feat(debug): apply planner battle values"
```

---

### Task 5: 打牌、结束回合和日志行为测试

**Files:**
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`

- [ ] **Step 1: 更新 Strike 测试的中文 BDD 注释和断言**

把 `test_strike_button_plays_strike_and_refreshes_display()` 的断言扩展为：

```gdscript
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（3）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("Strike"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))
```

- [ ] **Step 2: 更新 Defend 测试的中文 BDD 注释和断言**

把 `test_defend_button_plays_defend_and_refreshes_display()` 的断言扩展为：

```gdscript
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：5")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（3）："))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("Defend"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Defend，获得 5 点格挡"))
```

- [ ] **Step 3: 更新结束回合测试的中文 BDD 注释和断言**

把 `test_end_turn_button_starts_next_player_turn_and_reenables_card_buttons()` 的断言扩展为：

```gdscript
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：69/70")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（4）："))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("结束回合，DummyEnemy 攻击造成 1 点伤害"))
	assert_false(_button_disabled(scene, "Layout/Buttons/StrikeButton"))
	assert_false(_button_disabled(scene, "Layout/Buttons/DefendButton"))
```

- [ ] **Step 4: 新增详细日志开关测试**

先写方法名和中文 BDD 注释，再补全测试：

```gdscript
func test_detailed_log_toggle_switches_between_simple_and_detailed_entries() -> void:
	# Given：策划已经打出 Strike，简洁日志只显示关键结果。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/StrikeButton")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	# When：打开详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", true)
	# Then：日志显示规则过程细节。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("Strike 进入弃牌堆"))
	# When：关闭详细日志开关。
	_set_check_box_pressed(scene, "Layout/LogPanel/DetailedLogCheckBox", false)
	# Then：日志回到简洁结果。
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 Strike，敌人受到 6 点伤害"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("能量 3 -> 2"))
```

- [ ] **Step 5: 运行测试确认失败**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL，打牌和结束回合还没有写入指定日志细节，牌堆节点路径也需要新实现支撑。

---

### Task 6: 实现战斗操作日志和按钮刷新

**Files:**
- Modify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: 给打牌前后状态加快照函数**

```gdscript
func _player_snapshot() -> Dictionary:
	if game_state == null or game_state.player == null:
		return {"hp": 0, "energy": 0, "block": 0}
	var player = game_state.player
	return {"hp": player.hp, "energy": player.energy, "block": player.block}


func _enemy_hp_value() -> int:
	if enemy == null:
		return 0
	return enemy.hp
```

- [ ] **Step 2: 修改 `_play_first_card_named()` 写入日志**

在调用 `combat.play_card()` 前记录快照，调用后生成日志：

```gdscript
	var before_player := _player_snapshot()
	var before_enemy_hp := _enemy_hp_value()
	var result = combat.play_card(game_state, card, targets)
	status_message = _result_message(result, "已打出 %s" % card_name)
	_append_card_log(card_name, before_player, before_enemy_hp, result)
	_refresh_display()
```

新增日志函数：

```gdscript
func _append_card_log(card_name: String, before_player: Dictionary, before_enemy_hp: int, result: int) -> void:
	var after_player := _player_snapshot()
	var after_enemy_hp := _enemy_hp_value()
	if card_name == "Strike":
		var damage := max(before_enemy_hp - after_enemy_hp, 0)
		_append_log(
			"打出 Strike，敌人受到 %d 点伤害" % damage,
			"打出 Strike：能量 %d -> %d；敌人 HP %d -> %d；Strike 进入弃牌堆；结局检查=%d。"
				% [before_player.energy, after_player.energy, before_enemy_hp, after_enemy_hp, result]
		)
	elif card_name == "Defend":
		var block_gain := max(after_player.block - before_player.block, 0)
		_append_log(
			"打出 Defend，获得 %d 点格挡" % block_gain,
			"打出 Defend：能量 %d -> %d；格挡 %d -> %d；Defend 进入弃牌堆；结局检查=%d。"
				% [before_player.energy, after_player.energy, before_player.block, after_player.block, result]
		)
	else:
		_append_log("打出 %s" % card_name, "打出 %s：结局检查=%d。" % [card_name, result])
```

- [ ] **Step 3: 修改结束回合日志**

替换 `_on_end_turn_pressed()` 中调用前后的处理：

```gdscript
	var before_player := _player_snapshot()
	var result = combat.end_turn(game_state)
	var after_player := _player_snapshot()
	var hp_loss := max(before_player.hp - after_player.hp, 0)
	status_message = _result_message(result, "敌人回合结算完成")
	_append_log(
		"结束回合，DummyEnemy 攻击造成 %d 点伤害" % hp_loss,
		"结束回合：玩家 HP %d -> %d；格挡 %d -> %d；能量 %d -> %d；敌人意图执行；进入下一玩家回合；结局检查=%d。"
			% [before_player.hp, after_player.hp, before_player.block, after_player.block, before_player.energy, after_player.energy, result]
	)
	_refresh_display()
```

- [ ] **Step 4: 修改旧路径引用**

把所有旧测试里的 `Layout/HandLabel` 改成 `Layout/PilesPanel/HandLabel`。生产代码只输出新路径，不在场景里创建第二个手牌标签。

- [ ] **Step 5: 运行测试确认通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: 打牌、结束回合、详细日志测试 PASS。

- [ ] **Step 6: 提交日志行为**

```powershell
git add scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd
git commit -m "feat(debug): log planner battle actions"
```

---

### Task 7: 重开战斗行为测试和实现收口

**Files:**
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`
- Modify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: 先写重开测试的方法名和中文 BDD 注释**

```gdscript
func test_reset_button_restarts_fixed_debug_battle() -> void:
	# Given：策划已经打出卡牌并修改了战斗数值。
	# When：点击重开战斗按钮。
	# Then：固定测试战斗、输入框和日志都回到新战斗开始状态。
```

- [ ] **Step 2: 补全重开测试**

```gdscript
func test_reset_button_restarts_fixed_debug_battle() -> void:
	# Given：策划已经打出卡牌并修改了战斗数值。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_press_button(scene, "Layout/Buttons/StrikeButton")
	_set_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput", "40")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnergyInput", "2")
	_set_line_edit_text(scene, "Layout/ValueEditor/BlockInput", "9")
	_set_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput", "10")
	_press_button(scene, "Layout/ValueEditor/ApplyValuesButton")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值"))
	# When：点击重开战斗按钮。
	_press_button(scene, "Layout/Buttons/ResetButton")
	# Then：固定测试战斗、输入框和日志都回到新战斗开始状态。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：20/20")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/PlayerHpInput"), "70")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnergyInput"), "3")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/BlockInput"), "0")
	assert_eq(_line_edit_text(scene, "Layout/ValueEditor/EnemyHpInput"), "20")
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))
	assert_false(_label_text(scene, "Layout/LogPanel/LogLabel").contains("应用数值"))
```

- [ ] **Step 3: 明确 `_on_reset_pressed()` 的重开行为**

实现保持：

```gdscript
func _on_reset_pressed() -> void:
	start_debug_combat()
```

重开战斗保留 `DetailedLogCheckBox` 当前勾选状态，只清空日志内容并写入新的“战斗开始”。输入框必须依赖 `start_debug_combat()` 末尾的 `_refresh_display()` 回到新战斗初始值。

- [ ] **Step 4: 运行测试确认通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: 重开战斗测试 PASS。

- [ ] **Step 5: 提交重开行为**

```powershell
git add scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd
git commit -m "feat(debug): restart fixed battle from debug tool"
```

---

### Task 8: 最终自检、验收和提交状态确认

**Files:**
- Verify: `scripts/stm/tests/test_battle_debug_scene.gd`
- Verify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: 检查计划和实现没有未完成标记**

Run:

```powershell
rg -n "TO[D]O|TB[D]|implement[ ]later|fill[ ]in[ ]details|以后再[说]" docs/superpowers/plans/2026-05-24-battle-debug-tool-v2.md scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd
```

Expected: no matches。

- [ ] **Step 2: 检查空白和换行问题**

Run:

```powershell
git diff --check
```

Expected: no output。

- [ ] **Step 3: 运行全部 GUT 单元测试**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: all tests pass。

- [ ] **Step 4: 查看工作区状态**

Run:

```powershell
git status --short --branch
```

Expected: 当前分支为 `codex/battle-debug-tool-v2`；除已计划提交内容外没有意外文件。若出现 `C:\Users\User/.config/git/ignore` 权限警告，只记录为用户级 Git ignore 权限警告，不当作项目改动。

- [ ] **Step 5: 最终提交**

如果 Task 8 产生了测试或文档修正，提交：

```powershell
git add scripts/stm/tests/test_battle_debug_scene.gd scripts/stm/debug/battle_debug_scene.gd docs/superpowers/plans/2026-05-24-battle-debug-tool-v2.md
git commit -m "test(debug): verify battle debug tool v2"
```

如果 Task 8 没有产生文件改动，不创建空提交。

---

## 自检记录

- Spec 覆盖：初始界面、玩家血量/能量/格挡、手牌/抽牌堆/弃牌堆、敌人血量/意图/攻击、Strike、Defend、结束回合、重开战斗、数值输入、简洁日志、详细日志、非法输入原子性都映射到 Task 1-7。
- 边界覆盖：没有新增正式内容库、选择器、多敌人、存档、网络、Python 或第三方插件；只增强调试场景。
- 依赖覆盖：只使用 Godot、GDScript、GUT 和现有 `scripts/stm`。
- 类型一致性：新增生产函数集中在 `StmBattleDebugScene`；测试辅助函数均接收 `scene: Node` 和节点路径；输入框使用 `LineEdit`，详细日志开关使用 `CheckBox`。
- 字段核对：当前 `StmEnemy` 公开 `current_intention` 和 `intent_damage`；计划中的 `_enemy_intent_text()` 读取 `current_intention` 并把 `attack` 显示为“攻击”，`_enemy_attack_text()` 优先读取 `get_intended_damage()`，再读取 `intent_damage`，最后才回退为固定测试敌人的 `6`；这只服务调试场景，不改变规则层。
