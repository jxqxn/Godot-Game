# Cards / Godot-Game

这是一个基于 Godot 的卡牌战斗原型项目，当前主线围绕 STS2 复刻方向推进：固定地图节点、房间流程、战斗主干、选择系统、运行时架构边界，以及战斗调试工具。

## 当前项目定位

项目目标是构建一个可测试、可迭代的卡牌战斗主干。当前重点不是扩展复杂叙事或心理系统，而是先稳定以下核心闭环：

```text
固定地图节点图
→ 进入房间
→ 战斗 / 休息 / Boss 流程
→ 抽牌、出牌、结算行动队列
→ 战斗胜利后选择奖励
→ 休息房选择行动
→ 地图节点推进
→ Boss 胜利通关
```

当前已经完成并验证：

```text
手牌优先级排序与自动出牌 v1
自动出牌预览与不可打原因展示 v1.1
card_reward 战斗奖励选择
rest_choice 休息房选择
固定地图节点分支 v1
Core Runtime Architecture Spine v1
```

Core Runtime Architecture Spine v1 已建立以下长期边界：

```text
StmChoiceResolver     处理 card_reward / rest_choice 等选择规则
StmMapNode            表示地图节点与 next_nodes
StmRoomFactory        根据 MapNode 创建 Combat / Rest / Boss 房间
StmEncounterFactory   根据 encounter_id 创建 debug_dummy / boss_dummy 遭遇
```

这些边界的目标是让后续新增 EventRoom、Smith、精英房、地图 UI、第二种敌人时，不需要反复重写 `GameState`、`GameFlow`、`MapManager` 或 `BattleDebugScene` 的职责。

## 运行入口

Godot 工程入口：

```text
project.godot
```

当前主场景：

```text
res://scenes/stm/battle_debug_scene.tscn
```

在 Godot 编辑器中打开项目后，可以直接运行主场景进入战斗调试工具。

## 测试

当前项目使用 GUT 测试。推荐在项目根目录执行：

```bash
godot -s addons/gut/gut_cmdln.gd
```

当前 `.gutconfig.json` 已覆盖 24 个测试脚本，包括：

```text
core_skeleton_test.gd
test_battle_debug_scene.gd
test_fixed_battle_fixture.gd
test_powers_v1.gd
test_map.gd
test_rooms.gd
test_game_flow.gd
test_card_priority_autoplay_v1.gd
test_battle_debug_priority_autoplay_v1.gd
test_combat_can_play_guard.gd
test_autoplay_preview_v1_1.gd
test_battle_debug_autoplay_preview_v1_1.gd
test_choice_request_v1.gd
test_combat_card_reward_choice_v1.gd
test_battle_debug_choice_reward_v1.gd
test_rest_choice_v1.gd
test_battle_debug_rest_choice_v1.gd
test_fixed_map_node_branch_v1.gd
test_game_flow_node_branch_v1.gd
test_battle_debug_map_node_branch_v1.gd
test_choice_resolver_v1.gd
test_map_node_v1.gd
test_room_factory_v1.gd
test_encounter_factory_v1.gd
```

2026-05-30：人工确认完整 GUT 通过。

```text
Scripts: 24
Tests: 187
Passing Tests: 187
Asserts: 880
```

后续每次变更合并前应重新运行完整测试。

## 当前主线文档

当前最新规格文档：

```text
docs/superpowers/specs/2026-05-30-sts2-core-runtime-architecture-spine-v1-design.md
```

当前最新实施计划：

```text
docs/superpowers/plans/2026-05-30-sts2-core-runtime-architecture-spine-v1.md
```

较早阶段文档仍保留在 `docs/superpowers/` 中，用于追溯 card priority、autoplay preview、choice reward、rest choice、fixed map node branch 等阶段。

## 关键代码区域

```text
scripts/stm/cards/          卡牌定义与测试卡
scripts/stm/player/         玩家与卡牌管理器
scripts/stm/actions/        战斗行动与 ActionQueue
scripts/stm/engine/         Combat / GameState / GameFlow 主干
scripts/stm/choices/        ChoiceRequest / ChoiceOption / ChoiceResolver
scripts/stm/map/            MapData / MapNode / MapManager
scripts/stm/rooms/          BaseRoom / CombatRoom / RestRoom / BossRoom / RoomFactory
scripts/stm/encounters/     EncounterFactory 与固定遭遇创建
scripts/stm/debug/          战斗调试场景与固定测试夹具
scripts/stm/tests/          GUT 测试
```

## 当前架构职责

```text
StmGameState
→ 保存玩家、当前战斗、当前选择请求、ActionQueue 等运行时状态
→ 提供 submit_choice() 公共入口，但不直接实现具体选择规则

StmChoiceResolver
→ 解析 card_reward / rest_choice
→ 后续 event_choice / smith_choice 应优先接入这里

StmMapManager
→ 维护当前 floor_index / node_index
→ 只负责地图位置与可达节点，不创建房间、不结算房间

StmMapNode
→ 表示地图节点、房间类型、room_payload、next_nodes

StmGameFlow
→ 负责进入房间、完成房间、推进节点、Boss 通关判断
→ 通过 RoomFactory 创建房间

StmRoomFactory
→ 根据 MapNode.room_type 创建 CombatRoom / RestRoom / BossRoom

StmEncounterFactory
→ 根据 encounter_id 创建 debug_dummy / boss_dummy 等战斗遭遇

BattleDebugScene
→ 只负责显示状态和提交玩家操作，不直接维护地图/房间规则
```

## 协作规则文档

当前仓库根目录存在：

```text
AGENT.md
```

该文件记录了中文思维规则、BDD 要求和完整 GUT 命令。后续建议把它扩展为更完整的协作规则文档，并考虑改名为更通用的：

```text
AGENTS.md
```

## 开发红线

当前阶段不要恢复或新增以下旧原型体系：

```text
will/
mind/
意愿牌
本能牌
思维牌桌
人格痕迹
扶植 / 压制
独立 will_debug_scene
```

新功能应优先复用现有主干：

```text
StmCard
StmCardManager
StmCombat
StmGameState
StmChoiceResolver
StmMapNode
StmMapManager
StmGameFlow
StmRoomFactory
StmEncounterFactory
StmCombatActions.PlayCardAction
ActionQueue / add_action / drive_actions
现有 GUT 测试配置
```

不要新增平行手牌系统、平行行动队列、平行地图管理器或平行战斗结算逻辑。

## 建议的下一步

在进入新玩法前，建议先完成文档同步：

```text
更新 / 扩展 AGENT.md 或重命名为 AGENTS.md
新增 Core Runtime Architecture Spine v1 status 文档
```

之后建议推进一个很小的内容验证阶段：

```text
STS2 EventRoom v1
```

目标是用一个简单事件房验证当前架构边界：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom 发出 event_choice
→ ChoiceResolver 结算事件选择
→ GameFlow 完成房间并返回地图
```

第一版事件房应保持极小，不引入随机事件系统、商店、遗物或正式地图 UI。
