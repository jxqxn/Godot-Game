# 点击手牌出牌调试场景 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让策划调试场景通过点击当前手牌中的卡牌出牌，并把固定调试牌组扩展为中文测试卡牌组。

**Architecture:** 固定战斗夹具负责提供七张中文测试卡；调试 UI 负责把“点击手牌按钮”转换为 `combat.play_card(game_state, card, targets)` 调用；战斗结算继续由 `StmCombat`、`StmCard` 和 Action Queue 负责。固定 `Strike` / `Defend` 出牌按钮从主调试界面移除，结束回合、重开战斗、应用数值和日志控制保留。

**Tech Stack:** Godot 4.6.2、GDScript、GUT、现有 `StmFixedBattleFixture` / `StmCombat` / `StmCard` / `BattleDebugScene`。

---

## 约束和边界

- 只修改 `C:\Users\User\Documents\GitHub\Godot-Game` 内的 Godot 项目。
- 不修改 `slay-the-model-main/` Python 参考项目。
- 不引入新 addon、消息总线、正式卡牌库、正式卡牌 UI、拖拽、目标箭头或多敌人目标选择界面。
- 不改 `StmCombat.play_card()` 的核心职责。
- 测试函数名保留英文；测试内新增或修改的 Given-When-Then 行为注释使用中文。
- 所有正式代码之前先写测试，并确认测试 RED。
- 运行所有单元测试使用：

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

## 文件结构

**Modify**
- `scripts/stm/cards/test/strike.gd`：`card_name` 改为 `打击`。
- `scripts/stm/cards/test/defend.gd`：`card_name` 改为 `防御`。
- `scripts/stm/cards/test/bash.gd`：`card_name` 改为 `痛击`。
- `scripts/stm/cards/test/inflame.gd`：`card_name` 改为 `燃烧`。
- `scripts/stm/cards/test/shrug_it_off.gd`：`card_name` 改为 `耸肩无视`。
- `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`：固定调试牌组加入 `痛击`、`燃烧`、`耸肩无视`。
- `scripts/stm/debug/battle_debug_scene.gd`：移除固定出牌按钮，新增动态手牌按钮容器与点击出牌流程。
- `scripts/stm/tests/core_skeleton_test.gd`：按中文卡名更新骨架战斗测试。
- `scripts/stm/tests/test_fixed_battle_fixture.gd`：验证七张中文调试牌组和 fresh 实例。
- `scripts/stm/tests/test_powers_v1.gd`：验证三张状态测试卡中文名，更新抽牌断言。
- `scripts/stm/tests/test_battle_debug_scene.gd`：验证动态手牌按钮和点击出牌。

**Add / Track**
- `scripts/stm/cards/test/bash.gd.uid`
- `scripts/stm/cards/test/inflame.gd.uid`
- `scripts/stm/cards/test/shrug_it_off.gd.uid`

---

## Task 1: 中文测试卡名与固定调试牌组

**Files:**
- Modify: `scripts/stm/tests/test_fixed_battle_fixture.gd`
- Modify: `scripts/stm/tests/test_powers_v1.gd`
- Modify: `scripts/stm/tests/core_skeleton_test.gd`
- Modify: `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`
- Modify: `scripts/stm/cards/test/strike.gd`
- Modify: `scripts/stm/cards/test/defend.gd`
- Modify: `scripts/stm/cards/test/bash.gd`
- Modify: `scripts/stm/cards/test/inflame.gd`
- Modify: `scripts/stm/cards/test/shrug_it_off.gd`
- Add / Track: `scripts/stm/cards/test/bash.gd.uid`
- Add / Track: `scripts/stm/cards/test/inflame.gd.uid`
- Add / Track: `scripts/stm/cards/test/shrug_it_off.gd.uid`

- [ ] **Step 1: Write the failing fixture deck test**

Update `scripts/stm/tests/test_fixed_battle_fixture.gd` so the deck assertions expect seven Chinese cards:

```gdscript
	var deck: Array = context["player"].card_manager.get_pile("deck")
	assert_eq(deck.size(), 7)
	assert_eq(deck[0].card_name, "打击")
	assert_eq(deck[1].card_name, "防御")
	assert_eq(deck[2].card_name, "打击")
	assert_eq(deck[3].card_name, "防御")
	assert_eq(deck[4].card_name, "痛击")
	assert_eq(deck[5].card_name, "燃烧")
	assert_eq(deck[6].card_name, "耸肩无视")
```

In `test_fixed_battle_fixture_creates_fresh_instances_each_time()`, replace the four-card size and identity assertions with:

```gdscript
	assert_eq(first_deck.size(), 7)
	assert_eq(second_deck.size(), 7)
	for index in first_deck.size():
		assert_false(first_deck[index] == second_deck[index])
```

- [ ] **Step 2: Write failing card-name assertions**

In `scripts/stm/tests/test_powers_v1.gd`, add this test before the behavior tests for the three test cards:

```gdscript
func test_test_cards_use_chinese_display_names() -> void:
	# Given：策划调试牌组使用五张测试卡。
	var strike = StrikeScript.new()
	var bash = BashScript.new()
	var inflame = InflameScript.new()
	var shrug = ShrugItOffScript.new()
	# When：读取这些卡牌的显示名称。
	var names := [strike.card_name, bash.card_name, inflame.card_name, shrug.card_name]
	# Then：测试卡使用中文名称，便于策划在调试界面识别。
	assert_eq(names, ["打击", "痛击", "燃烧", "耸肩无视"])
```

In `test_shrug_it_off_gains_block_and_draws_card()`, update the final draw assertion:

```gdscript
	assert_eq(player.card_manager.hand[0].card_name, "打击")
```

- [ ] **Step 3: Update existing skeleton tests to use Chinese names**

In `scripts/stm/tests/core_skeleton_test.gd`, replace English card lookups and display assertions:

```gdscript
var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "打击")
var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "防御")
```

Update affected comments to keep Chinese BDD wording, for example:

```gdscript
# Given：一场已开始的测试战斗，玩家手牌中有打击。
# When：玩家对 DummyEnemy 打出打击。
# Then：玩家消耗 1 点能量，敌人受到 6 点伤害，打击进入弃牌堆。
```

- [ ] **Step 4: Run tests to verify RED**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL because the fixture still returns four English cards and test cards still use English `card_name`.

- [ ] **Step 5: Implement minimal card names**

Update these `_init()` methods:

```gdscript
# scripts/stm/cards/test/strike.gd
func _init() -> void:
	card_name = "打击"
	card_type = "attack"
	card_rarity = "starter"
	target_type = "enemy_select"
	cost = 1
	base_damage = 6
	upgrade_damage = 9
	reset_values()
```

```gdscript
# scripts/stm/cards/test/defend.gd
func _init() -> void:
	card_name = "防御"
	card_type = "skill"
	card_rarity = "starter"
	target_type = "self"
	cost = 1
	base_block = 5
	upgrade_block = 8
	reset_values()
```

```gdscript
# scripts/stm/cards/test/bash.gd
func _init() -> void:
	card_name = "痛击"
	card_type = "attack"
	card_rarity = "starter"
	target_type = "enemy_select"
	cost = 2
	base_damage = 8
	base_magic = 2
	upgrade_damage = 10
	upgrade_magic = 3
	reset_values()
```

```gdscript
# scripts/stm/cards/test/inflame.gd
func _init() -> void:
	card_name = "燃烧"
	card_type = "power"
	card_rarity = "uncommon"
	target_type = "self"
	cost = 1
	base_magic = 2
	upgrade_magic = 3
	reset_values()
```

```gdscript
# scripts/stm/cards/test/shrug_it_off.gd
func _init() -> void:
	card_name = "耸肩无视"
	card_type = "skill"
	card_rarity = "common"
	target_type = "self"
	cost = 1
	base_block = 8
	base_magic = 1
	upgrade_block = 11
	reset_values()
```

- [ ] **Step 6: Implement minimal fixed deck**

Update `scripts/stm/debug/fixtures/fixed_battle_fixture.gd` constants:

```gdscript
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")
```

Update `create_deck()`:

```gdscript
func create_deck() -> Array:
	return [
		StrikeScript.new(),
		DefendScript.new(),
		StrikeScript.new(),
		DefendScript.new(),
		BashScript.new(),
		InflameScript.new(),
		ShrugItOffScript.new(),
	]
```

- [ ] **Step 7: Run tests to verify Task 1 expected transition state**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: fixture, core, and powers card-name expectations align with Chinese card names. Existing battle debug tests may still fail because the UI still expects fixed `StrikeButton` / `DefendButton`; do not commit this transition state.

- [ ] **Step 8: Keep Task 1 changes unstaged for Task 2**

Do not commit after Task 1. Continue directly to Task 2 so the first implementation commit contains a fully passing state.

---

## Task 2: 调试场景动态手牌按钮

**Files:**
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`
- Modify: `scripts/stm/debug/battle_debug_scene.gd`

- [ ] **Step 1: Write failing tests for hand-card buttons**

In `scripts/stm/tests/test_battle_debug_scene.gd`, update initial display tests so they no longer expect fixed `StrikeButton` / `DefendButton`, and add assertions for `HandButtons`:

```gdscript
func test_debug_scene_shows_initial_combat_state() -> void:
	# Given：策划打开固定调试战斗场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景初始化完成。
	# Then：界面显示玩家血量、能量、格挡、手牌和敌人血量，并为当前手牌生成可点击按钮。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerHpLabel"), "玩家血量：70/70")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：3/3")
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：0")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("手牌（5）："))
	assert_not_null(_debug_node_or_null(scene, "Layout/PilesPanel/HandButtons"))
	assert_eq(_hand_card_button_count(scene), 5)
	assert_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/StrikeButton"))
	assert_null(scene.get_node_or_null("Layout/Body/MainPanel/Buttons/DefendButton"))
```

Add helper functions near `_press_button()`:

```gdscript
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
```

- [ ] **Step 2: Replace fixed button behavior tests with hand-card behavior tests**

Replace `test_strike_button_plays_strike_and_refreshes_display()` with:

```gdscript
func test_clicking_hand_attack_card_plays_that_card_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有打击，敌人是 DummyEnemy。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "打击")
	# When：点击手牌中的打击。
	_press_hand_card_button(scene, "打击")
	# Then：敌人受到 6 点伤害，玩家消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：14/20")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("打击"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))
```

Replace `test_defend_button_plays_defend_and_refreshes_display()` with:

```gdscript
func test_clicking_hand_skill_card_plays_that_card_and_refreshes_display() -> void:
	# Given：调试场景已启动，玩家手牌中有防御。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_ensure_card_in_hand(scene, "防御")
	# When：点击手牌中的防御。
	_press_hand_card_button(scene, "防御")
	# Then：玩家获得 5 点格挡，消耗 1 点能量，手牌与弃牌堆刷新，并写入简洁日志。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：5")
	assert_eq(_label_text(scene, "Layout/Metrics/EnergyLabel"), "能量：2/3")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("防御"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 防御，获得 5 点格挡"))
```

Add tests for the three newly included cards:

```gdscript
func test_clicking_bash_applies_vulnerable_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有痛击且敌人没有易伤。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [BashScript.new()])
	scene._refresh_display()
	# When：点击手牌中的痛击。
	_press_hand_card_button(scene, "痛击")
	# Then：敌人受到 8 点伤害，并获得 2 层易伤。
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyHpLabel"), "敌人血量：12/20")
	assert_eq(_label_text(scene, "Layout/EnemyPanel/EnemyPowersLabel"), "敌人状态效果：易伤 2")


func test_clicking_inflame_applies_strength_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有燃烧且没有力量。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [InflameScript.new()])
	scene._refresh_display()
	# When：点击手牌中的燃烧。
	_press_hand_card_button(scene, "燃烧")
	# Then：玩家获得 2 点力量，燃烧进入弃牌堆。
	assert_eq(_label_text(scene, "Layout/Metrics/PlayerPowersLabel"), "玩家状态效果：力量 2")
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("燃烧"))


func test_clicking_shrug_it_off_gains_block_and_draws_from_hand() -> void:
	# Given：调试场景中，玩家手牌里有耸肩无视，抽牌堆顶有打击。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	_replace_hand(scene, [ShrugItOffScript.new()])
	scene.game_state.player.card_manager.draw_pile = [StrikeScript.new()]
	scene._refresh_display()
	# When：点击手牌中的耸肩无视。
	_press_hand_card_button(scene, "耸肩无视")
	# Then：玩家获得 8 点格挡，并抽到打击。
	assert_eq(_label_text(scene, "Layout/Metrics/BlockLabel"), "格挡：8")
	assert_true(_label_text(scene, "Layout/PilesPanel/HandLabel").contains("打击"))
	assert_true(_label_text(scene, "Layout/PilesPanel/DiscardPileLabel").contains("耸肩无视"))
```

Add these helpers near other test helpers:

```gdscript
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
	assert_fail("未找到测试需要的手牌：" + card_name)
```

- [ ] **Step 3: Run tests to verify RED**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL because `HandButtons` does not exist, fixed buttons still exist, and clicking hand cards is not implemented.

- [ ] **Step 4: Add hand button state to the debug scene**

In `scripts/stm/debug/battle_debug_scene.gd`, replace fixed button variables:

```gdscript
var hand_buttons_container: GridContainer
var end_turn_button: Button
var reset_button: Button
```

Remove these variables:

```gdscript
var strike_button: Button
var defend_button: Button
```

- [ ] **Step 5: Build dynamic hand button container**

In `_build_ui()`, after `hand_label` is added to `piles_panel`, add:

```gdscript
	hand_buttons_container = GridContainer.new()
	hand_buttons_container.name = "HandButtons"
	hand_buttons_container.columns = 4
	hand_buttons_container.add_theme_constant_override("h_separation", 8)
	hand_buttons_container.add_theme_constant_override("v_separation", 8)
	piles_panel.add_child(hand_buttons_container)
```

Remove the fixed `StrikeButton` and `DefendButton` creation block. Keep only:

```gdscript
	end_turn_button = _new_button("EndTurnButton", "结束回合")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	buttons.add_child(end_turn_button)

	reset_button = _new_button("ResetButton", "重开战斗")
	reset_button.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset_button)
```

- [ ] **Step 6: Add hand button refresh helpers**

Add these methods near `_refresh_display()`:

```gdscript
func _refresh_hand_buttons(player) -> void:
	if hand_buttons_container == null:
		return
	for child in hand_buttons_container.get_children():
		hand_buttons_container.remove_child(child)
		child.free()
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
```

In `_show_no_combat_display()`, clear the container:

```gdscript
	if hand_buttons_container != null:
		for child in hand_buttons_container.get_children():
			hand_buttons_container.remove_child(child)
			child.free()
```

In `_refresh_display()`, call the helper after pile labels:

```gdscript
	hand_label.text = _pile_text("手牌", "hand")
	draw_pile_label.text = _pile_text("抽牌堆", "draw_pile")
	discard_pile_label.text = _pile_text("弃牌堆", "discard_pile")
	_refresh_hand_buttons(player)
```

Remove:

```gdscript
	strike_button.disabled = _find_card_by_name("打击") == null or _first_alive_enemy() == null
	defend_button.disabled = _find_card_by_name("防御") == null
```

- [ ] **Step 7: Replace fixed-name play flow with card-reference play flow**

Remove `_on_strike_pressed()`, `_on_defend_pressed()`, and `_play_first_card_named()`.

Add:

```gdscript
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
	_refresh_display()
```

- [ ] **Step 8: Make card logging generic and Chinese**

Change `_append_card_log` signature and body:

```gdscript
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
			"打出 %s：能量 %d -> %d；敌人 HP %d -> %d；%s 进入弃牌堆；结局检查=%d。"
				% [card_name, energy_before, energy_after, before_enemy_hp, after_enemy_hp, card_name, result]
		)
	elif block_gain > 0:
		_append_log(
			"打出 %s，获得 %d 点格挡" % [card_name, block_gain],
			"打出 %s：能量 %d -> %d；格挡 %d -> %d；%s 进入弃牌堆；结局检查=%d。"
				% [card_name, energy_before, energy_after, int(before_player["block"]), int(after_player["block"]), card_name, result]
		)
	else:
		_append_log(
			"打出 %s" % card_name,
			"打出 %s：能量 %d -> %d；结局检查=%d。"
				% [card_name, energy_before, energy_after, result]
		)
```

- [ ] **Step 9: Update remaining battle debug tests**

In `scripts/stm/tests/test_battle_debug_scene.gd`:

- Replace fixed button disable assertions in fixture-failure tests with:

```gdscript
	assert_eq(_hand_card_button_count(scene), 0)
```

- Replace end-turn re-enable assertions with:

```gdscript
	assert_true(_hand_card_button_count(scene) > 0)
```

- Replace detailed log tests to click hand card:

```gdscript
_ensure_card_in_hand(scene, "打击")
_press_hand_card_button(scene, "打击")
assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("打出 打击，敌人受到 6 点伤害"))
```

- Replace reset test fixed button click with:

```gdscript
_ensure_card_in_hand(scene, "打击")
_press_hand_card_button(scene, "打击")
```

- [ ] **Step 10: Run full GUT for Task 2**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS for every test path listed in `.gutconfig.json`.

- [ ] **Step 11: Commit Tasks 1-2 together**

```powershell
git add scripts/stm/cards/test/strike.gd scripts/stm/cards/test/defend.gd scripts/stm/cards/test/bash.gd scripts/stm/cards/test/inflame.gd scripts/stm/cards/test/shrug_it_off.gd scripts/stm/cards/test/bash.gd.uid scripts/stm/cards/test/inflame.gd.uid scripts/stm/cards/test/shrug_it_off.gd.uid scripts/stm/debug/fixtures/fixed_battle_fixture.gd scripts/stm/debug/battle_debug_scene.gd scripts/stm/tests/core_skeleton_test.gd scripts/stm/tests/test_fixed_battle_fixture.gd scripts/stm/tests/test_powers_v1.gd scripts/stm/tests/test_battle_debug_scene.gd
git commit -m "feat(debug): play localized cards from hand"
```

---

## Task 3: 最终安全自检与验证

**Files:**
- Review: all modified files from Tasks 1-2

- [ ] **Step 1: Run full GUT suite**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS for all tests. Godot may still print existing resource-leak warnings at process exit; treat the GUT exit code and summary as the pass/fail source.

- [ ] **Step 2: Scan for ambiguous placeholders**

```powershell
rg -n "TB[D]|TO[D]O|implement\s+later|fill\s+in\s+details|Add\s+appropriate\s+error\s+handling|Write\s+tests\s+for\s+the\s+above|Similar\s+to\s+Task" scripts/stm docs/superpowers/specs/2026-05-25-click-hand-cards-debug-design.md docs/superpowers/plans/2026-05-25-click-hand-cards-debug.md
```

Expected: no matches.

- [ ] **Step 3: Check patch hygiene**

```powershell
git diff --check
git status --short --branch
```

Expected: `git diff --check` prints nothing. `git status --short --branch` shows only intended committed history or a clean worktree.

- [ ] **Step 4: Safety, boundary, dependency checklist**

Verify these statements against the diff:

- `slay-the-model-main/` has no changes.
- No new addon, plugin, network dependency, or resource editor dependency was added.
- Test cards still live under `scripts/stm/cards/test/`.
- Debug scene calls `combat.play_card(game_state, card, targets)` and does not duplicate card action resolution.
- Every hand-card button checks current hand membership before play.
- Enemy-target cards fail safely when no living enemy exists.
- Energy-insufficient cards are disabled and also guarded in `_play_card_from_hand()`.
- `.gd.uid` files for the three newly tracked test card scripts are committed.

- [ ] **Step 5: Commit final verification edits only when files changed**

If Step 4 produces code, test, or documentation edits, commit them:

```powershell
git add scripts/stm docs/superpowers/specs/2026-05-25-click-hand-cards-debug-design.md docs/superpowers/plans/2026-05-25-click-hand-cards-debug.md
git commit -m "chore(debug): verify hand card debug flow"
```

If Step 4 is inspection-only and the worktree is clean, record “无需额外提交” in the final handoff.

---

## Self-Review

**Spec coverage**
- 中文测试卡名：Task 1。
- 固定调试牌组加入三张新卡：Task 1。
- 点击当前手牌出牌：Task 2。
- 移除固定 `Strike` / `Defend` 出牌按钮：Task 2。
- 敌人目标默认选择第一个存活敌人：Task 2。
- 安全、边界、依赖检查：Task 3。

**Placeholder scan**
- 本计划每个实现步骤均给出具体文件、代码片段和验证命令。

**Type consistency**
- 手目录径统一为 `Layout/PilesPanel/HandButtons`，测试 helper 通过既有 `_relocated_debug_path()` 支持真实路径 `Layout/Body/MainPanel/PilesPanel/HandButtons`。
- 出牌入口统一为 `_play_card_from_hand(card)`。
- 按钮可用性统一由 `_can_play_card_from_hand(card)` 判断。
- 牌名显示统一走 `_card_display_name(card)`。
