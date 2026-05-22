# Godot GDScript 核心骨架 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Godot 项目中搭建 `scripts/stm/` GDScript 规则骨架，保留 Python 参考项目的核心职责边界，并用 GUT/BDD 测试验证最小战斗切片。

**Architecture:** 规则层使用 `RefCounted` 类组织，`engine/` 编排流程，`actions/` 执行状态变更，`entities/` 保存共享生物状态，`player/` 管理玩家与牌堆，`cards/` 和 `enemies/` 只放内容行为。第一阶段只实现 Strike、Defend 和 DummyEnemy，`slay-the-model-main/` 始终只读。

**Tech Stack:** Godot 4.6.2、GDScript、GUT 测试入口 `godot -s addons/gut/gut_cmdln.gd`、PowerShell、Git。

---

## 文件结构

- Create: `scripts/stm/utils/types.gd`：规则层枚举常量。
- Create: `scripts/stm/utils/option.gd`：可选项数据对象。
- Create: `scripts/stm/actions/action.gd`：行为基类。
- Create: `scripts/stm/actions/action_queue.gd`：行为队列。
- Create: `scripts/stm/actions/combat_actions.gd`：最小战斗行为集合。
- Create: `scripts/stm/entities/creature.gd`：共享生物状态。
- Create: `scripts/stm/cards/card.gd`：卡牌基类。
- Create: `scripts/stm/cards/test/strike.gd`：测试 Strike。
- Create: `scripts/stm/cards/test/defend.gd`：测试 Defend。
- Create: `scripts/stm/player/card_manager.gd`：牌堆管理器。
- Create: `scripts/stm/player/player.gd`：玩家对象。
- Create: `scripts/stm/enemies/enemy.gd`：敌人基类。
- Create: `scripts/stm/enemies/test/dummy_enemy.gd`：测试敌人。
- Create: `scripts/stm/engine/combat_state.gd`：战斗状态。
- Create: `scripts/stm/engine/game_state.gd`：全局状态。
- Create: `scripts/stm/engine/combat.gd`：战斗流程。
- Create: `scripts/stm/engine/game_bootstrap.gd`：测试启动器。
- Create: `scripts/stm/tests/core_skeleton_test.gd`：GUT/BDD 单元测试。

## 执行约束

- 先创建测试方法名和 Given-When-Then 中文行为注释，再写测试断言，再写正式代码。
- 所有新增代码注释使用中文。
- 不修改 `slay-the-model-main/`。
- 不联网安装依赖。
- 如果 `addons/gut/gut_cmdln.gd` 不存在，记录为测试环境阻塞。

### Task 1: 创建 BDD 测试骨架

**Files:**
- Create: `scripts/stm/tests/core_skeleton_test.gd`

- [ ] **Step 1: 创建测试目录**

Run:

```powershell
New-Item -ItemType Directory -Force scripts\stm\tests
```

Expected: 目录 `scripts\stm\tests` 存在。

- [ ] **Step 2: 写入测试方法名和 Given-When-Then 注释**

Create `scripts/stm/tests/core_skeleton_test.gd`:

```gdscript
extends GutTest

func test_reset_for_combat_moves_deck_copies_to_draw_pile() -> void:
	# Given：一个带有测试起始牌组的游戏状态。
	# When：重置玩家牌堆进入战斗。
	# Then：卡组保留原始牌，抽牌堆获得战斗副本，手牌和弃牌堆为空。
	pass

func test_draw_many_moves_cards_from_draw_pile_to_hand() -> void:
	# Given：一个已经重置到战斗状态的牌堆管理器。
	# When：抽取两张牌。
	# Then：两张牌从抽牌堆进入手牌。
	pass

func test_strike_spends_energy_damages_enemy_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Strike。
	# When：玩家对 DummyEnemy 打出 Strike。
	# Then：玩家消耗 1 点能量，敌人受到 6 点伤害，Strike 进入弃牌堆。
	pass

func test_defend_spends_energy_grants_block_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Defend。
	# When：玩家打出 Defend。
	# Then：玩家消耗 1 点能量，获得 5 点格挡，Defend 进入弃牌堆。
	pass

func test_end_turn_discards_hand_and_enemy_damage_uses_block() -> void:
	# Given：玩家已打出 Defend 并保留 5 点格挡，手牌中还有其他牌。
	# When：玩家结束回合，DummyEnemy 执行 6 点攻击。
	# Then：剩余手牌进入弃牌堆，格挡抵消 5 点伤害，玩家只损失 1 点 HP。
	pass

func test_combat_reports_win_when_all_enemies_reach_zero_hp() -> void:
	# Given：DummyEnemy 只剩 6 点 HP，玩家手牌中有 Strike。
	# When：玩家对 DummyEnemy 打出 Strike。
	# Then：战斗返回胜利结果。
	pass
```

- [ ] **Step 3: 运行测试骨架**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: 如果 GUT 已安装，测试文件被发现且这些空测试通过；如果 `addons/gut/gut_cmdln.gd` 不存在，命令失败并报告测试环境阻塞。

- [ ] **Step 4: 提交测试骨架**

```powershell
git add scripts\stm\tests\core_skeleton_test.gd
git commit -m "test: add core skeleton bdd scenarios"
```

### Task 2: 将 BDD 骨架补成失败测试

**Files:**
- Modify: `scripts/stm/tests/core_skeleton_test.gd`
- Create later in implementation tasks: all `scripts/stm/**/*.gd` files referenced by the test

- [ ] **Step 1: 写入完整失败测试**

Replace `scripts/stm/tests/core_skeleton_test.gd` with:

```gdscript
extends GutTest

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

func _find_card_by_name(cards: Array, card_name: String):
	for card in cards:
		if card.card_name == card_name:
			return card
	return null

func test_reset_for_combat_moves_deck_copies_to_draw_pile() -> void:
	# Given：一个带有测试起始牌组的游戏状态。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var card_manager = game_state.player.card_manager
	# When：重置玩家牌堆进入战斗。
	card_manager.reset_for_combat()
	# Then：卡组保留原始牌，抽牌堆获得战斗副本，手牌和弃牌堆为空。
	assert_eq(card_manager.get_pile("deck").size(), 4)
	assert_eq(card_manager.get_pile("draw_pile").size(), 4)
	assert_eq(card_manager.get_pile("hand").size(), 0)
	assert_eq(card_manager.get_pile("discard_pile").size(), 0)
	assert_ne(card_manager.get_pile("deck")[0], card_manager.get_pile("draw_pile")[0])

func test_draw_many_moves_cards_from_draw_pile_to_hand() -> void:
	# Given：一个已经重置到战斗状态的牌堆管理器。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var card_manager = game_state.player.card_manager
	card_manager.reset_for_combat()
	# When：抽取两张牌。
	var drawn = card_manager.draw_many(2)
	# Then：两张牌从抽牌堆进入手牌。
	assert_eq(drawn.size(), 2)
	assert_eq(card_manager.get_pile("hand").size(), 2)
	assert_eq(card_manager.get_pile("draw_pile").size(), 2)

func test_strike_spends_energy_damages_enemy_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Strike。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Strike")
	var starting_energy = game_state.player.energy
	# When：玩家对 DummyEnemy 打出 Strike。
	var result = combat.play_card(game_state, strike, [enemy])
	# Then：玩家消耗 1 点能量，敌人受到 6 点伤害，Strike 进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(enemy.hp, enemy.max_hp - 6)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(strike))

func test_defend_spends_energy_grants_block_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Defend。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Defend")
	var starting_energy = game_state.player.energy
	# When：玩家打出 Defend。
	var result = combat.play_card(game_state, defend, [])
	# Then：玩家消耗 1 点能量，获得 5 点格挡，Defend 进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(game_state.player.block, 5)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(defend))

func test_end_turn_discards_hand_and_enemy_damage_uses_block() -> void:
	# Given：玩家已打出 Defend 并保留 5 点格挡，手牌中还有其他牌。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Defend")
	combat.play_card(game_state, defend, [])
	var starting_hp = game_state.player.hp
	# When：玩家结束回合，DummyEnemy 执行 6 点攻击。
	var result = combat.end_turn(game_state)
	# Then：剩余手牌进入弃牌堆，格挡抵消 5 点伤害，玩家只损失 1 点 HP。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.card_manager.get_pile("hand").size(), 0)
	assert_eq(game_state.player.hp, starting_hp - 1)
	assert_eq(game_state.player.block, 0)
	assert_eq(combat.combat_state.current_phase, "player_start")

func test_combat_reports_win_when_all_enemies_reach_zero_hp() -> void:
	# Given：DummyEnemy 只剩 6 点 HP，玩家手牌中有 Strike。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	enemy.hp = 6
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Strike")
	# When：玩家对 DummyEnemy 打出 Strike。
	var result = combat.play_card(game_state, strike, [enemy])
	# Then：战斗返回胜利结果。
	assert_eq(result, TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(enemy.is_dead())
```

- [ ] **Step 2: 运行失败测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: FAIL。若 GUT 已安装，失败信息应包含缺失脚本路径，例如 `res://scripts/stm/engine/game_bootstrap.gd`。若 GUT 不存在，报告测试环境阻塞。

- [ ] **Step 3: 提交失败测试**

```powershell
git add scripts\stm\tests\core_skeleton_test.gd
git commit -m "test: cover gdscript core skeleton behavior"
```

### Task 3: 实现工具类型和行为队列基础

**Files:**
- Create: `scripts/stm/utils/types.gd`
- Create: `scripts/stm/utils/option.gd`
- Create: `scripts/stm/actions/action.gd`
- Create: `scripts/stm/actions/action_queue.gd`

- [ ] **Step 1: 创建目录**

Run:

```powershell
New-Item -ItemType Directory -Force scripts\stm\utils, scripts\stm\actions
```

Expected: 目录存在。

- [ ] **Step 2: 写入 `scripts/stm/utils/types.gd`**

```gdscript
class_name StmTypes
extends RefCounted

enum TargetType {
	SELF,
	ENEMY_SELECT,
	ENEMY_RANDOM,
	ENEMY_LOWEST_HP,
	ENEMY_ALL,
}

enum PilePosType {
	TOP,
	BOTTOM,
	RANDOM,
}

enum CardType {
	ATTACK,
	SKILL,
	POWER,
	CURSE,
	STATUS,
}

enum RarityType {
	STARTER,
	COMMON,
	UNCOMMON,
	RARE,
	SPECIAL,
	BOSS,
	SHOP,
	EVENT,
	CURSE,
}

enum CombatType {
	NORMAL,
	ELITE,
	BOSS,
}

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS,
	MINION,
}

enum TerminalResult {
	NONE,
	COMBAT_WIN,
	GAME_LOSE,
	COMBAT_ESCAPE,
}
```

- [ ] **Step 3: 写入 `scripts/stm/utils/option.gd`**

```gdscript
class_name StmOption
extends RefCounted

var name: String = ""
var actions: Array = []

func _init(option_name: String = "", option_actions: Array = []) -> void:
	name = option_name
	actions = option_actions.duplicate()
```

- [ ] **Step 4: 写入 `scripts/stm/actions/action.gd`**

```gdscript
class_name StmAction
extends RefCounted

func execute(_game_state) -> int:
	push_error("行为未实现 execute(): %s" % [get_script().resource_path])
	return StmTypes.TerminalResult.NONE
```

- [ ] **Step 5: 写入 `scripts/stm/actions/action_queue.gd`**

```gdscript
class_name StmActionQueue
extends RefCounted

var queue: Array = []

func add_action(action: StmAction, to_front: bool = false) -> void:
	if action == null:
		return
	if to_front:
		queue.push_front(action)
	else:
		queue.append(action)

func add_actions(actions: Array, to_front: bool = false) -> void:
	if actions.is_empty():
		return
	if to_front:
		for index in range(actions.size() - 1, -1, -1):
			add_action(actions[index], true)
	else:
		for action in actions:
			add_action(action)

func execute_next(game_state) -> int:
	if queue.is_empty():
		return StmTypes.TerminalResult.NONE
	var action: StmAction = queue.pop_front()
	return action.execute(game_state)

func execute_all(game_state) -> int:
	while not queue.is_empty():
		var result = execute_next(game_state)
		if result != StmTypes.TerminalResult.NONE:
			return result
	return StmTypes.TerminalResult.NONE

func is_empty() -> bool:
	return queue.is_empty()

func clear() -> void:
	queue.clear()
```

- [ ] **Step 6: 运行测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: FAIL。失败仍来自缺失 `GameBootstrap` 或核心战斗类。

- [ ] **Step 7: 提交基础类型和队列**

```powershell
git add scripts\stm\utils\types.gd scripts\stm\utils\option.gd scripts\stm\actions\action.gd scripts\stm\actions\action_queue.gd
git commit -m "feat: add stm utility types and action queue"
```

### Task 4: 实现生物、卡牌和牌堆管理

**Files:**
- Create: `scripts/stm/entities/creature.gd`
- Create: `scripts/stm/cards/card.gd`
- Create: `scripts/stm/player/card_manager.gd`

- [ ] **Step 1: 创建目录**

Run:

```powershell
New-Item -ItemType Directory -Force scripts\stm\entities, scripts\stm\cards, scripts\stm\player
```

Expected: 目录存在。

- [ ] **Step 2: 写入 `scripts/stm/entities/creature.gd`**

```gdscript
class_name StmCreature
extends RefCounted

var _max_hp: int = 1
var _hp: int = 1
var _block: int = 0
var powers: Array = []

var max_hp: int:
	get:
		return _max_hp
	set(value):
		var previous_max = _max_hp
		_max_hp = max(1, int(value))
		_hp = max(0, min(_max_hp, _hp + (_max_hp - previous_max)))

var hp: int:
	get:
		return _hp
	set(value):
		_hp = max(0, min(_max_hp, int(value)))

var block: int:
	get:
		return _block
	set(value):
		_block = max(0, int(value))

func _init(initial_max_hp: int = 1) -> void:
	_max_hp = max(1, initial_max_hp)
	_hp = _max_hp
	_block = 0

func is_dead() -> bool:
	return _hp <= 0

func take_damage(amount: int, _source = null, _card = null) -> int:
	if amount <= 0:
		return 0
	var absorbed = min(_block, amount)
	block = _block - absorbed
	var remaining = amount - absorbed
	if remaining > 0:
		hp = _hp - remaining
	return remaining

func heal(amount: int) -> int:
	if amount <= 0:
		return _hp
	hp = _hp + amount
	return _hp

func gain_block(amount: int) -> void:
	if amount <= 0:
		return
	block = _block + amount
```

- [ ] **Step 3: 写入 `scripts/stm/cards/card.gd`**

```gdscript
class_name StmCard
extends RefCounted

var card_name: String = "Card"
var card_type: int = StmTypes.CardType.ATTACK
var rarity: int = StmTypes.RarityType.COMMON
var target_type: int = StmTypes.TargetType.ENEMY_SELECT

var base_cost: int = 0
var base_damage: int = 0
var base_block: int = 0
var base_exhaust: bool = false

var upgrade_cost: int = -999
var upgrade_damage: int = -999
var upgrade_block: int = -999

var cost: int = 0
var damage: int = 0
var block: int = 0
var exhaust: bool = false
var upgrade_level: int = 0

func reset_values() -> void:
	cost = base_cost
	damage = base_damage
	block = base_block
	exhaust = base_exhaust

func can_play(game_state) -> bool:
	if game_state == null or game_state.current_combat == null:
		push_error("没有当前战斗，不能打出卡牌：%s" % card_name)
		return false
	if not game_state.player.card_manager.get_pile("hand").has(self):
		push_error("卡牌不在手牌中：%s" % card_name)
		return false
	if game_state.player.energy < cost:
		return false
	return true

func on_play(_game_state, targets: Array = []) -> Array:
	var actions: Array = []
	if block > 0:
		actions.append(StmCombatActions.GainBlockAction.new(block))
	if damage > 0:
		for target in targets:
			actions.append(StmCombatActions.AttackAction.new(target, damage, self))
	return actions

func upgrade() -> bool:
	if upgrade_level > 0:
		return false
	upgrade_level += 1
	if upgrade_cost != -999:
		cost = upgrade_cost
	if upgrade_damage != -999:
		damage = upgrade_damage
	if upgrade_block != -999:
		block = upgrade_block
	return true

func copy() -> StmCard:
	var script = get_script()
	var copied_card: StmCard = script.new()
	if upgrade_level > 0:
		copied_card.upgrade()
	return copied_card
```

- [ ] **Step 4: 写入 `scripts/stm/player/card_manager.gd`**

```gdscript
class_name StmCardManager
extends RefCounted

const HAND_LIMIT := 10

var piles := {
	"deck": [],
	"draw_pile": [],
	"discard_pile": [],
	"hand": [],
	"exhaust_pile": [],
}

func _init(deck: Array = []) -> void:
	piles["deck"] = deck.duplicate()

func reset_for_combat() -> void:
	piles["draw_pile"] = []
	for card in piles["deck"]:
		piles["draw_pile"].append(card.copy())
	piles["discard_pile"] = []
	piles["hand"] = []
	piles["exhaust_pile"] = []

func get_pile(pile_name: String) -> Array:
	if not piles.has(pile_name):
		push_error("无效牌堆名称：%s" % pile_name)
		return []
	return piles[pile_name]

func add_to_pile(card: StmCard, pile_name: String, pos: int = StmTypes.PilePosType.TOP) -> bool:
	if not piles.has(pile_name):
		push_error("无效牌堆名称：%s" % pile_name)
		return false
	var target_pile: Array = piles[pile_name]
	if pile_name == "hand" and target_pile.size() >= HAND_LIMIT:
		return add_to_pile(card, "discard_pile", StmTypes.PilePosType.TOP)
	match pos:
		StmTypes.PilePosType.BOTTOM:
			target_pile.push_front(card)
		StmTypes.PilePosType.RANDOM:
			var index = randi_range(0, target_pile.size())
			target_pile.insert(index, card)
		_:
			target_pile.append(card)
	return true

func get_card_location(card: StmCard) -> String:
	for pile_name in piles.keys():
		if piles[pile_name].has(card):
			return pile_name
	return ""

func remove_from_pile(card: StmCard, pile_name: String) -> bool:
	if not piles.has(pile_name):
		push_error("无效牌堆名称：%s" % pile_name)
		return false
	var pile: Array = piles[pile_name]
	if not pile.has(card):
		return false
	pile.erase(card)
	return true

func move_to(card: StmCard, destination: String, source: String = "", pos: int = StmTypes.PilePosType.TOP) -> bool:
	if not piles.has(destination):
		push_error("无效目标牌堆：%s" % destination)
		return false
	var actual_source = source
	if actual_source == "":
		actual_source = get_card_location(card)
	if actual_source == "":
		push_error("卡牌不在任何牌堆中：%s" % card.card_name)
		return false
	if not remove_from_pile(card, actual_source):
		return false
	return add_to_pile(card, destination, pos)

func shuffle_discard_to_draw() -> bool:
	if piles["discard_pile"].is_empty():
		return false
	for card in piles["discard_pile"]:
		piles["draw_pile"].append(card)
	piles["discard_pile"] = []
	piles["draw_pile"].shuffle()
	return true

func draw_one() -> StmCard:
	if piles["hand"].size() >= HAND_LIMIT:
		return null
	if piles["draw_pile"].is_empty() and not shuffle_discard_to_draw():
		return null
	var card: StmCard = piles["draw_pile"].pop_back()
	add_to_pile(card, "hand")
	return card

func draw_many(amount: int) -> Array:
	var drawn: Array = []
	for _index in range(amount):
		var card = draw_one()
		if card == null:
			break
		drawn.append(card)
	return drawn

func discard(card: StmCard, source: String = "") -> bool:
	return move_to(card, "discard_pile", source)

func exhaust_card(card: StmCard, source: String = "") -> bool:
	return move_to(card, "exhaust_pile", source)
```

- [ ] **Step 5: 运行测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: FAIL。失败应来自缺失玩家、敌人、战斗启动或战斗行为类。

- [ ] **Step 6: 提交生物、卡牌和牌堆管理**

```powershell
git add scripts\stm\entities\creature.gd scripts\stm\cards\card.gd scripts\stm\player\card_manager.gd
git commit -m "feat: add stm creature card and pile core"
```

### Task 5: 实现玩家、敌人和测试内容

**Files:**
- Create: `scripts/stm/player/player.gd`
- Create: `scripts/stm/enemies/enemy.gd`
- Create: `scripts/stm/cards/test/strike.gd`
- Create: `scripts/stm/cards/test/defend.gd`
- Create: `scripts/stm/enemies/test/dummy_enemy.gd`

- [ ] **Step 1: 创建内容目录**

Run:

```powershell
New-Item -ItemType Directory -Force scripts\stm\cards\test, scripts\stm\enemies, scripts\stm\enemies\test
```

Expected: 目录存在。

- [ ] **Step 2: 写入 `scripts/stm/player/player.gd`**

```gdscript
class_name StmPlayer
extends StmCreature

var card_manager: StmCardManager
var max_energy: int = 3
var energy: int = 3
var base_draw_count: int = 5
var gold: int = 99
var relics: Array = []
var potions: Array = []

var draw_count: int:
	get:
		return base_draw_count

func _init(deck: Array = []) -> void:
	super(70)
	card_manager = StmCardManager.new(deck)
	energy = max_energy

func gain_energy(amount: int) -> int:
	energy = max(0, energy + amount)
	return energy
```

- [ ] **Step 3: 写入 `scripts/stm/enemies/enemy.gd`**

```gdscript
class_name StmEnemy
extends StmCreature

var enemy_name: String = "Enemy"
var enemy_type: int = StmTypes.EnemyType.NORMAL
var current_intention: String = ""
var intent_damage: int = 0

func _init(initial_max_hp: int = 1, initial_name: String = "Enemy", initial_damage: int = 0) -> void:
	super(initial_max_hp)
	enemy_name = initial_name
	intent_damage = initial_damage

func determine_next_intention() -> String:
	current_intention = "attack"
	return current_intention

func execute_intention(_game_state, _combat) -> Array:
	return []
```

- [ ] **Step 4: 写入 `scripts/stm/cards/test/strike.gd`**

```gdscript
class_name StmStrike
extends StmCard

func _init() -> void:
	card_name = "Strike"
	card_type = StmTypes.CardType.ATTACK
	rarity = StmTypes.RarityType.STARTER
	target_type = StmTypes.TargetType.ENEMY_SELECT
	base_cost = 1
	base_damage = 6
	upgrade_damage = 9
	reset_values()
```

- [ ] **Step 5: 写入 `scripts/stm/cards/test/defend.gd`**

```gdscript
class_name StmDefend
extends StmCard

func _init() -> void:
	card_name = "Defend"
	card_type = StmTypes.CardType.SKILL
	rarity = StmTypes.RarityType.STARTER
	target_type = StmTypes.TargetType.SELF
	base_cost = 1
	base_block = 5
	upgrade_block = 8
	reset_values()
```

- [ ] **Step 6: 写入 `scripts/stm/enemies/test/dummy_enemy.gd`**

```gdscript
class_name StmDummyEnemy
extends StmEnemy

func _init() -> void:
	super(20, "DummyEnemy", 6)
	current_intention = "attack"

func execute_intention(_game_state, _combat) -> Array:
	return [StmCombatActions.EnemyAttackAction.new(self, intent_damage)]
```

- [ ] **Step 7: 运行测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: FAIL。失败应来自缺失战斗行为、全局状态或启动器。

- [ ] **Step 8: 提交玩家、敌人和测试内容**

```powershell
git add scripts\stm\player\player.gd scripts\stm\enemies\enemy.gd scripts\stm\cards\test\strike.gd scripts\stm\cards\test\defend.gd scripts\stm\enemies\test\dummy_enemy.gd
git commit -m "feat: add stm player enemy and test content"
```

### Task 6: 实现战斗行为、全局状态和战斗流程

**Files:**
- Create: `scripts/stm/actions/combat_actions.gd`
- Create: `scripts/stm/engine/combat_state.gd`
- Create: `scripts/stm/engine/game_state.gd`
- Create: `scripts/stm/engine/combat.gd`
- Create: `scripts/stm/engine/game_bootstrap.gd`

- [ ] **Step 1: 创建引擎目录**

Run:

```powershell
New-Item -ItemType Directory -Force scripts\stm\engine
```

Expected: 目录存在。

- [ ] **Step 2: 写入 `scripts/stm/actions/combat_actions.gd`**

```gdscript
class_name StmCombatActions
extends RefCounted

class AttackAction extends StmAction:
	var target
	var amount: int
	var card

	func _init(action_target, action_amount: int, action_card = null) -> void:
		target = action_target
		amount = action_amount
		card = action_card

	func execute(game_state) -> int:
		if target == null:
			push_error("攻击行为缺少目标")
			return StmTypes.TerminalResult.NONE
		target.take_damage(amount, game_state.player, card)
		return game_state.current_combat.check_combat_end(game_state)

class EnemyAttackAction extends StmAction:
	var source
	var amount: int

	func _init(action_source, action_amount: int) -> void:
		source = action_source
		amount = action_amount

	func execute(game_state) -> int:
		if game_state.player == null:
			push_error("敌人攻击行为缺少玩家")
			return StmTypes.TerminalResult.NONE
		game_state.player.take_damage(amount, source, null)
		return game_state.current_combat.check_combat_end(game_state)

class GainBlockAction extends StmAction:
	var amount: int

	func _init(action_amount: int) -> void:
		amount = action_amount

	func execute(game_state) -> int:
		game_state.player.gain_block(amount)
		return StmTypes.TerminalResult.NONE

class DrawCardsAction extends StmAction:
	var amount: int

	func _init(action_amount: int) -> void:
		amount = action_amount

	func execute(game_state) -> int:
		game_state.player.card_manager.draw_many(amount)
		return StmTypes.TerminalResult.NONE

class DiscardCardAction extends StmAction:
	var card
	var source: String

	func _init(action_card, action_source: String = "hand") -> void:
		card = action_card
		source = action_source

	func execute(game_state) -> int:
		game_state.player.card_manager.discard(card, source)
		return StmTypes.TerminalResult.NONE

class PlayCardAction extends StmAction:
	var card
	var targets: Array

	func _init(action_card, action_targets: Array = []) -> void:
		card = action_card
		targets = action_targets.duplicate()

	func execute(game_state) -> int:
		if card == null:
			push_error("打牌行为缺少卡牌")
			return StmTypes.TerminalResult.NONE
		if not card.can_play(game_state):
			return StmTypes.TerminalResult.NONE
		game_state.player.energy -= card.cost
		var generated_actions = card.on_play(game_state, targets)
		game_state.add_actions(generated_actions, true)
		if card.exhaust:
			game_state.player.card_manager.exhaust_card(card, "hand")
		else:
			game_state.player.card_manager.discard(card, "hand")
		return StmTypes.TerminalResult.NONE

class EndTurnAction extends StmAction:
	func execute(game_state) -> int:
		if game_state.current_combat == null:
			return StmTypes.TerminalResult.NONE
		game_state.current_combat.combat_state.current_phase = "player_end"
		return StmTypes.TerminalResult.NONE
```

- [ ] **Step 3: 写入 `scripts/stm/engine/combat_state.gd`**

```gdscript
class_name StmCombatState
extends RefCounted

var combat_turn: int = 0
var turn_cards_played: int = 0
var player_energy_spent_this_turn: int = 0
var current_phase: String = "player_start"

func reset_combat_info() -> void:
	combat_turn = 0
	turn_cards_played = 0
	player_energy_spent_this_turn = 0
	current_phase = "player_start"

func reset_turn_info() -> void:
	turn_cards_played = 0
	player_energy_spent_this_turn = 0
```

- [ ] **Step 4: 写入 `scripts/stm/engine/game_state.gd`**

```gdscript
class_name StmGameState
extends RefCounted

var current_act: int = 1
var floor_in_act: int = 0
var player: StmPlayer
var current_combat
var action_queue: StmActionQueue = StmActionQueue.new()

var current_floor: int:
	get:
		return floor_in_act

func _init(initial_player: StmPlayer = null) -> void:
	player = initial_player

func add_action(action: StmAction, to_front: bool = false) -> void:
	action_queue.add_action(action, to_front)

func add_actions(actions: Array, to_front: bool = false) -> void:
	action_queue.add_actions(actions, to_front)

func drive_actions() -> int:
	return action_queue.execute_all(self)
```

- [ ] **Step 5: 写入 `scripts/stm/engine/combat.gd`**

```gdscript
class_name StmCombat
extends RefCounted

var enemies: Array = []
var combat_type: int = StmTypes.CombatType.NORMAL
var combat_state: StmCombatState = StmCombatState.new()

func _init(initial_enemies: Array = [], initial_combat_type: int = StmTypes.CombatType.NORMAL) -> void:
	enemies = initial_enemies.duplicate()
	combat_type = initial_combat_type

func start(game_state: StmGameState) -> int:
	game_state.current_combat = self
	combat_state.reset_combat_info()
	game_state.player.card_manager.reset_for_combat()
	return start_player_turn(game_state)

func start_player_turn(game_state: StmGameState) -> int:
	if check_combat_end(game_state) != StmTypes.TerminalResult.NONE:
		return check_combat_end(game_state)
	game_state.player.energy = game_state.player.max_energy
	combat_state.reset_turn_info()
	combat_state.combat_turn += 1
	combat_state.current_phase = "player_action"
	game_state.add_action(StmCombatActions.DrawCardsAction.new(game_state.player.draw_count))
	return game_state.drive_actions()

func play_card(game_state: StmGameState, card: StmCard, targets: Array = []) -> int:
	game_state.add_action(StmCombatActions.PlayCardAction.new(card, targets))
	var action_result = game_state.drive_actions()
	if action_result != StmTypes.TerminalResult.NONE:
		return action_result
	return check_combat_end(game_state)

func end_turn(game_state: StmGameState) -> int:
	game_state.add_action(StmCombatActions.EndTurnAction.new())
	var action_result = game_state.drive_actions()
	if action_result != StmTypes.TerminalResult.NONE:
		return action_result
	if combat_state.current_phase == "player_end":
		return execute_player_end(game_state)
	return StmTypes.TerminalResult.NONE

func execute_player_end(game_state: StmGameState) -> int:
	var hand = game_state.player.card_manager.get_pile("hand").duplicate()
	for card in hand:
		game_state.player.card_manager.discard(card, "hand")
	var enemy_result = execute_enemy_turn(game_state)
	if enemy_result != StmTypes.TerminalResult.NONE:
		return enemy_result
	combat_state.current_phase = "player_start"
	return StmTypes.TerminalResult.NONE

func execute_enemy_turn(game_state: StmGameState) -> int:
	for enemy in enemies:
		if enemy.is_dead():
			continue
		enemy.determine_next_intention()
		game_state.add_actions(enemy.execute_intention(game_state, self))
	var result = game_state.drive_actions()
	if result != StmTypes.TerminalResult.NONE:
		return result
	return check_combat_end(game_state)

func check_combat_end(game_state: StmGameState) -> int:
	enemies = enemies.filter(func(enemy): return not enemy.is_dead())
	if enemies.is_empty():
		return StmTypes.TerminalResult.COMBAT_WIN
	if game_state.player != null and game_state.player.is_dead():
		return StmTypes.TerminalResult.GAME_LOSE
	return StmTypes.TerminalResult.NONE
```

- [ ] **Step 6: 写入 `scripts/stm/engine/game_bootstrap.gd`**

```gdscript
class_name StmGameBootstrap
extends RefCounted

func create_test_game() -> StmGameState:
	var deck: Array = [
		StmStrike.new(),
		StmDefend.new(),
		StmStrike.new(),
		StmDefend.new(),
	]
	var player = StmPlayer.new(deck)
	return StmGameState.new(player)

func create_test_combat(_game_state: StmGameState) -> StmCombat:
	return StmCombat.new([StmDummyEnemy.new()], StmTypes.CombatType.NORMAL)
```

- [ ] **Step 7: 运行测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: PASS。若出现脚本解析错误，先修复 GDScript 类型或嵌套类语法，再重复运行同一命令。

- [ ] **Step 8: 提交战斗流程**

```powershell
git add scripts\stm\actions\combat_actions.gd scripts\stm\engine\combat_state.gd scripts\stm\engine\game_state.gd scripts\stm\engine\combat.gd scripts\stm\engine\game_bootstrap.gd
git commit -m "feat: add stm combat flow skeleton"
```

### Task 7: 最终验证和边界检查

**Files:**
- Verify: `AGENT.md`
- Verify: `docs/superpowers/specs/2026-05-22-godot-gdscript-core-skeleton-design.md`
- Verify: `scripts/stm/**/*.gd`
- Verify unchanged reference: `slay-the-model-main/`

- [ ] **Step 1: 确认没有修改参考实现**

Run:

```powershell
git status --short slay-the-model-main
```

Expected: 无输出。

- [ ] **Step 2: 检查新增代码中的英文注释**

Run:

```powershell
rg -n "^\s*#" scripts\stm
```

Expected: 输出只包含中文行为注释或中文说明注释；无英文说明注释。

- [ ] **Step 3: 运行全部单元测试**

Run:

```powershell
godot -s addons/gut/gut_cmdln.gd
```

Expected: PASS，覆盖 `scripts/stm/tests/core_skeleton_test.gd` 中所有测试。若 GUT 文件不存在，报告测试环境阻塞并停止实现收尾。

- [ ] **Step 4: 查看最终状态**

Run:

```powershell
git status --short
```

Expected: 没有未提交实现文件。

- [ ] **Step 5: 提交最终验证修复**

如果 Step 2 或 Step 3 需要修复，修复后提交：

```powershell
git add scripts\stm
git commit -m "test: verify stm core skeleton"
```

如果没有修复，跳过提交。

## 自检记录

- Spec 覆盖：计划覆盖 `scripts/stm/` 文件结构、ActionQueue 执行模型、Creature/Card/Player/Enemy/Combat/GameState 核心职责、Strike/Defend/DummyEnemy 最小内容、GUT/BDD 测试、安全边界、依赖和验收标准。
- 占位词扫描：已检查常见未完成标记，计划中没有用于推迟实现的占位描述。
- 类型一致性：统一使用 `StmTypes.TerminalResult.NONE`、`COMBAT_WIN`、`GAME_LOSE`、`COMBAT_ESCAPE`；统一使用 `card_name`、`current_combat`、`action_queue`、`draw_pile`、`discard_pile`、`exhaust_pile`。
