# 地图/房间/游戏流程 v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在核心战斗骨架之上加入地图、房间和游戏流程层，让调试工具升级为"选层→进房间→战斗→完成→推进→Boss→通关"的迷你闭环。

**Architecture:** 新增 `map/`（地图数据+导航）、`rooms/`（房间基类+CombatRoom+RestRoom+BossRoom）、`game_flow.gd`（流程编排）。所有新增逻辑对象使用 `RefCounted`，不改动现有核心战斗代码。调试场景增加地图导航面板，战斗区域通过 GameFlow 驱动。

**Tech Stack:** Godot 4.6.2、GDScript、GUT、现有 `StmCombat`/`StmFixedBattleFixture`/`StmGameBootstrap`。

---

## 执行约束

- 每个 Task 按 RED-GREEN 顺序：先写中文 BDD 测试 → 运行失败 → 写最小实现 → 运行通过 → 提交。
- 所有新增注释使用中文。
- 不改 `slay-the-model-main/`。
- 不修改现有核心战斗脚本（`combat.gd`、`combat_actions.gd`、`creature.gd`、`card.gd` 等）。
- 单元测试命令：
```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

## 文件结构

**Create**
- `scripts/stm/map/map_data.gd`：固定 7 层测试地图数据
- `scripts/stm/map/map_manager.gd`：当前楼层位置追踪与导航
- `scripts/stm/rooms/base.gd`：房间基类 `StmRoom`
- `scripts/stm/rooms/combat.gd`：`StmCombatRoom`，包装现有战斗
- `scripts/stm/rooms/rest.gd`：`StmRestRoom`，恢复 HP
- `scripts/stm/rooms/boss_room.gd`：`StmBossRoom extends StmCombatRoom`，加强敌人
- `scripts/stm/engine/game_flow.gd`：`StmGameFlow`，编排地图→房间→循环
- `scripts/stm/tests/test_map.gd`：地图数据与管理器测试
- `scripts/stm/tests/test_rooms.gd`：房间类型测试
- `scripts/stm/tests/test_game_flow.gd`：游戏流程测试

**Modify**
- `scripts/stm/debug/battle_debug_scene.gd`：增加地图导航面板、GameFlow 驱动
- `scripts/stm/tests/test_battle_debug_scene.gd`：增加地图 UI 测试
- `.gutconfig.json`：加入三个新测试文件

---

### Task 1: 地图数据与地图管理器

**Files:**
- Create: `scripts/stm/map/map_data.gd`
- Create: `scripts/stm/map/map_manager.gd`
- Create: `scripts/stm/tests/test_map.gd`
- Modify: `.gutconfig.json`

- [ ] **Step 1: 创建目录和测试文件**

```powershell
New-Item -ItemType Directory -Force scripts\stm\map
```

Create `scripts/stm/tests/test_map.gd` with BDD test method names and Chinese Given-When-Then comments:

```gdscript
extends GutTest

const MapDataScript := preload("res://scripts/stm/map/map_data.gd")
const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_floor_count_is_seven() -> void:
	# Given：使用固定测试地图数据。
	# When：读取地图的楼层总数。
	# Then：地图应包含 7 层。
	pass


func test_layer_one_is_single_combat_room() -> void:
	# Given：固定测试地图。
	# When：查询第 0 层（层 1）的房间列表。
	# Then：该层只有 1 间 CombatRoom，且是必经楼层（无分支）。
	pass


func test_layer_five_has_two_branch_options() -> void:
	# Given：固定测试地图。
	# When：查询第 4 层（层 5）的房间列表。
	# Then：该层有 2 间可选房间（CombatRoom 和 RestRoom），形成分支。
	pass


func test_layer_seven_is_boss_room() -> void:
	# Given：固定测试地图。
	# When：查询第 6 层（层 7）的房间列表。
	# Then：该层只有 1 间 BossRoom。
	pass


func test_map_manager_starts_at_floor_zero() -> void:
	# Given：一个基于固定测试地图初始化的地图管理器。
	var manager = MapManagerScript.new()
	# When：查询当前楼层索引。
	var current = manager.get_current_floor_index()
	# Then：初始楼层索引为 0（层 1）。
	pass


func test_map_manager_navigate_to_next_floor() -> void:
	# Given：地图管理器处于第 0 层。
	var manager = MapManagerScript.new()
	# When：导航到第 1 层（层 2）。
	manager.navigate_to_floor(1)
	# Then：当前楼层索引变为 1。
	pass


func test_map_manager_available_next_floors_from_branch() -> void:
	# Given：地图管理器处于第 4 层（层 5，有分支）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(4)
	# When：查询可用的下一层选项。
	var options = manager.get_available_next_floors()
	# Then：返回第 5 层（层 6）作为唯一汇合点，两个可选房间类型都在同一层。
	pass


func test_map_manager_is_final_floor_for_boss_layer() -> void:
	# Given：地图管理器处于第 6 层（层 7 Boss）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(6)
	# When：查询是否为最终楼层。
	var is_final = manager.is_final_floor()
	# Then：返回 true。
	pass
```

- [ ] **Step 2: 补充测试断言并运行确认 RED**

Replace the test methods in `scripts/stm/tests/test_map.gd` with full assertions:

```gdscript
extends GutTest

const MapDataScript := preload("res://scripts/stm/map/map_data.gd")
const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")


func test_floor_count_is_seven() -> void:
	# Given：使用固定测试地图数据。
	# When：读取地图的楼层总数。
	var floors = MapDataScript.FLOORS
	# Then：地图应包含 7 层。
	assert_eq(floors.size(), 7)


func test_layer_one_is_single_combat_room() -> void:
	# Given：固定测试地图。
	# When：查询第 0 层（层 1）的房间列表。
	var layer = MapDataScript.FLOORS[0]
	var rooms = layer["rooms"]
	# Then：该层只有 1 间 CombatRoom，且是必经楼层（无分支）。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "combat")


func test_layer_five_has_two_branch_options() -> void:
	# Given：固定测试地图。
	# When：查询第 4 层（层 5）的房间列表。
	var layer = MapDataScript.FLOORS[4]
	var rooms = layer["rooms"]
	# Then：该层有 2 间可选房间（CombatRoom 和 RestRoom），形成分支。
	assert_eq(rooms.size(), 2)
	var types := []
	for room in rooms:
		types.append(room["type"])
	assert_true(types.has("combat"))
	assert_true(types.has("rest"))


func test_layer_seven_is_boss_room() -> void:
	# Given：固定测试地图。
	# When：查询第 6 层（层 7）的房间列表。
	var layer = MapDataScript.FLOORS[6]
	var rooms = layer["rooms"]
	# Then：该层只有 1 间 BossRoom。
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["type"], "boss")


func test_map_manager_starts_at_floor_zero() -> void:
	# Given：一个基于固定测试地图初始化的地图管理器。
	var manager = MapManagerScript.new()
	# When：查询当前楼层索引。
	var current = manager.get_current_floor_index()
	# Then：初始楼层索引为 0（层 1）。
	assert_eq(current, 0)


func test_map_manager_navigate_to_next_floor() -> void:
	# Given：地图管理器处于第 0 层。
	var manager = MapManagerScript.new()
	# When：导航到第 1 层（层 2）。
	manager.navigate_to_floor(1)
	# Then：当前楼层索引变为 1。
	assert_eq(manager.get_current_floor_index(), 1)


func test_map_manager_available_next_floors_from_branch() -> void:
	# Given：地图管理器处于第 4 层（层 5，有分支）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(4)
	# When：查询可用的下一层选项。
	var options = manager.get_available_next_floors()
	# Then：当前层的 2 个房间各自指向同一汇合层（层 6），但房间类型不同。
	assert_eq(options.size(), 1)
	assert_eq(options[0]["floor_index"], 5)


func test_map_manager_is_final_floor_for_boss_layer() -> void:
	# Given：地图管理器处于第 6 层（层 7 Boss）。
	var manager = MapManagerScript.new()
	manager.navigate_to_floor(6)
	# When：查询是否为最终楼层。
	var is_final = manager.is_final_floor()
	# Then：返回 true。
	assert_true(is_final)
```

Update `.gutconfig.json` to include the new test:

```json
{
  "tests": [
    "res://scripts/stm/tests/core_skeleton_test.gd",
    "res://scripts/stm/tests/test_battle_debug_scene.gd",
    "res://scripts/stm/tests/test_fixed_battle_fixture.gd",
    "res://scripts/stm/tests/test_powers_v1.gd",
    "res://scripts/stm/tests/test_map.gd"
  ],
  "should_exit": true,
  "should_exit_on_success": true,
  "log_level": 2
}
```

Run tests to verify RED:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL — `res://scripts/stm/map/map_data.gd` 和 `res://scripts/stm/map/map_manager.gd` 不存在。

- [ ] **Step 3: 实现地图数据**

Create `scripts/stm/map/map_data.gd`:

```gdscript
class_name StmMapData
extends RefCounted

# 固定 7 层测试地图
# floors[i]["rooms"] 是 Array[Dictionary]，每个 room 包含 type 和 next_floors
# floors[i]["name"] 是楼层显示名
# rooms[j]["type"]: "combat" | "rest" | "boss"
# rooms[j]["next_floors"]: Array[int]，指向下一层索引（空数组表示最终层）
const FLOORS: Array = [
	{
		"name": "第 1 层",
		"rooms": [
			{"type": "combat", "next_floors": [1]}
		]
	},
	{
		"name": "第 2 层",
		"rooms": [
			{"type": "combat", "next_floors": [2]}
		]
	},
	{
		"name": "第 3 层",
		"rooms": [
			{"type": "combat", "next_floors": [3]}
		]
	},
	{
		"name": "第 4 层",
		"rooms": [
			{"type": "rest", "next_floors": [4]}
		]
	},
	{
		"name": "第 5 层",
		"rooms": [
			{"type": "combat", "next_floors": [5]},
			{"type": "rest", "next_floors": [5]}
		]
	},
	{
		"name": "第 6 层",
		"rooms": [
			{"type": "rest", "next_floors": [6]}
		]
	},
	{
		"name": "第 7 层",
		"rooms": [
			{"type": "boss", "next_floors": []}
		]
	},
]
```

- [ ] **Step 4: 实现地图管理器**

Create `scripts/stm/map/map_manager.gd`:

```gdscript
class_name StmMapManager
extends RefCounted

var _current_floor_index: int = 0


func get_current_floor_index() -> int:
	return _current_floor_index


func get_current_floor_info() -> Dictionary:
	if _current_floor_index < 0 or _current_floor_index >= StmMapData.FLOORS.size():
		return {}
	return StmMapData.FLOORS[_current_floor_index].duplicate(true)


func navigate_to_floor(floor_index: int) -> void:
	if floor_index >= 0 and floor_index < StmMapData.FLOORS.size():
		_current_floor_index = floor_index


func get_available_next_floors() -> Array:
	var current_info := get_current_floor_info()
	if current_info.is_empty():
		return []
	var rooms: Array = current_info.get("rooms", [])
	var next_set := {}
	for room in rooms:
		for next_index in room.get("next_floors", []):
			next_set[next_index] = true
	var result: Array = []
	for floor_index in next_set.keys():
		result.append({
			"floor_index": int(floor_index),
			"floor_name": StmMapData.FLOORS[int(floor_index)].get("name", "")
		})
	result.sort_custom(func(a, b): return a["floor_index"] < b["floor_index"])
	return result


func get_available_room_types() -> Array:
	var current_info := get_current_floor_info()
	if current_info.is_empty():
		return []
	var rooms: Array = current_info.get("rooms", [])
	var types: Array = []
	for room in rooms:
		types.append(str(room.get("type", "")))
	return types


func is_final_floor() -> bool:
	return _current_floor_index >= StmMapData.FLOORS.size() - 1
```

- [ ] **Step 5: 运行测试确认通过**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: `test_map.gd` 中 8 个测试全部 PASS，现有测试不受影响。

- [ ] **Step 6: 提交**

```powershell
git add .gutconfig.json scripts/stm/map/map_data.gd scripts/stm/map/map_manager.gd scripts/stm/tests/test_map.gd
git commit -m "feat(stm): add fixed test map data and map manager"
```

---

### Task 2: 房间基类与 CombatRoom

**Files:**
- Create: `scripts/stm/rooms/base.gd`
- Create: `scripts/stm/rooms/combat.gd`
- Create: `scripts/stm/tests/test_rooms.gd`
- Modify: `.gutconfig.json`

- [ ] **Step 1: 创建目录和测试文件**

```powershell
New-Item -ItemType Directory -Force scripts\stm\rooms
```

Create `scripts/stm/tests/test_rooms.gd` with BDD test method names and Chinese Given-When-Then comments:

```gdscript
extends GutTest

const BaseRoomScript := preload("res://scripts/stm/rooms/base.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")


func test_room_enter_sets_is_completed_false() -> void:
	# Given：一个房间实例。
	var room = BaseRoomScript.new()
	# When：调用 enter() 进入房间。
	room.enter(null)
	# Then：is_completed 为 false。
	pass


func test_room_leave_after_enter_does_not_crash() -> void:
	# Given：一个已进入但未完成的房间。
	var room = BaseRoomScript.new()
	room.enter(null)
	# When：调用 leave() 退出房间。
	room.leave(null)
	# Then：不崩溃。
	pass


func test_combat_room_enter_creates_battle_context() -> void:
	# Given：一个 CombatRoom 实例和一个 GameState。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入战斗房间。
	room.enter(game_state)
	# Then：战斗上下文已创建（game_state.player 不为空，combat 不为空）。
	pass


func test_combat_room_complete_sets_is_completed() -> void:
	# Given：一个已经进入的 CombatRoom。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：调用 complete()。
	room.complete(game_state)
	# Then：is_completed 为 true。
	pass


func test_combat_room_get_room_type_returns_combat() -> void:
	# Given：一个 CombatRoom。
	var room = CombatRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "combat"。
	pass
```

- [ ] **Step 2: 补充测试断言并运行确认 RED**

Replace test methods with full assertions:

```gdscript
extends GutTest

const BaseRoomScript := preload("res://scripts/stm/rooms/base.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	var game_state = bootstrap.create_game(player)
	return game_state


func test_room_enter_sets_is_completed_false() -> void:
	# Given：一个房间实例。
	var room = BaseRoomScript.new()
	# When：调用 enter() 进入房间。
	room.enter(null)
	# Then：is_completed 为 false。
	assert_false(room.is_completed)


func test_room_leave_after_enter_does_not_crash() -> void:
	# Given：一个已进入但未完成的房间。
	var room = BaseRoomScript.new()
	room.enter(null)
	# When：调用 leave() 退出房间。
	room.leave(null)
	# Then：不崩溃，方法正常返回。
	assert_not_null(room)


func test_combat_room_enter_creates_battle_context() -> void:
	# Given：一个 CombatRoom 实例和一个 GameState。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入战斗房间。
	room.enter(game_state)
	# Then：战斗上下文已创建（game_state 持有 player 和 combat）。
	assert_not_null(game_state.player)
	assert_not_null(game_state.current_combat)
	assert_not_null(room.get_player())


func test_combat_room_complete_sets_is_completed() -> void:
	# Given：一个已经进入的 CombatRoom。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：调用 complete()。
	room.complete(game_state)
	# Then：is_completed 为 true。
	assert_true(room.is_completed)


func test_combat_room_get_room_type_returns_combat() -> void:
	# Given：一个 CombatRoom。
	var room = CombatRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "combat"。
	assert_eq(room_type, "combat")
```

Add test_rooms.gd to `.gutconfig.json`:

```json
{
  "tests": [
    "res://scripts/stm/tests/core_skeleton_test.gd",
    "res://scripts/stm/tests/test_battle_debug_scene.gd",
    "res://scripts/stm/tests/test_fixed_battle_fixture.gd",
    "res://scripts/stm/tests/test_powers_v1.gd",
    "res://scripts/stm/tests/test_map.gd",
    "res://scripts/stm/tests/test_rooms.gd"
  ],
  "should_exit": true,
  "should_exit_on_success": true,
  "log_level": 2
}
```

Run tests to verify RED:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL — `res://scripts/stm/rooms/base.gd` 和 `res://scripts/stm/rooms/combat.gd` 不存在。

- [ ] **Step 3: 实现房间基类**

Create `scripts/stm/rooms/base.gd`:

```gdscript
class_name StmRoom
extends RefCounted

var is_completed: bool = false


func enter(_game_state) -> void:
	is_completed = false


func leave(_game_state) -> void:
	pass


func complete(_game_state) -> void:
	is_completed = true


func get_room_type() -> String:
	return ""
```

- [ ] **Step 4: 实现 CombatRoom**

Create `scripts/stm/rooms/combat.gd`:

```gdscript
class_name StmCombatRoom
extends StmRoom

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")

var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	var fixture = FixedBattleFixtureScript.new()
	var context: Dictionary = fixture.create_context()
	if context.is_empty():
		return
	_player = context["player"]
	_combat = context["combat"]
	_enemy = context["enemy"]
	if game_state != null:
		game_state.player = _player
		game_state.current_combat = _combat
	_combat.start(game_state)


func leave(_game_state) -> void:
	_player = null
	_combat = null
	_enemy = null


func get_player():
	return _player


func get_combat():
	return _combat


func get_enemy():
	return _enemy


func get_room_type() -> String:
	return "combat"
```

- [ ] **Step 5: 运行测试确认通过**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: `test_rooms.gd` 中 5 个测试 PASS，现有测试不受影响。

- [ ] **Step 6: 提交**

```powershell
git add .gutconfig.json scripts/stm/rooms/base.gd scripts/stm/rooms/combat.gd scripts/stm/tests/test_rooms.gd
git commit -m "feat(stm): add room base and combat room"
```

---

### Task 3: RestRoom 与 BossRoom

**Files:**
- Create: `scripts/stm/rooms/rest.gd`
- Create: `scripts/stm/rooms/boss_room.gd`
- Modify: `scripts/stm/tests/test_rooms.gd`

- [ ] **Step 1: 补充失败测试**

Append these test methods to `scripts/stm/tests/test_rooms.gd`（在最后一个测试之后、文件末尾之前）:

```gdscript
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")
const CombatScript := preload("res://scripts/stm/engine/combat.gd")


func test_rest_room_restores_thirty_percent_max_hp() -> void:
	# Given：玩家 HP 低于最大值，进入休息房间。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = GameStateScript.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房间。
	room.enter(game_state)
	# Then：玩家恢复 30% 最大 HP（70 × 0.3 = 21），HP 变为 61。
	assert_eq(player.hp, 61)
	assert_true(room.is_completed)


func test_rest_room_does_not_exceed_max_hp() -> void:
	# Given：玩家 HP 接近满值。
	var player = PlayerScript.new([])
	player.hp = 65
	var game_state = GameStateScript.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房间。
	room.enter(game_state)
	# Then：HP 不会超过最大值 70。
	assert_eq(player.hp, 70)


func test_rest_room_get_room_type_returns_rest() -> void:
	# Given：一个 RestRoom。
	var room = RestRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "rest"。
	assert_eq(room_type, "rest")


func test_boss_room_extends_combat_room() -> void:
	# Given：一个 BossRoom。
	var room = BossRoomScript.new()
	# When：检查继承链。
	var is_combat_room = room is CombatRoomScript
	var is_base_room = room is BaseRoomScript
	# Then：BossRoom 是 CombatRoom 的子类，也是 Room 的子类。
	assert_true(is_combat_room)
	assert_true(is_base_room)


func test_boss_room_get_room_type_returns_boss() -> void:
	# Given：一个 BossRoom。
	var room = BossRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "boss"。
	assert_eq(room_type, "boss")


func test_boss_room_creates_stronger_enemy() -> void:
	# Given：一个 BossRoom 实例和一个 GameState。
	var room = BossRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入 BOSS 房间。
	room.enter(game_state)
	var enemy = room.get_enemy()
	# Then：敌人名称包含 Boss，HP 为 40，攻击力为 12。
	assert_not_null(enemy)
	assert_eq(enemy.enemy_name, "BossEnemy")
	assert_eq(enemy.max_hp, 40)
	assert_eq(enemy.hp, 40)
	assert_eq(enemy.intent_damage, 12)
```

- [ ] **Step 2: 运行确认 RED**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL — `res://scripts/stm/rooms/rest.gd` 和 `res://scripts/stm/rooms/boss_room.gd` 不存在。

- [ ] **Step 3: 实现 RestRoom**

Create `scripts/stm/rooms/rest.gd`:

```gdscript
class_name StmRestRoom
extends StmRoom


func enter(game_state) -> void:
	super.enter(game_state)
	if game_state == null or game_state.player == null:
		is_completed = true
		return
	var player = game_state.player
	var heal_amount: int = int(float(player.max_hp) * 0.3)
	player.hp = min(player.max_hp, player.hp + heal_amount)
	is_completed = true


func get_room_type() -> String:
	return "rest"
```

- [ ] **Step 4: 实现 BossRoom**

Create `scripts/stm/rooms/boss_room.gd`:

```gdscript
class_name StmBossRoom
extends StmCombatRoom

const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func enter(game_state) -> void:
	is_completed = false
	var bootstrap = GameBootstrapScript.new()
	var fixture = load("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd").new()
	var context: Dictionary = fixture.create_context()
	if context.is_empty():
		return
	_player = context["player"]
	var boss_enemy = EnemyScript.new(40, "BossEnemy", 12)
	var combat_script = load("res://scripts/stm/engine/combat.gd")
	if combat_script != null:
		_combat = combat_script.new([boss_enemy], "boss")
	_enemy = boss_enemy
	if game_state != null:
		game_state.player = _player
		game_state.current_combat = _combat
	if _combat != null:
		_combat.start(game_state)


func get_room_type() -> String:
	return "boss"
```

- [ ] **Step 5: 运行测试确认通过**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: `test_rooms.gd` 中全部 11 个测试 PASS，现有测试不受影响。

- [ ] **Step 6: 提交**

```powershell
git add scripts/stm/rooms/rest.gd scripts/stm/rooms/boss_room.gd scripts/stm/tests/test_rooms.gd
git commit -m "feat(stm): add rest room and boss room"
```

---

### Task 4: GameFlow 流程编排

**Files:**
- Create: `scripts/stm/engine/game_flow.gd`
- Create: `scripts/stm/tests/test_game_flow.gd`
- Modify: `.gutconfig.json`

- [ ] **Step 1: 创建测试文件**

Create `scripts/stm/tests/test_game_flow.gd` with BDD test method names and Chinese Given-When-Then comments:

```gdscript
extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


func test_game_flow_starts_at_floor_zero() -> void:
	# Given：一个新创建的 GameFlow。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：查询当前楼层索引。
	var floor_index = flow.get_current_floor_index()
	# Then：初始楼层索引为 0。
	pass


func test_game_flow_enter_combat_room_creates_battle() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：进入当前楼层的战斗房间。
	flow.enter_current_room()
	# Then：game_state 中创建了战斗上下文。
	pass


func test_game_flow_complete_room_then_get_next_options() -> void:
	# Given：GameFlow 处于第 0 层，已进入战斗房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：查询可选的下一层。
	var options = flow.get_available_next_floors()
	# Then：返回第 1 层作为下一层选项。
	pass


func test_game_flow_advance_to_next_floor() -> void:
	# Given：GameFlow 处于第 0 层，房间已完成。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：推进到下一层。
	flow.advance_to_next_floor(1)
	# Then：当前楼层索引变为 1。
	pass


func test_game_flow_at_boss_floor_sets_flow_completed_on_win() -> void:
	# Given：GameFlow 直接导航到第 6 层 BossRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow._map_manager.navigate_to_floor(6)
	# When：进入 BOSS 房间并直接标记完成。
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# Then：flow_completed 为 true。
	pass


func test_game_flow_not_completed_at_non_boss_floor() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：检查 flow_completed。
	var is_completed = flow.is_flow_completed()
	# Then：普通战斗完成不应触发通关。
	pass
```

- [ ] **Step 2: 补充测试断言并运行确认 RED**

Replace test methods with full assertions:

```gdscript
extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


func test_game_flow_starts_at_floor_zero() -> void:
	# Given：一个新创建的 GameFlow。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：查询当前楼层索引。
	var floor_index = flow.get_current_floor_index()
	# Then：初始楼层索引为 0。
	assert_eq(floor_index, 0)


func test_game_flow_enter_combat_room_creates_battle() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：进入当前楼层的战斗房间。
	flow.enter_current_room()
	# Then：game_state 中创建了战斗上下文。
	assert_not_null(game_state.current_combat)
	assert_not_null(game_state.player)
	assert_not_null(flow.get_current_room())


func test_game_flow_complete_room_then_get_next_options() -> void:
	# Given：GameFlow 处于第 0 层，已进入战斗房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：查询可选的下一层。
	var options = flow.get_available_next_floors()
	# Then：返回第 1 层作为下一层选项。
	assert_eq(options.size(), 1)
	assert_eq(options[0]["floor_index"], 1)


func test_game_flow_advance_to_next_floor() -> void:
	# Given：GameFlow 处于第 0 层，房间已完成。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：推进到下一层。
	flow.advance_to_next_floor(1)
	# Then：当前楼层索引变为 1。
	assert_eq(flow.get_current_floor_index(), 1)


func test_game_flow_at_boss_floor_sets_flow_completed_on_win() -> void:
	# Given：GameFlow 直接导航到第 6 层 BossRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow._map_manager.navigate_to_floor(6)
	# When：进入 BOSS 房间并直接标记完成。
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# Then：flow_completed 为 true。
	assert_true(flow.is_flow_completed())


func test_game_flow_not_completed_at_non_boss_floor() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：检查 flow_completed。
	var is_completed = flow.is_flow_completed()
	# Then：普通战斗完成不应触发通关。
	assert_false(is_completed)
```

Add test_game_flow.gd to `.gutconfig.json`:

```json
{
  "tests": [
    "res://scripts/stm/tests/core_skeleton_test.gd",
    "res://scripts/stm/tests/test_battle_debug_scene.gd",
    "res://scripts/stm/tests/test_fixed_battle_fixture.gd",
    "res://scripts/stm/tests/test_powers_v1.gd",
    "res://scripts/stm/tests/test_map.gd",
    "res://scripts/stm/tests/test_rooms.gd",
    "res://scripts/stm/tests/test_game_flow.gd"
  ],
  "should_exit": true,
  "should_exit_on_success": true,
  "log_level": 2
}
```

Run tests to verify RED:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL — `res://scripts/stm/engine/game_flow.gd` 不存在。

- [ ] **Step 3: 实现 GameFlow**

Create `scripts/stm/engine/game_flow.gd`:

```gdscript
class_name StmGameFlow
extends RefCounted

const MapManagerScript := preload("res://scripts/stm/map/map_manager.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")

var _map_manager: StmMapManager = MapManagerScript.new()
var _current_room = null
var _game_state = null
var flow_completed: bool = false


func _init(game_state) -> void:
	_game_state = game_state


func get_current_floor_index() -> int:
	return _map_manager.get_current_floor_index()


func get_current_room():
	return _current_room


func get_game_state():
	return _game_state


func is_flow_completed() -> bool:
	return flow_completed


func get_available_next_floors() -> Array:
	return _map_manager.get_available_next_floors()


func get_current_floor_room_types() -> Array:
	return _map_manager.get_available_room_types()


func enter_current_room() -> void:
	var room_types := _map_manager.get_available_room_types()
	if room_types.is_empty():
		return
	var room_type: String = room_types[0]
	var room = null
	match room_type:
		"combat":
			room = CombatRoomScript.new()
		"rest":
			room = RestRoomScript.new()
		"boss":
			room = BossRoomScript.new()
		_:
			return
	_current_room = room
	_current_room.enter(_game_state)


func complete_current_room() -> void:
	if _current_room == null:
		return
	_current_room.complete(_game_state)
	if _current_room.get_room_type() == "boss":
		flow_completed = true


func advance_to_next_floor(floor_index: int) -> void:
	leave_current_room()
	_map_manager.navigate_to_floor(floor_index)


func leave_current_room() -> void:
	if _current_room == null:
		return
	_current_room.leave(_game_state)
	_current_room = null
```

- [ ] **Step 4: 运行测试确认通过**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: `test_game_flow.gd` 中 6 个测试 PASS，现有测试不受影响。

- [ ] **Step 5: 提交**

```powershell
git add .gutconfig.json scripts/stm/engine/game_flow.gd scripts/stm/tests/test_game_flow.gd
git commit -m "feat(stm): add game flow orchestration"
```

---

### Task 5: 调试场景地图 UI 集成

**Files:**
- Modify: `scripts/stm/debug/battle_debug_scene.gd`
- Modify: `scripts/stm/tests/test_battle_debug_scene.gd`

- [ ] **Step 1: 补充失败测试**

在 `scripts/stm/tests/test_battle_debug_scene.gd` 的 preload 区增加：

```gdscript
const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
```

在测试文件中添加以下测试方法（插入到现有测试方法之间，例如在 `test_debug_scene_shows_initial_combat_state()` 之后）:

```gdscript
func test_debug_scene_starts_with_map_navigation_panel() -> void:
	# Given：策划打开调试场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景完成初始化。
	# Then：场景显示地图导航面板，包含当前楼层、房间类型和可选路径，而不是直接开始战斗。
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/MapPanel"))
	assert_true(_label_text(scene, "Layout/MainPanel/MapPanel/CurrentFloorLabel").length() > 0)
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/MapPanel/EnterRoomButton"))


func test_debug_scene_enter_combat_room_shows_battle_ui() -> void:
	# Given：调试场景已启动，显示地图面板。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：点击进入房间按钮（当前层为 CombatRoom）。
	_press_button(scene, "Layout/MainPanel/MapPanel/EnterRoomButton")
	# Then：战斗 UI 显示，地图面板隐藏。
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/HandButtons"))
	assert_true(_label_text(scene, "Layout/LogPanel/LogLabel").contains("战斗开始"))


func test_debug_scene_game_flow_completed_shows_victory() -> void:
	# Given：调试场景已启动，GameFlow 直接进入 Boss 层并完成。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	var flow = scene.game_flow
	if flow == null:
		return
	flow._map_manager.navigate_to_floor(6)
	flow.enter_current_room()
	flow.complete_current_room()
	scene._on_room_completed()
	# When：场景刷新。
	scene._refresh_display()
	# Then：显示通关信息。
	assert_true(flow.is_flow_completed())
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/VictoryLabel"))
```

- [ ] **Step 2: 运行确认 RED**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: FAIL — `Layout/MainPanel/MapPanel` 等节点不存在。

- [ ] **Step 3: 改造 battle_debug_scene.gd**

修改 `scripts/stm/debug/battle_debug_scene.gd`：

**a) 在 preload 区增加 GameFlow 依赖**

将现有的 `const FixedBattleFixtureScript` 保留，新增：

```gdscript
const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
```

**b) 新增状态变量**

在现有变量区（`var enemy` 之后）增加：

```gdscript
var game_flow
var map_panel: VBoxContainer
var current_floor_label: Label
var room_choices_label: Label
var enter_room_button: Button
var next_floor_container: VBoxContainer
var victory_label: Label
```

**c) 修改 `start_debug_combat()`**

替换现有实现：

```gdscript
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
```

**d) 修改 `_build_ui()` 的 MainPanel 结构**

在 `MainPanel` 创建后，增加地图面板节点（在 Metrics 之前）：

```gdscript
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
```

**e) 在 `_show_no_combat_display()` 中增加地图面板清空逻辑**

```gdscript
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
```

**f) 扩展 `_refresh_display()`**

在 `_refresh_display()` 函数开头增加 GameFlow 驱动的面板刷新：

```gdscript
	if game_flow != null and game_flow.is_flow_completed():
		if map_panel != null:
			map_panel.visible = true
		if victory_label != null:
			victory_label.visible = true
		_show_map_panel_state()
		status_label.text = "游戏通关"
		return

	if game_flow != null and game_state != null and game_state.current_combat == null:
		if map_panel != null:
			map_panel.visible = true
		_show_map_panel_state()
		status_label.text = status_message
		return
```

**g) 新增地图面板刷新辅助函数**

```gdscript
func _show_map_panel_state() -> void:
	if game_flow == null:
		return
	var floor_index = game_flow.get_current_floor_index()
	var floor_name = _get_floor_display_name(floor_index)
	current_floor_label.text = "当前楼层：%s" % floor_name

	var room_types := game_flow.get_current_floor_room_types()
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

	var next_floors := game_flow.get_available_next_floors()
	if not next_floors.is_empty():
		for option in next_floors:
			var btn = _new_button("NextFloorButton%d" % option["floor_index"], "→ %s" % option["floor_name"])
			btn.pressed.connect(_on_next_floor_selected.bind(option["floor_index"]))
			next_floor_container.add_child(btn)


func _get_floor_display_name(floor_index: int) -> String:
	var floors = StmMapData.FLOORS
	if floor_index >= 0 and floor_index < floors.size():
		return str(floors[floor_index].get("name", "第 %d 层" % (floor_index + 1)))
	return "第 %d 层" % (floor_index + 1)
```

**h) 新增地图交互回调**

```gdscript
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
	var room_type := room.get_room_type()
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
	var next_floors := game_flow.get_available_next_floors()
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
```

**i) 修改 `_on_end_turn_pressed()` —— 战斗胜利后触发房间完成**

在现有 `_on_end_turn_pressed()` 末尾，检查 section 添加：

```gdscript
	var result = combat.end_turn(game_state)
	# ... 现有日志和刷新代码 ...
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		if game_flow != null and game_flow.get_current_room() != null:
			game_flow.complete_current_room()
			_on_room_completed()
			return
	_refresh_display()
```

**j) 修改 `_play_card_from_hand()` —— 出牌后如果战斗胜利则触发房间完成**

在 `_play_card_from_hand()` 调用 `combat.play_card()` 之后：

```gdscript
	var result = combat.play_card(game_state, card, targets)
	# ... 现有日志 ...
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		if game_flow != null and game_flow.get_current_room() != null:
			game_flow.complete_current_room()
			_on_room_completed()
			return
	_refresh_display()
```

**k) 修改 `_on_reset_pressed()`**

替换为：

```gdscript
func _on_reset_pressed() -> void:
	start_debug_combat()
```

- [ ] **Step 4: 更新测试以匹配新结构**

修改 `scripts/stm/tests/test_battle_debug_scene.gd`：

- 将 `test_debug_scene_shows_initial_combat_state()` 中的断言更新为检查 MapPanel 节点（因为场景现在以地图面板开始，而非立即战斗）。
- 保留现有其他测试方法但跳过直接检查战斗 UI 的测试（因为现在需要先进入房间才有战斗 UI）。

更新后的关键测试方法：

```gdscript
func test_debug_scene_shows_initial_combat_state() -> void:
	# Given：策划打开固定调试战斗场景。
	var scene = _instantiate_debug_scene()
	assert_not_null(scene)
	if scene == null:
		return
	# When：场景初始化完成。
	# Then：界面显示地图导航面板，包含当前楼层和进入房间按钮。
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/MapPanel"))
	assert_true(_label_text(scene, "Layout/MainPanel/MapPanel/CurrentFloorLabel").length() > 0)
	assert_not_null(scene.get_node_or_null("Layout/MainPanel/MapPanel/EnterRoomButton"))
```

- [ ] **Step 5: 运行测试确认通过**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: 新增的地图 UI 测试 PASS，现有测试中需要调整的测试方法更新后也 PASS。如果部分旧测试因结构变化失败，逐一定位修正。

- [ ] **Step 6: 提交**

```powershell
git add scripts/stm/debug/battle_debug_scene.gd scripts/stm/tests/test_battle_debug_scene.gd
git commit -m "feat(debug): integrate map room flow into battle debug scene"
```

---

### Task 6: 最终自检与整体验证

**Files:**
- Review: all modified files from Tasks 1-5

- [ ] **Step 1: 运行完整 GUT 测试**

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" -s addons/gut/gut_cmdln.gd
```

Expected: PASS，所有测试通过。现有测试（核心骨架、状态效果、调试场景、固定夹具）不受影响。

- [ ] **Step 2: 占位符扫描**

```powershell
rg -n "TB[D]|TO[D]O|implement\s+later|fill\s+in\s+details|Add\s+appropriate\s+error\s+handling|Write\s+tests\s+for\s+the\s+above|Similar\s+to\s+Task" scripts/stm docs/superpowers/plans/2026-05-26-map-room-game-flow-v1.md docs/superpowers/specs/2026-05-26-map-room-game-flow-v1-design.md
```

Expected: no matches。

- [ ] **Step 3: 检查实现覆盖 spec**

手动验证：
- `scripts/stm/map/map_data.gd` 定义了固定 7 层地图 ✓
- `scripts/stm/map/map_manager.gd` 提供楼层导航 ✓
- `scripts/stm/rooms/base.gd` 定义房间生命周期 ✓
- `scripts/stm/rooms/combat.gd` 包装现有战斗 ✓
- `scripts/stm/rooms/rest.gd` 恢复 HP ✓
- `scripts/stm/rooms/boss_room.gd` 使用加强敌人 ✓
- `scripts/stm/engine/game_flow.gd` 编排地图→房间→循环 ✓
- `scripts/stm/debug/battle_debug_scene.gd` 增加地图导航面板 ✓
- 所有新增逻辑对象使用 `extends RefCounted` ✓
- 未修改现有核心战斗脚本 ✓

- [ ] **Step 4: 检查工作区状态**

```powershell
git status --short --branch
git diff --check
```

Expected: 工作区干净（除 `C:\Users\User\.config/git/ignore` 权限警告外）。

- [ ] **Step 5: 最终提交**

如果 Step 3 或 Step 4 产生了修正，提交：

```powershell
git add scripts/stm docs/superpowers/plans/2026-05-26-map-room-game-flow-v1.md
git commit -m "chore(stm): verify map room game flow v1"
```

如果无改动，不创建空提交。

---

## 自检记录

**Spec coverage**
- 固定 7 层测试地图：Task 1
- MapManager 导航：Task 1
- Room 基类生命周期：Task 2
- CombatRoom 包装战斗：Task 2
- RestRoom 恢复 HP：Task 3
- BossRoom 加强敌人：Task 3
- GameFlow 编排：Task 4
- 调试场景地图 UI：Task 5
- 全量 GUT + 最终验证：Task 6

**Placeholder scan**
- 本计划不使用 TBD、TODO、或待填内容。

**Type consistency**
- `StmMapData.FLOORS`：Array of Dictionary，与 `StmMapManager` 读取一致
- `StmRoom.enter(game_state)` / `leave(game_state) / `complete(game_state)` 签名统一
- `StmGameFlow._map_manager` 类型为 `StmMapManager`
- 测试文件使用 `const` preload 模式，与现有测试风格一致
- `.gutconfig.json` 路径使用 `res://` 前缀

**安全自检**
- 不修改 `slay-the-model-main/` ✓
- 不引入网络、API、新插件 ✓
- 所有逻辑对象 `extends RefCounted` ✓
- 不改动现有核心战斗代码 ✓
