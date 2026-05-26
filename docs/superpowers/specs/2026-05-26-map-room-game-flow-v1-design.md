# 地图/房间/游戏流程 v1 设计

## 目的

在现有 GDScript 战斗骨架之上，加入地图、房间和游戏流程层，让调试工具从“单场战斗模拟器”升级为“可循环的迷你游戏闭环”。

第一阶段只实现最小闭环：固定测试地图 + 3 种房间类型 + 文本菜单导航 + 休息回血。

## 背景

当前 `scripts/stm/` 规则骨架已包含完整的单场战斗系统（Combat、ActionQueue、Player/Card/Enemy/Powers），但缺少战斗之间的衔接层。Python 参考项目有完整的 `map/`、`rooms/`、`engine/game_flow.py` 系统，本设计从中提取最小子集。

## 推荐方案

### 架构概览

新增 3 个模块目录 + 1 个引擎文件，改造 1 个调试场景：

```text
scripts/stm/
├── map/            （新增）地图数据与导航
├── rooms/          （新增）房间基类与具体房间
├── engine/
│   └── game_flow.gd  （新增）游戏流程编排
└── debug/
    └── battle_debug_scene.gd  （改造）增加地图导航 UI
```

### 模块职责

**`scripts/stm/map/`**
- `map_data.gd`：定义固定测试地图的楼层列表和连接关系。数据用嵌套数组描述，每层包含可用房间及其下一层可选索引。
- `map_manager.gd`：持有当前楼层位置，提供 `get_current_floor_info()`、`get_available_next_floors()`、`navigate_to_next_floor(target_floor_index)` 等方法。
- `navigate_to_floor()` 仅作为底层定位方法使用；正常流程应通过 `GameFlow.advance_to_next_floor()` 推进。

**`scripts/stm/rooms/`**
- `base.gd`：房间基类 `StmRoom`。定义 `enter(game_state) → void`、`leave(game_state) → void` 生命周期方法，以及 `is_completed: bool` 状态。
- `combat.gd`：`StmCombatRoom extends StmRoom`。进入时通过 `StmFixedBattleFixture` 创建/补齐测试战斗上下文并调用 `combat.start()`。普通战斗使用 DummyEnemy。
- `rest.gd`：`StmRestRoom extends StmRoom`。进入后恢复玩家 30% 最大 HP，记录 `last_hp_before`、`last_hp_after`、`last_heal_amount`，并立即标记完成。
- `boss_room.gd`：`StmBossRoom extends StmCombatRoom`。覆盖 `enter()`，使用 BossEnemy（HP 40，攻击 12）替代 DummyEnemy。

**`scripts/stm/engine/game_flow.gd`**
- `StmGameFlow`：编排地图→房间→战斗→循环。持有 `MapManager`、当前 `Room` 实例、`GameState` 引用。
- 当前 v1 公开 API：
  - `get_current_floor_index() -> int`
  - `get_current_room()`
  - `get_game_state()`
  - `is_flow_completed() -> bool`
  - `get_current_floor_room_types() -> Array`
  - `get_available_next_floors() -> Array`
  - `enter_current_room(room_index: int = 0) -> bool`
  - `complete_current_room() -> bool`
  - `handle_combat_result(result: int) -> bool`
  - `advance_to_next_floor(floor_index: int) -> bool`
  - `debug_navigate_to_floor_for_test(floor_index: int) -> bool`，仅供测试/调试定位楼层使用，正常游戏流程不得调用。
- Boss 胜利后设置 `flow_completed: bool = true`。

**`scripts/stm/debug/battle_debug_scene.gd`（改造）**
- 新增地图导航面板：显示当前楼层、可选下一层路径、房间类型名称。
- 战斗区域保留现有手牌点击、数值编辑、日志等功能，但战斗胜利后显示“前往下一层”按钮替代手动操作。
- 休息房间显示恢复 HP 的简要日志。
- Boss 胜利后显示“游戏通关”。

## 测试地图设计

固定 7 层，3 种分支结构：

```text
层 1: CombatRoom（必经）
层 2: CombatRoom（必经）
层 3: CombatRoom ─┐（必经）
层 4: RestRoom   ─┘（必经）
层 5: CombatRoom ─┐
                  ├─ 二选一分支
层 6: RestRoom   ─┘
层 7: BossRoom    （必经）
```

- 层 1-3：连续战斗，测试战斗耐力。
- 层 4：第一间休息房。
- 层 5-6：战斗/休息分支选择 + 最后一间休息房。
- 层 7：Boss 战（DummyEnemy 加强版：HP 40，攻击 12，名称 `BossEnemy`）。
- 最短路径：层 1→2→3→4（休息）→跳过层 5→层 6（休息）→层 7（Boss）= 3 场普通战斗 + 1 场 Boss + 2 次休息。
- 最长路径：层 1→2→3→4（休息）→层 5（战斗）→层 6（休息）→层 7（Boss）= 4 场普通战斗 + 1 场 Boss + 2 次休息。

## 房间类型

### CombatRoom

- `enter()`：使用 `StmFixedBattleFixture` 创建 DummyEnemy/Combat，并在玩家不存在或玩家 deck 为空时补齐固定测试牌组。
- 普通战斗敌人：DummyEnemy（HP 20，攻击 6）。
- Boss 战斗敌人：直接用 `StmEnemy.new(40, "BossEnemy", 12)` 构造，不创建新脚本文件。
- 战斗通过现有 `combat.start()` 和 `combat.play_card()` / `combat.end_turn()` 流程。
- 战斗胜利（`TerminalResult.COMBAT_WIN`）后通过 `handle_combat_result()` 标记 `is_completed = true`。

### RestRoom

- `enter()`：恢复 `player.hp = min(player.max_hp, player.hp + int(player.max_hp * 0.3))`。
- 记录 `last_hp_before`、`last_hp_after`、`last_heal_amount`，供调试 UI 可信展示。
- 立即标记 `is_completed = true`，不需要玩家操作。
- 如果玩家 HP 已满，仍算完成，不报错。

### BossRoom

- 继承 CombatRoom（`StmBossRoom extends StmCombatRoom`）。
- `enter()` 覆盖父类：使用 `StmEnemy.new(40, "BossEnemy", 12)` 替代 DummyEnemy。
- 战斗胜利后，`GameFlow.handle_combat_result()` 设置 `flow_completed = true`。

## 安全模型

延续核心骨架设计的所有安全约束：

- `slay-the-model-main/` 始终只读。不编辑、删除、重命名其中任何文件。
- 不在规则层引入网络调用、API key、模型调用、遥测、存档上传或远程内容加载。
- MCP / Godot 交互服务仅属于本地开发调试工具，不属于游戏规则层；正式导出或展示构建应禁用或移除相关 autoload/config。
- 不新增 Godot 插件（GUT 已就位，不再下载其他依赖）。
- 不写入 Godot 项目目录之外的位置。
- 不创建破坏性编辑器工具、代码生成器或批量文件重写脚本。
- 测试必须确定性执行：不使用未设种子的随机断言，不依赖墙上时间，不依赖用户输入。
- 规则测试必须可在 headless 环境运行。

## 依赖

- Godot 版本：4.6.2。
- 语言：仅使用 GDScript。不依赖 Python 运行时。
- 测试入口：`godot -s addons/gut/gut_cmdln.gd`（与 AGENT.md 一致）。
- 允许在测试中直接构造对象实例，不要求 autoload 单例。
- 除 GUT 外不新增第三方依赖。

## 对象类型约定

- `map/`、`rooms/`、`game_flow.gd` 中所有逻辑对象使用 `extends RefCounted`。
- 只有调试场景（`battle_debug_scene.gd`）可以使用 `extends Control`（Node）。
- 地图和房间数据使用简单数组与字典，不引入外部配置文件。

## 边界合同

延续核心骨架设计的所有边界合同，并新增以下模块边界：

- `map/` 只负责地图数据与导航查询。不应知道战斗流程、玩家状态、HP 或牌堆。
- `rooms/` 负责房间内逻辑（进入/离开/完成）。可以调用战斗系统（`StmCombat`、`StmFixedBattleFixture`），但不应知道地图结构或 UI。
- `game_flow.gd` 持有 `MapManager` + 当前 `Room` + `GameState`，负责编排三者。不应知道具体房间内部实现，也不应直接操作 UI。
- 调试场景只通过 `GameFlow` 的公开方法驱动流程，不直接操作 `MapManager` 或 `Room` 实例。
- 测试如需定位到特定楼层，使用 `GameFlow.debug_navigate_to_floor_for_test()`，不直接访问 `_map_manager`。
- 不改动现有核心战斗逻辑（`combat.gd`、`combat_actions.gd`、`creature.gd`、`card.gd` 等），房间层只包装调用这些公开接口。
- 未来完整系统（多 Act、商店、事件、宝箱、选牌奖励、遗物、药水）是扩展点，不在此阶段实现。

## 调试 UI 改造要点

- 场景初始时显示地图导航面板（替代立即启动战斗）。
- 玩家点击“进入战斗”后展开战斗区域。
- 战斗区域与当前功能完全一致（手牌按钮、数值编辑、日志）。
- 战斗胜利后隐藏战斗区域，显示“房间完成”和“选择下一层”。
- 休息房间自动处理，显示回复日志。
- Boss 胜利后显示“游戏通关”标签。

## 测试策略

- 新增 `scripts/stm/tests/test_map.gd`：验证地图数据完整性和分支结构。
- 新增 `scripts/stm/tests/test_rooms.gd`：验证 CombatRoom 能启动战斗、RestRoom 正确回复 HP、BossRoom 使用加强敌人。
- 新增 `scripts/stm/tests/test_game_flow.gd`：验证流程状态迁移（创建→进房间→完成→推进→Boss→通关），以及未完成不能推进、不可达不能跳转、完成后未推进前不能重复进房间。
- 修改 `scripts/stm/tests/test_battle_debug_scene.gd`：验证地图导航 UI 节点和交互。
- 测试函数名使用英文，Given-When-Then 行为注释使用中文。
- 遵循 AGENT.md 的 BDD 流程：先写测试方法名和中文 Given-When-Then 注释，再写断言代码，再写实现代码。
- 运行命令：`godot -s addons/gut/gut_cmdln.gd`。
- 所有测试必须 headless 可运行。

## 非目标

- 不实现多 Act 切换。
- 不实现程序随机地图生成。
- 不实现商店、事件、宝箱房间。
- 不实现战斗奖励选牌。
- 不实现卡牌升级。
- 不实现遗物、药水、充能球。
- 不实现正式地图可视化（只做文本菜单）。
- 不修改 `slay-the-model-main/`。

## 验收标准

- 调试场景能从地图导航开始，选择楼层，进入战斗或休息房间。
- 战斗房间复用现有手牌点击出牌流程，胜利后回到地图。
- 休息房间自动恢复 HP 并记录日志。
- Boss 房间使用加强敌人，胜利后显示通关。
- 地图的固定 7 层结构和分支路径可被测试验证。
- 全量 GUT 测试通过。
- 现有测试（核心骨架、状态效果、调试场景）不受影响。
