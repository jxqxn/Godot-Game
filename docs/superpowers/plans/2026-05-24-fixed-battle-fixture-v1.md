# 固定战斗内容夹具 v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把调试场景里写死的测试战斗内容抽到固定战斗夹具中，让策划调试工具从稳定、可复现的战斗样例启动。

**Architecture:** 新增 `StmFixedBattleFixture` 作为测试内容创建边界，负责创建玩家、测试牌组、DummyEnemy、GameState 和 debug Combat。`StmBattleDebugScene` 只读取 fixture 返回的上下文，不再直接拼装测试内容。现有战斗规则层不改动。

**Tech Stack:** Godot 4.6.2、GDScript、GUT、现有 `scripts/stm/` 战斗骨架。

---

## 执行约束

- 每个任务使用 fresh subagent。
- 实现代理使用 `gpt-5.3-codex`。
- 审核代理使用 `gpt-5.5`。
- 每个实现任务提交前必须完成双重审核：实现代理先用 `git diff` 自审，再派 fresh `gpt-5.5` 审核；阻塞问题必须修复并重跑 GUT。
- 每个任务先写中文 BDD 测试方法名和 Given-When-Then 注释，再写测试断言，再写正式代码。
- 所有新增注释使用中文。
- 不修复现有 UI 文本编码问题，本计划只移动固定战斗内容创建边界。
- 不修改 `slay-the-model-main/`。
- 不新增网络、Python、Node 或第三方 Godot 插件依赖。
- 单元测试命令使用：

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

## 文件结构

- Create: `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`
  - 单一职责：创建“基础测试战斗”的内容和战斗上下文。
  - 公开方法：`create_context() -> Dictionary`。
  - 公开常量：`FIXTURE_NAME := "基础测试战斗"`、`COMBAT_TYPE := "debug"`。

- Create: `scripts/stm/tests/test_fixed_battle_fixture.gd`
  - 测试 fixture 能创建命名 debug 战斗。
  - 测试 fixture 每次返回新实例。

- Modify: `scripts/stm/debug/battle_debug_scene.gd`
  - 用 `StmFixedBattleFixture` 替换场景内的手动牌组、玩家、敌人和 combat 创建逻辑。
  - 新增 `current_fixture_name` 记录当前样例名称。
  - 新增 fixture 失败保护，避免空对象进入 `combat.start(game_state)`。

- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`
  - 增加调试场景确实记录并使用固定战斗夹具的测试。
  - 保留现有调试场景行为测试。

---

### Task 1: 新增固定战斗夹具

**Files:**
- Create: `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`
- Create: `scripts/stm/tests/test_fixed_battle_fixture.gd`

- [ ] **Step 1: 先写 BDD 测试方法名和中文行为注释**

Create `scripts/stm/tests/test_fixed_battle_fixture.gd` with only the test method names and Given-When-Then comments:

```gdscript
extends GutTest


func test_fixed_battle_fixture_creates_named_debug_battle() -> void:
	# Given：策划需要一个固定测试战斗样例。
	# When：创建固定战斗夹具并请求战斗上下文。
	# Then：返回样例名称、游戏状态、战斗对象、玩家和 DummyEnemy。
	pass


func test_fixed_battle_fixture_creates_fresh_instances_each_time() -> void:
	# Given：策划多次重开同一个固定测试战斗。
	# When：连续两次创建 fixture 战斗上下文。
	# Then：两次返回的玩家、敌人、卡牌和战斗对象不是同一批实例。
	pass
```

- [ ] **Step 2: 补充失败测试断言**

Replace `scripts/stm/tests/test_fixed_battle_fixture.gd` with:

```gdscript
extends GutTest

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")


func test_fixed_battle_fixture_creates_named_debug_battle() -> void:
	# Given：策划需要一个固定测试战斗样例。
	var fixture = FixedBattleFixtureScript.new()
	# When：创建固定战斗夹具并请求战斗上下文。
	var context: Dictionary = fixture.create_context()
	# Then：返回样例名称、游戏状态、战斗对象、玩家和 DummyEnemy。
	assert_eq(context.get("name", ""), "基础测试战斗")
	assert_not_null(context.get("game_state"))
	assert_not_null(context.get("combat"))
	assert_not_null(context.get("player"))
	assert_not_null(context.get("enemy"))
	assert_true(context["game_state"].player == context["player"])
	assert_eq(context["combat"].enemies.size(), 1)
	assert_true(context["combat"].enemies[0] == context["enemy"])
	assert_eq(context["combat"].combat_type, "debug")
	assert_eq(context["player"].hp, 70)
	assert_eq(context["player"].max_hp, 70)
	assert_eq(context["player"].energy, 3)
	assert_eq(context["player"].max_energy, 3)
	assert_eq(context["enemy"].enemy_name, "DummyEnemy")
	assert_eq(context["enemy"].hp, 20)
	assert_eq(context["enemy"].max_hp, 20)
	var deck: Array = context["player"].card_manager.get_pile("deck")
	assert_eq(deck.size(), 4)
	assert_eq(deck[0].card_name, "Strike")
	assert_eq(deck[1].card_name, "Defend")
	assert_eq(deck[2].card_name, "Strike")
	assert_eq(deck[3].card_name, "Defend")


func test_fixed_battle_fixture_creates_fresh_instances_each_time() -> void:
	# Given：策划多次重开同一个固定测试战斗。
	var fixture = FixedBattleFixtureScript.new()
	# When：连续两次创建 fixture 战斗上下文。
	var first: Dictionary = fixture.create_context()
	var second: Dictionary = fixture.create_context()
	# Then：两次返回的玩家、敌人、卡牌和战斗对象不是同一批实例。
	assert_false(first["player"] == second["player"])
	assert_false(first["enemy"] == second["enemy"])
	assert_false(first["combat"] == second["combat"])
	assert_false(first["game_state"] == second["game_state"])
	var first_deck: Array = first["player"].card_manager.get_pile("deck")
	var second_deck: Array = second["player"].card_manager.get_pile("deck")
	assert_eq(first_deck.size(), 4)
	assert_eq(second_deck.size(), 4)
	assert_false(first_deck[0] == second_deck[0])
	assert_false(first_deck[1] == second_deck[1])
	assert_false(first_deck[2] == second_deck[2])
	assert_false(first_deck[3] == second_deck[3])
```

- [ ] **Step 3: 运行测试确认失败**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL before implementation. The expected failure is a missing `res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd` preload; if an empty file was created accidentally, the expected failure is missing `create_context()`.

- [ ] **Step 4: 实现最小固定战斗夹具**

Create `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`:

```gdscript
class_name StmFixedBattleFixture
extends RefCounted

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")

const FIXTURE_NAME := "基础测试战斗"
const COMBAT_TYPE := "debug"


func create_context() -> Dictionary:
	var deck: Array = create_deck()
	var player = PlayerScript.new(deck)
	var enemy = DummyEnemyScript.new()
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_game(player)
	if game_state == null:
		return {}
	var combat = bootstrap.create_combat(game_state, [enemy], COMBAT_TYPE)
	if combat == null:
		return {}
	return {
		"name": FIXTURE_NAME,
		"game_state": game_state,
		"combat": combat,
		"player": player,
		"enemy": enemy,
	}


func create_deck() -> Array:
	return [
		StrikeScript.new(),
		DefendScript.new(),
		StrikeScript.new(),
		DefendScript.new(),
	]
```

- [ ] **Step 5: 运行测试确认通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS. GUT summary shows `26/26` tests passing. Existing tests still pass, and total test count increased by 2.

- [ ] **Step 6: 审核并提交 Task 1**

Review:

```powershell
git diff -- scripts/stm/debug/fixtures/fixed_battle_fixture.gd scripts/stm/tests/test_fixed_battle_fixture.gd
git status --short
```

Then dispatch a fresh `gpt-5.5` review agent with this scope:

```text
请审查 Task 1：固定战斗夹具实现。重点检查：
1. 是否先写中文 BDD，再写测试断言，再写正式代码。
2. `create_context()` 是否返回 `name`、`game_state`、`combat`、`player`、`enemy`。
3. 每次调用是否创建新的玩家、敌人、卡牌、GameState 和 Combat 实例。
4. 是否没有新增正式内容库、配置文件、网络、Python、Node 或第三方插件依赖。
5. 是否存在空对象、半初始化或测试断言不足。
```

Expected: no blocking findings. If there are blocking findings, fix them BDD-first and rerun the full GUT command before committing.

Commit:

```powershell
git add scripts/stm/debug/fixtures/fixed_battle_fixture.gd scripts/stm/tests/test_fixed_battle_fixture.gd
git commit -m "feat(debug): add fixed battle fixture"
```

---

### Task 2: 调试场景改为从 fixture 启动

**Files:**
- Modify: `scripts/stm/debug/battle_debug_scene.gd`
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`

- [ ] **Step 1: 先写调试场景 BDD 测试方法名和中文行为注释**

Insert this method immediately after `test_debug_scene_shows_planner_tool_surface()` and before `test_apply_values_updates_combat_state_and_display()` in `scripts/stm/tests/test_battle_debug_scene.gd`:

```gdscript
func test_debug_scene_records_fixed_battle_fixture_name() -> void:
	# Given：策划打开依赖固定战斗夹具的调试场景。
	# When：场景完成初始化并创建测试战斗。
	# Then：场景记录基础测试战斗，并仍然连接 debug 战斗和 DummyEnemy。
	pass
```

- [ ] **Step 2: 补充失败测试断言**

Replace that new method with:

```gdscript
func test_debug_scene_records_fixed_battle_fixture_name() -> void:
	# Given：策划打开依赖固定战斗夹具的调试场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化并创建测试战斗。
	var fixture_name := str(scene.current_fixture_name)
	# Then：场景记录基础测试战斗，并仍然连接 debug 战斗和 DummyEnemy。
	assert_eq(fixture_name, "基础测试战斗")
	assert_not_null(scene.combat)
	assert_not_null(scene.enemy)
	assert_eq(scene.combat.combat_type, "debug")
	assert_eq(scene.enemy.enemy_name, "DummyEnemy")
```

- [ ] **Step 3: 运行测试确认失败**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL before scene implementation. The expected failure is missing `current_fixture_name` on `StmBattleDebugScene`.

- [ ] **Step 4: 修改调试场景常量和状态字段**

In `scripts/stm/debug/battle_debug_scene.gd`, replace the direct content preloads at the top:

```gdscript
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
```

with:

```gdscript
const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
```

Add this state field below `var enemy`:

```gdscript
var current_fixture_name: String = ""
```

- [ ] **Step 5: 替换 `start_debug_combat()`**

In `scripts/stm/debug/battle_debug_scene.gd`, replace the existing `start_debug_combat()` with:

```gdscript
func start_debug_combat() -> void:
	var fixture = FixedBattleFixtureScript.new()
	var context: Dictionary = fixture.create_context()
	if not _apply_fixture_context(context):
		_handle_fixture_failure()
		return
	status_message = "绛夊緟琛屽姩"
	combat.start(game_state)
	_reset_log()
	_append_log("鎴樻枟寮€濮?", "鎴樻枟寮€濮嬶細鐜╁鎶藉彇璧峰鎵嬬墝锛屾晫浜?DummyEnemy 鍑嗗鏀诲嚮銆?")
	_refresh_display()
```

- [ ] **Step 6: 新增 fixture 上下文应用和失败保护**

Add these helper methods below `start_debug_combat()`:

```gdscript
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
```

- [ ] **Step 7: 运行测试确认通过**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS. GUT summary shows `27/27` tests passing. Existing调试场景测试继续通过，新增场景测试通过。

- [ ] **Step 8: 审核并提交 Task 2**

Review:

```powershell
git diff -- scripts/stm/debug/battle_debug_scene.gd scripts/stm/tests/test_battle_debug_scene.gd
git status --short
```

Then dispatch a fresh `gpt-5.5` review agent with this scope:

```text
请审查 Task 2：调试场景从固定战斗夹具启动。重点检查：
1. 是否先写中文 BDD，再写测试断言，再写正式代码。
2. `battle_debug_scene.gd` 是否不再直接拼装 Strike、Defend、Player、DummyEnemy 和 GameBootstrap。
3. `current_fixture_name` 是否由 fixture 上下文赋值，并被测试覆盖。
4. fixture 创建失败时是否不会继续调用 `combat.start(game_state)`。
5. 重开战斗是否仍通过 `start_debug_combat()` 创建新上下文。
```

Expected: no blocking findings. If there are blocking findings, fix them BDD-first and rerun the full GUT command before committing.

Commit:

```powershell
git add scripts/stm/debug/battle_debug_scene.gd scripts/stm/tests/test_battle_debug_scene.gd
git commit -m "refactor(debug): start battle scene from fixture"
```

---

### Task 3: 最终验证和整理

**Files:**
- Verify: all modified files
- Verify: `docs/superpowers/specs/2026-05-24-fixed-battle-fixture-v1-design.md`

- [ ] **Step 1: 运行完整 GUT 测试**

Run:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS. GUT summary shows `27/27` tests passing. No failing tests, no script parse errors, no Godot crash dialog.

- [ ] **Step 2: 检查实现是否覆盖 spec**

Check these requirements manually:

- `scripts/stm/debug/battle_debug_scene.gd` no longer preloads `StrikeScript`、`DefendScript`、`PlayerScript`、`DummyEnemyScript`、`GameBootstrapScript` directly.
- `scripts/stm/debug/fixtures/fixed_battle_fixture.gd` owns the fixed battle content creation.
- `create_context()` returns `name`、`game_state`、`combat`、`player`、`enemy`。
- Reset still creates a new fixture context because `_on_reset_pressed()` calls `start_debug_combat()`。
- New fixture tests prove fresh instances.
- Existing planner debug tool tests still pass.

- [ ] **Step 3: 检查工作区状态**

Run:

```powershell
git status --short --branch
git log --oneline -5
```

Expected: branch contains the spec commit, plan commit, Task 1 commit, and Task 2 commit. Working tree is clean except for known user-level Git ignore warning if it appears.

- [ ] **Step 4: 请求最终代码审核**

Dispatch a fresh `gpt-5.5` review agent with this scope:

```text
请审查固定战斗内容夹具 v1 的实现。重点检查：
1. 是否遵守 spec：fixture 负责测试内容创建，调试场景只消费上下文。
2. 是否每次创建新玩家、敌人、卡牌、GameState 和 Combat 实例。
3. 是否没有引入正式内容库、JSON/CSV/Resource 配置、网络、Python、Node 或第三方插件依赖。
4. 是否存在空对象、半初始化、重开战斗复用旧状态、测试遗漏或边界不清问题。
5. 是否遵守 AGENT.md：中文 BDD、先测试后实现、新增注释中文。
```

Expected: review reports no blocking issues. If there are blocking issues, fix them with a new BDD-first task and rerun full GUT tests.

---

## 计划自检

- Spec coverage: 计划覆盖 fixture 创建、调试场景接入、新实例保证、失败保护、测试和最终审核。
- Placeholder scan: 本计划没有未决占位、模糊任务或缺失命令。
- Type consistency: 计划统一使用 `StmFixedBattleFixture`、`create_context()`、`current_fixture_name`、`FIXTURE_NAME` 和 `COMBAT_TYPE`。
- Scope check: 本计划不做正式内容库、多预设选择器、配置文件、正式 UI 或参考项目修改。
- Safety check: 本计划不访问网络、不读写用户目录、不新增依赖。
