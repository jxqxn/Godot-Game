# STS2 固定地图节点分支 v1 设计

## 当前定位

本规格是 `STS2 休息房间选择请求 v1` 之后的主干修正。

当前 Godot 主干已经具备：

```text
地图选择房间
战斗房间
战斗胜利后 card_reward 选择请求
休息房 rest_choice 选择请求
Boss 胜利通关
BattleDebugScene 可完整跑通固定测试流程
```

但当前固定测试地图仍使用简化的“楼层跳转表”。第 4 层休息房完成后，玩家看到的是：

```text
→ 第 5 层
→ 第 6 层
```

这会造成一个不自然结果：

```text
选择第 5 层后，要先打第 5 层战斗，再进入第 6 层休息。
选择第 6 层后，则直接进入第 6 层休息。
```

这不是严格意义上的“同层二选一分支”，而是“多打一层 vs 跳过一层”。

本阶段目标：

```text
把固定测试地图从“楼层跳转表”改成“节点图”
玩家每次只能从当前节点选择下一层可达节点
第 4 层之后的分支应显示为“第 5 层的两个节点”
而不是“第 5 层 / 第 6 层”
```

## Python 参考项目依据

Python 参考项目的地图模型不是简单楼层跳转。

其核心语义是：

```text
MapData.nodes 是二维节点数组
每个 MapNode 位于某一 floor 和 position
每个节点通过 connections_up 连接到下一层的若干节点
玩家选择的是下一层中的某个可达节点
```

`MapManager._generate_nodes_with_connections()` 会在相邻楼层之间创建连接：

```text
current_floor_nodes
→ next_floor_nodes
```

`get_available_moves()` 使用：

```text
next_floor = current_floor + 1
for pos in current_node.connections_up:
    available_nodes.append(get_node(next_floor, pos))
```

也就是说，Python 项目的地图选择语义是：

```text
当前节点
→ 下一层可达节点 A / B / C
```

不是：

```text
当前房间
→ 任意目标楼层
```

Godot 本阶段应吸收这个核心结构，但不做完整随机地图生成。

## 要解决的问题

当前 Godot 地图数据在：

```text
scripts/stm/map/map_data.gd
```

当前结构是：

```text
floors[i]["rooms"][j]["next_floors"] = Array[int]
```

这导致第 4 层休息房可直接指向第 5 层或第 6 层：

```text
第 4 层 rest → [4, 5]
第 5 层 combat → [5]
第 6 层 rest → [6]
第 7 层 boss
```

这种结构无法表达：

```text
第 5 层同时有两个可选节点
两个节点再汇合到第 6 层
```

因此需要改成节点级连接。

## 目标

### 玩家目标

玩家完成第 4 层休息房后，应看到：

```text
→ 第 5 层 战斗房间
→ 第 5 层 休息房间
```

玩家选择其中一个后：

```text
如果选择第 5 层 战斗房间：进入第 5 层 combat，胜利并处理奖励后前往第 6 层。
如果选择第 5 层 休息房间：进入第 5 层 rest，选择休息/跳过后前往第 6 层。
```

第 6 层作为汇合层：

```text
第 6 层 战斗房间 或 休息房间
→ 第 7 层 Boss
```

本阶段建议固定为：

```text
第 6 层 rest
```

这样保留当前短路径体验。

### 工程目标

新增节点选择概念：

```text
current_node_position
next_nodes
node_position
```

但仍保留固定地图，不做随机地图生成。

地图最小结构建议：

```gdscript
const FLOORS := [
    {
        "name": "第 1 层",
        "nodes": [
            {"type": "combat", "next_nodes": [{"floor_index": 1, "node_index": 0}]}
        ]
    },
    ...
]
```

第 4 / 第 5 / 第 6 / 第 7 层建议：

```text
第 4 层 node 0 rest
→ 第 5 层 node 0 combat
→ 第 5 层 node 1 rest

第 5 层 node 0 combat
→ 第 6 层 node 0 rest

第 5 层 node 1 rest
→ 第 6 层 node 0 rest

第 6 层 node 0 rest
→ 第 7 层 node 0 boss
```

## 非目标

本阶段明确不做：

```text
完整随机地图生成
Python MapManager 全量迁移
地图节点坐标绘制
地图连线可视化
正式地图 UI
多 act 地图
事件房 / 商店房 / 精英房完整系统
地图种子
路径交叉检测
房间权重生成
Boss 宝箱 / Act 过渡
will / mind / 意愿牌 / 思维牌桌
修改 Python 参考项目
```

本阶段也不修改：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) bool 语义
card_reward 规则
rest_choice 规则
Boss 胜利通关规则
```

## 核心设计原则

### 1. 地图选择必须是“下一层节点选择”

从当前节点获得下一步时，只允许返回：

```text
next_nodes 中列出的节点
```

正常主流程不允许：

```text
跳过中间层
选择非下一层节点
直接输入任意 floor_index
```

### 2. GameFlow 不直接理解地图结构细节

`StmGameFlow` 应继续只问 `StmMapManager`：

```text
当前楼层
当前房间类型
可用下一节点选项
导航到下一节点
```

具体 `current_node_index`、`next_nodes`、节点显示名由 `StmMapManager` 处理。

### 3. BattleDebugScene 显示节点选项，但不维护地图状态

UI 可以显示：

```text
→ 第 5 层 战斗房间
→ 第 5 层 休息房间
```

点击后只调用：

```gdscript
game_flow.advance_to_next_floor(floor_index, node_index)
```

或等价方法。

UI 不应：

```text
自行修改 current_floor_index
自行修改 current_node_index
绕过 MapManager
```

### 4. 保持旧测试路径可读

测试可以继续使用 floor_index 定位，但需要增加 node_index。

调试入口建议改为：

```gdscript
debug_navigate_to_node_for_test(floor_index, node_index = 0)
```

旧的：

```gdscript
debug_navigate_to_floor_for_test(floor_index)
```

可以保留为兼容方法，默认进入 node 0。

## 数据结构设计

### MapData

当前：

```gdscript
{
    "name": "第 4 层",
    "rooms": [
        {"type": "rest", "next_floors": [4, 5]}
    ]
}
```

目标：

```gdscript
{
    "name": "第 4 层",
    "nodes": [
        {
            "type": "rest",
            "next_nodes": [
                {"floor_index": 4, "node_index": 0},
                {"floor_index": 4, "node_index": 1}
            ]
        }
    ]
}
```

### MapManager 状态

新增：

```gdscript
var _current_node_index: int = 0
```

保留：

```gdscript
var _current_floor_index: int = 0
```

新增 / 修改方法建议：

```gdscript
func get_current_node_index() -> int
func get_current_node_info() -> Dictionary
func get_available_room_types() -> Array
func get_available_next_nodes() -> Array
func can_navigate_to_next_node(floor_index: int, node_index: int) -> bool
func navigate_to_node(floor_index: int, node_index: int) -> bool
func navigate_to_next_node(floor_index: int, node_index: int) -> bool
```

兼容保留：

```gdscript
func get_available_next_floors() -> Array
func can_navigate_to_next_floor(floor_index: int) -> bool
func navigate_to_next_floor(floor_index: int) -> bool
func navigate_to_floor(floor_index: int) -> bool
```

但兼容方法应有明确语义：

```text
只用于旧测试或 debug 默认 node 0
主流程应逐步迁移到 node 方法
```

## 固定地图建议

为了保证路线直观，本阶段固定地图为 7 层：

```text
第 1 层
  node 0 combat → 第 2 层 node 0

第 2 层
  node 0 combat → 第 3 层 node 0

第 3 层
  node 0 combat → 第 4 层 node 0

第 4 层
  node 0 rest → 第 5 层 node 0 / 第 5 层 node 1

第 5 层
  node 0 combat → 第 6 层 node 0
  node 1 rest   → 第 6 层 node 0

第 6 层
  node 0 rest → 第 7 层 node 0

第 7 层
  node 0 boss → none
```

玩家看到的关键分支：

```text
第 4 层休息完成后：
→ 第 5 层 战斗房间
→ 第 5 层 休息房间
```

这更接近 Python 参考项目中的下一层节点选择。

## GameFlow 接入设计

修改文件：

```text
scripts/stm/engine/game_flow.gd
```

新增或调整：

```gdscript
func get_current_node_index() -> int
func get_available_next_nodes() -> Array
func advance_to_next_node(floor_index: int, node_index: int) -> bool
```

保留兼容：

```gdscript
func get_available_next_floors() -> Array
func advance_to_next_floor(floor_index: int) -> bool
func debug_navigate_to_floor_for_test(floor_index: int) -> bool
```

兼容 `advance_to_next_floor(floor_index)` 可以选择该 floor 的第一个可达 node：

```text
如果多个可达节点属于同一 floor，则选择第一个。
```

但 DebugScene 新按钮应使用 node 精确导航，避免同层多个节点歧义。

## BattleDebugScene 接入设计

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

当前下一层按钮使用：

```gdscript
_on_next_floor_selected(floor_index)
```

本阶段应改为：

```gdscript
_on_next_node_selected(floor_index, node_index)
```

按钮显示建议：

```text
→ 第 5 层 战斗房间
→ 第 5 层 休息房间
```

如果只有一个节点，显示仍可为：

```text
→ 第 2 层 战斗房间
```

## 测试验收

### MapManager 验收

新增或更新测试：

```text
scripts/stm/tests/test_map.gd
```

验收点：

1. 初始位置为第 1 层 node 0。
2. 第 4 层 node 0 完成后，可用下一节点为第 5 层 node 0 和第 5 层 node 1。
3. 两个可用节点都属于第 5 层。
4. 第 5 层 node 0 是 combat。
5. 第 5 层 node 1 是 rest。
6. 选择第 5 层 node 0 后，下一步只能到第 6 层 node 0。
7. 选择第 5 层 node 1 后，下一步也只能到第 6 层 node 0。
8. 不允许从第 4 层直接导航到第 6 层 node 0。

### GameFlow 验收

新增或更新测试：

```text
scripts/stm/tests/test_game_flow.gd
```

验收点：

1. 第 4 层休息完成后，`get_available_next_nodes()` 返回两个第 5 层节点。
2. 选择第 5 层 combat 分支后，必须完成第 5 层 combat，之后才到第 6 层。
3. 选择第 5 层 rest 分支后，必须完成第 5 层 rest，之后才到第 6 层。
4. 两条分支都能汇合到第 6 层。
5. 第 6 层完成后进入 Boss。
6. 旧的短路径测试不应再写成“第 4 层直接跳第 6 层”。

### DebugScene UI 验收

新增或更新测试：

```text
scripts/stm/tests/test_battle_debug_scene.gd
```

或新增：

```text
scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
```

验收点：

1. 第 4 层休息选择完成后，地图显示两个下一节点按钮。
2. 两个按钮都显示“第 5 层”。
3. 一个按钮包含“战斗房间”。
4. 一个按钮包含“休息房间”。
5. 点击战斗分支后进入第 5 层 combat。
6. 点击休息分支后进入第 5 层 rest。
7. 不显示“第 6 层”作为第 4 层后的直接选项。

## 安全 / 边界 / 依赖自检

### 安全自检

检查项：

- 不修改 `project.godot`。
- 不新增插件。
- 不新增 autoload。
- 不引入网络、文件下载、第三方库。
- 不修改 Python 参考项目。
- 不恢复 will / mind / 意愿牌 / 思维牌桌 / 本能牌原型。
- 不新增完整随机地图系统。
- 不新增完整正式地图 UI。
- 不修改 `StmTypes.TerminalResult`。
- 不修改 `StmCard.can_play(game_state)` bool 语义。
- 测试 deterministic，不依赖随机数、时间或人工点击。

结论：通过。v1 只把固定测试地图升级为节点图。

### 边界自检

本阶段只做：

```text
固定地图节点化
下一层节点选择
第 4 层后显示两个第 5 层节点
GameFlow 支持 node_index
DebugScene 按节点导航
BDD / TDD 测试
```

本阶段不做：

```text
随机地图生成
地图连线绘制
正式地图 UI
事件房 / 商店房 / 精英房完整系统
完整 Python MapManager 迁移
```

结论：通过。功能边界聚焦于“固定地图结构纠错”。

### 依赖自检

必须复用：

- `StmMapData`
- `StmMapManager`
- `StmGameFlow`
- `StmBattleDebugScene`
- `StmRestRoom`
- `StmCombatRoom`
- `StmBossRoom`
- 现有 GUT 测试体系

不得新增：

- 第二套 GameFlow
- 第二套 MapManager
- 第二套 DebugScene 地图状态
- 第二套房间完成系统

结论：通过。

## 风险提示

1. 当前很多测试只用 `floor_index`，节点化后要兼容或逐步更新。
2. `advance_to_next_floor(floor_index)` 在同一 floor 有多个 node 时存在歧义，DebugScene 应优先使用新 `advance_to_next_node()`。
3. `get_available_room_types()` 过去返回当前楼层所有房间类型；节点化后应返回当前节点的单个 room type，或明确只用于当前节点。
4. `debug_navigate_to_floor_for_test()` 默认 node 0，不能用于测试第 5 层 node 1；需要新增 `debug_navigate_to_node_for_test()`。
5. 旧短路径测试必须更新，不应再认为第 4 层能直接跳到第 6 层。
6. 地图 UI 文案必须显示 node 的 room type，否则两个“第 5 层”按钮会看起来重复。

## 下一步

规格确认后，再写实施计划：

```text
docs/superpowers/plans/2026-05-30-sts2-fixed-map-node-branch-v1.md
```

计划必须逐步写清：

```text
新增/修改哪些测试
修改哪个文件
新增哪些字段/方法
旧兼容方法如何处理
每一步不允许改什么
对应完成标准
计划歧义自检
```

在计划确认前，不进入实现阶段。
