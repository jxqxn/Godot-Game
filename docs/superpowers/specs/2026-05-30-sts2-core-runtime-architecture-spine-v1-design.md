# STS2 Core Runtime Architecture Spine v1 设计

## 当前定位

本规格是 `STS2 固定地图节点分支 v1` 之后的主干架构定型阶段。

当前 Godot 主干已经具备：

```text
固定地图节点图
MapManager 节点可达性
GameFlow 节点推进
CombatRoom / RestRoom / BossRoom
战斗胜利 card_reward
休息房 rest_choice
BattleDebugScene 可完整跑通固定测试流程
完整 GUT 通过
```

但当前系统已经出现几个后续必然会扩大的压力点：

```text
GameState.submit_choice 开始承担所有选择规则
CombatRoom 直接绑定 debug fixture
MapData 虽然节点化但仍是裸 Dictionary
GameFlow 直接 new 不同 Room 类型
BattleDebugScene 继续承担大量 UI 与流程胶水
```

本阶段目标不是新增玩法内容，而是在不改变玩家可见功能的前提下，把后续事件房、Smith、精英房、地图 UI、第二种敌人等都需要依赖的长期边界先确立起来。

本阶段命名为：

```text
STS2 Core Runtime Architecture Spine v1
```

核心目标：

```text
让当前已经跑通的地图 / 房间 / 选择 / 战斗流程拥有稳定主干接口
后续新增内容时不需要反复搬 GameState、GameFlow、MapManager、DebugScene 的职责
```

## Python 参考项目依据

Python 参考项目不是把所有规则直接写进 GameState 或 UI，而是更接近以下结构：

```text
MapManager 管理地图与可用移动
Action / InputRequest 负责将玩家选择转为动作
Room / Event / Combat 通过动作或请求推进流程
GameState 保存运行状态
```

地图方面，Python 项目先生成楼层结构，再生成节点连接，再分配房间类型，最后存入 `map_data.nodes`。Godot 目前已经吸收了“当前节点 → 下一层可达节点”的核心语义，但还没有正式 MapNode 对象。

选择方面，Python 项目会通过 InputRequest / Option actions 把“给玩家一个选择”和“选择后执行动作”分开。Godot 目前已有 ChoiceRequest，但 `GameState.submit_choice()` 仍直接写具体 request_type 规则。

本阶段不完整迁移 Python 架构，只吸收它的长期边界：

```text
状态保存者不要变成所有规则的实现者
地图节点应是明确模型，不只是散落 Dictionary
房间创建应有工厂边界
战斗遭遇配置应与 CombatRoom 解耦
UI 只显示状态并提交命令，不直接维护地图/房间规则
```

## 要解决的问题

### 问题 1：GameState 选择规则膨胀

当前 `StmGameState.submit_choice()` 已处理：

```text
card_reward
rest_choice
```

如果继续加入：

```text
event_choice
smith_choice
upgrade_card_choice
remove_card_choice
shop_choice
relic_choice
```

GameState 会变成选择规则大杂烩。

需要把选择解析逻辑移出 GameState，建立：

```text
StmChoiceResolver
```

GameState 保留统一入口，但不再持有每种选择的具体规则。

### 问题 2：CombatRoom 绑定 FixedBattleFixture

当前 CombatRoom 直接使用 debug fixture 创建敌人和固定牌组。这对测试主干有效，但长期会阻碍：

```text
不同敌人
精英房
Boss 配置
地图节点决定遭遇
战斗奖励表
```

需要建立：

```text
StmEncounterFactory
```

CombatRoom 接收 room payload / encounter id，再由 EncounterFactory 创建敌人组合。

### 问题 3：MapData 节点仍是裸 Dictionary

当前 MapData 已从 `rooms / next_floors` 改成 `nodes / next_nodes`，但 node 仍是 Dictionary。

短期可用，长期会影响：

```text
地图 UI 坐标
节点显示名
节点是否可见 / 已走过
room_payload
事件/商店/精英节点扩展
```

需要建立轻量：

```text
StmMapNode
```

但本阶段不做随机地图生成。

### 问题 4：GameFlow 直接创建 Room

当前 GameFlow 根据 room_type 直接 new CombatRoom / RestRoom / BossRoom。

后续加入 event / shop / elite / treasure 时，GameFlow 会继续膨胀。

需要建立：

```text
StmRoomFactory
```

GameFlow 只问 RoomFactory：

```text
根据当前 MapNode 创建 Room
```

### 问题 5：DebugScene 已经承担过多 UI 胶水

当前 BattleDebugScene 同时负责地图显示、战斗显示、ChoicePanel、日志、数值编辑、自动出牌预览和按钮行为。

本阶段不拆正式 UI，但必须保持一个原则：

```text
DebugScene 不新增规则职责
DebugScene 不直接改 MapManager / Room / HP / Deck
DebugScene 只调用 GameFlow / GameState 的稳定入口
```

后续可在 UI 增长时再做局部拆分。

## 目标

本阶段玩家可见功能保持不变。

玩家仍然看到：

```text
地图节点选择
战斗房间
奖励卡选择
休息房选择
Boss 胜利通关
```

本阶段工程目标是新增长期边界：

```text
StmChoiceResolver
StmMapNode
StmRoomFactory
StmEncounterFactory
```

并把现有规则迁移到这些边界上。

## 非目标

本阶段明确不做：

```text
新增事件房内容
新增 Smith / 升级牌
新增删牌 / 商店 / 遗物
新增精英房
新增第二种敌人玩法表现
完整随机地图生成
地图连线绘制
正式地图 UI
完整 MessageBus
完整 RuntimePresenter
完整 InputRequest / InputSubmission 框架
完整 Python 架构迁移
多 act
Boss 宝箱 / Act 过渡
will / mind / 意愿牌 / 思维牌桌
修改 Python 参考项目
```

本阶段也不修改：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) bool 语义
card_reward 玩家可见结果
rest_choice 玩家可见结果
Boss 胜利通关规则
当前固定地图可见路径
BattleDebugScene 当前主要交互
```

## 核心设计原则

### 1. 玩家可见行为不变

这是纯架构定型阶段。

通过前后，以下行为必须一致：

```text
战斗胜利后出现 card_reward
奖励选择后房间完成
休息房进入后出现 rest_choice
休息/跳过后房间完成
第 4 层后显示两个第 5 层节点
Boss 战胜利后通关
```

### 2. GameState 只保存状态和统一入口

GameState 可以继续提供：

```gdscript
submit_choice(option_id)
set_choice_request(request)
clear_choice_request()
has_choice_request()
add_action(action)
drive_actions()
```

但不应该继续新增：

```text
_resolve_event_choice
_resolve_smith_choice
_resolve_upgrade_card_choice
```

本阶段将现有：

```text
_resolve_card_reward_choice
_resolve_rest_choice
```

迁移到 ChoiceResolver。

### 3. ChoiceResolver 负责选择规则

新增文件：

```text
scripts/stm/choices/choice_resolver.gd
```

职责：

```gdscript
func resolve(game_state, request, option) -> Dictionary
```

内部可保留：

```gdscript
_resolve_card_reward_choice(game_state, request, option)
_resolve_rest_choice(game_state, request, option)
```

短期仍可直接执行结果，长期可逐步把选择结果转为 actions。

### 4. MapNode 是地图节点模型

新增文件：

```text
scripts/stm/map/map_node.gd
```

字段建议：

```gdscript
var floor_index: int
var node_index: int
var room_type: String
var room_payload: Dictionary
var next_nodes: Array
```

方法建议：

```gdscript
func to_option(floor_name: String) -> Dictionary
func display_room_name() -> String
func has_next_node(floor_index: int, node_index: int) -> bool
```

本阶段可以让 MapData 仍保留 Dictionary 常量，但 MapManager 对外尽量通过 MapNode 风格接口工作。

### 5. RoomFactory 创建房间

新增文件：

```text
scripts/stm/rooms/room_factory.gd
```

职责：

```gdscript
func create_room(map_node)
```

根据 `map_node.room_type` 创建：

```text
combat → StmCombatRoom
rest → StmRestRoom
boss → StmBossRoom
```

未来可接：

```text
event
shop
elite
treasure
```

GameFlow 不再直接 match room_type new 房间。

### 6. EncounterFactory 创建战斗遭遇

新增文件：

```text
scripts/stm/encounters/encounter_factory.gd
```

职责：

```gdscript
func create_encounter(encounter_id: String) -> Dictionary
```

返回示例：

```gdscript
{
    "enemies": [enemy],
    "combat_type": "debug"
}
```

本阶段先支持：

```text
debug_dummy
boss_dummy
```

CombatRoom 使用 room_payload 中的 encounter_id 调用 EncounterFactory。

### 7. DebugScene 不直接依赖新细节

DebugScene 不需要知道：

```text
ChoiceResolver
RoomFactory
EncounterFactory
MapNode 内部结构
```

它仍然只调用：

```text
game_flow.enter_current_room()
game_flow.advance_to_next_node(floor_index, node_index)
game_state.submit_choice(option_id)
combat.play_card(...)
```

## 目标结构

建议形成：

```text
scripts/stm/
  engine/
    game_state.gd
    game_flow.gd
    action_queue.gd
    combat.gd

  choices/
    choice_request.gd
    choice_option.gd
    choice_resolver.gd

  map/
    map_data.gd
    map_node.gd
    map_manager.gd

  rooms/
    base.gd
    combat.gd
    rest.gd
    boss_room.gd
    room_factory.gd

  encounters/
    encounter_factory.gd

  debug/
    battle_debug_scene.gd
```

## 测试验收

本阶段应以“行为不变”为核心验收。

### ChoiceResolver 验收

新增测试：

```text
scripts/stm/tests/test_choice_resolver_v1.gd
```

验收点：

1. `GameState.submit_choice()` 对 card_reward 的外部行为不变。
2. `GameState.submit_choice()` 对 rest_choice 的外部行为不变。
3. Unsupported request_type 仍返回失败结果。
4. GameState 不再直接包含具体 choice resolver 方法，或测试只通过公共入口验证行为。

### MapNode 验收

新增测试：

```text
scripts/stm/tests/test_map_node_v1.gd
```

验收点：

1. MapNode 能保存 floor_index / node_index / room_type / next_nodes。
2. MapNode 能生成包含 floor_index / node_index / room_type / room_name 的 option。
3. MapManager 的 `get_available_next_nodes()` 行为不变。
4. 第 4 层后仍返回两个第 5 层节点。

### RoomFactory 验收

新增测试：

```text
scripts/stm/tests/test_room_factory_v1.gd
```

验收点：

1. combat node 创建 CombatRoom。
2. rest node 创建 RestRoom。
3. boss node 创建 BossRoom。
4. unknown room_type 返回 null 或失败，不抛运行时错误。
5. GameFlow 通过 RoomFactory 进入当前房间，旧 GameFlow 行为保持不变。

### EncounterFactory 验收

新增测试：

```text
scripts/stm/tests/test_encounter_factory_v1.gd
```

验收点：

1. `debug_dummy` 创建 DummyEnemy 战斗配置。
2. `boss_dummy` 创建 BossEnemy 战斗配置。
3. CombatRoom 可以从 payload 获取 encounter_id 并启动战斗。
4. 现有 combat room 测试继续通过。
5. Boss room 测试继续通过。

### 回归验收

完整 GUT 必须继续通过：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

关键回归：

```text
card_reward 不变
rest_choice 不变
fixed map node branch 不变
BattleDebugScene 仍可操作
Boss 胜利通关不变
```

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
- 不新增正式地图 UI。
- 不修改 `StmTypes.TerminalResult`。
- 不修改 `StmCard.can_play(game_state)` bool 语义。
- 测试 deterministic，不依赖随机数、时间或人工点击。

结论：通过。

### 边界自检

本阶段只做：

```text
ChoiceResolver 边界
MapNode 边界
RoomFactory 边界
EncounterFactory 边界
现有行为迁移到这些边界
旧功能回归测试保持通过
```

本阶段不做：

```text
新增玩法内容
事件房
Smith
商店
遗物
正式 UI
随机地图
完整 Python 架构迁移
```

结论：通过。

### 依赖自检

必须复用：

```text
StmGameState
StmGameFlow
StmMapManager
StmMapData
StmCombatRoom
StmRestRoom
StmBossRoom
StmChoiceRequest
StmChoiceOption
StmCombat
现有 GUT 测试体系
```

不得新增：

```text
第二套 GameState
第二套 GameFlow
第二套 MapManager
第二套 ChoiceRequest
第二套 DebugScene 运行时
```

结论：通过。

## 风险提示

1. 这是架构定型阶段，必须强制玩家可见行为不变。
2. 不要借 RoomFactory 顺手新增 EventRoom。
3. 不要借 EncounterFactory 顺手新增随机敌人。
4. 不要借 MapNode 顺手做地图 UI 坐标和连线。
5. 不要借 ChoiceResolver 顺手做完整 InputRequestAction。
6. 每一步迁移后必须跑现有相关测试，防止“纯重构”破坏主干。

## 下一步

规格确认后，写实施计划：

```text
docs/superpowers/plans/2026-05-30-sts2-core-runtime-architecture-spine-v1.md
```

计划必须拆清：

```text
先写 ChoiceResolver 测试，再迁移 GameState
先写 MapNode 测试，再调整 MapManager
先写 RoomFactory 测试，再调整 GameFlow
先写 EncounterFactory 测试，再调整 CombatRoom / BossRoom
最后更新 GUT 配置并完整验证
```

在计划确认前，不进入代码实现。
