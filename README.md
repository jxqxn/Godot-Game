# Cards / Godot-Game

这是一个基于 Godot 的卡牌战斗原型项目，当前主线围绕 STS2 复刻方向推进：固定地图节点、房间流程、战斗主干、选择系统、运行时架构边界，以及战斗调试工具。

## 当前项目定位

项目目标是构建一个可测试、可迭代的卡牌战斗主干。当前重点不是扩展复杂叙事或心理系统，而是先稳定以下核心闭环：

```text
固定地图节点图
→ 进入房间
→ 战斗 / 休息 / 事件 / Boss 流程
→ 抽牌、出牌、结算行动队列
→ 战斗胜利后选择奖励
→ 休息房选择行动
→ 事件房选择行动
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
STS2 EventRoom v1
STS2 Fixed Map Event Node v1
```

当前默认固定地图已经包含一个事件分支：

```text
第 4 层 rest
→ 第 5 层 node 0 combat
→ 第 5 层 node 1 event(debug_fountain)
→ 第 6 层 rest
→ 第 7 层 boss
```

Core Runtime Architecture Spine v1 之后，EventRoom v1 和默认地图事件节点已验证以下长期边界：

```text
StmChoiceResolver     处理 card_reward / rest_choice / event_choice 等选择规则
StmMapNode            表示地图节点、room_payload、next_nodes
StmRoomFactory        根据 MapNode 创建 Combat / Rest / Event / Boss 房间
StmEncounterFactory   根据 encounter_id 创建 debug_dummy / boss_dummy 遭遇
StmGameFlow           通过 RoomFactory 进入房间，并在房间完成后推进地图节点
BattleDebugScene      显示状态并提交玩家操作，不直接维护事件规则
```

这些边界的目标是让后续新增 Smith、精英房、地图 UI、第二种敌人时，不需要反复重写 `GameState`、`GameFlow`、`MapManager` 或 `BattleDebugScene` 的职责。

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

当前 `.gutconfig.json` 已覆盖 31 个测试脚本，包括：

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
test_event_room_v1.gd
test_pressure_encounter_v1.gd
test_pressure_encounter_v1_1.gd
test_choice_resolver_event_choice_v1.gd
test_game_flow_event_room_v1.gd
test_battle_debug_event_choice_v1.gd
test_battle_debug_pressure_encounter_v1.gd
```

2026-06-06：完整 GUT 通过，并已清理退出时的 ObjectDB / resources still in use 警告。

```text
Scripts: 31
Tests: 234
Passing Tests: 234
Asserts: 1179
```

本次完整 GUT 以 `All tests passed` 和退出码 0 结束，未再出现 ObjectDB / resources still in use 警告。

后续每次变更合并前应重新运行完整测试。

## 当前主线文档

当前最新规格文档：

```text
docs/superpowers/specs/2026-06-06-pressure-encounter-v1-1-quality-review.md
```

当前最新实施计划：

```text
docs/superpowers/plans/2026-06-06-pressure-encounter-v1-1-plan.md
```

当前最新状态记录：

```text
docs/superpowers/status/2026-06-06-pressure-encounter-v1-1-status.md
```

较早阶段文档仍保留在 `docs/superpowers/` 中，用于追溯 card priority、autoplay preview、choice reward、rest choice、fixed map node branch、core runtime architecture spine、event room 等阶段。

## 参考材料

用于后续机制抽象与外部案例迭代的参考文档位于：

```text
docs/references/disco-gunfight-cardification/README.md
```

该目录中的文档不是当前 Godot 项目的正式开发规格。若要把其中机制转入本项目，应先另写 `docs/superpowers/specs/` 与 `docs/superpowers/plans/`。

## 关键代码区域

```text
scripts/stm/cards/          卡牌定义与测试卡
scripts/stm/player/         玩家与卡牌管理器
scripts/stm/actions/        战斗行动与 ActionQueue
scripts/stm/engine/         Combat / GameState / GameFlow 主干
scripts/stm/choices/        ChoiceRequest / ChoiceOption / ChoiceResolver
scripts/stm/map/            MapData / MapNode / MapManager
scripts/stm/rooms/          BaseRoom / CombatRoom / RestRoom / EventRoom / BossRoom / RoomFactory
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
→ 解析 card_reward / rest_choice / event_choice
→ 后续 smith_choice 等新选择应优先接入这里

StmMapManager
→ 维护当前 floor_index / node_index
→ 只负责地图位置与可达节点，不创建房间、不结算房间
→ 允许 GUT 通过 debug_set_floors_for_test() 注入最小测试地图

StmMapNode
→ 表示地图节点、房间类型、room_payload、next_nodes

StmGameFlow
→ 负责进入房间、完成房间、推进节点、Boss 通关判断
→ 通过 RoomFactory 创建房间
→ 允许 GUT 通过 debug_set_map_floors_for_test() 注入最小测试地图

StmRoomFactory
→ 根据 MapNode.room_type 创建 CombatRoom / RestRoom / EventRoom / BossRoom

StmEventRoom
→ 进入房间时创建 event_choice
→ 不直接修改 HP / Deck / MapManager / GameFlow

StmEncounterFactory
→ 根据 encounter_id 创建 debug_dummy / boss_dummy 等战斗遭遇

BattleDebugScene
→ 只负责显示状态和提交玩家操作，不直接维护地图/房间/事件规则
```

## 协作规则文档

当前仓库根目录存在：

```text
AGENTS.md
```

该文件记录项目协作规则、BDD/TDD 流程、架构边界、开发红线和完整 GUT 命令。后续开发前应先阅读 `AGENTS.md`。

## Codex 协作复用入口

后续新对话中，如果 Codex 已安装本地 skill，可优先调用：

```text
godot-sts-card-prototype
```

该 skill 只负责快速进入项目流程，不替代 `AGENTS.md` / `README.md` / 最新 status 文档。

新功能或结构性重构开工前，可使用：

```text
docs/superpowers/prompts/new-feature-intake.md
```

阶段完成后，可复制以下模板生成新的 status 记录：

```text
docs/superpowers/templates/status-template.md
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

默认地图事件节点已经接入并通过完整 GUT。下一步建议不要立刻扩大事件系统，而是在以下方向中选择一个小步推进：

```text
1. 新增 Smith / upgrade 选择作为第二种非战斗选择类型。
2. 新增第二个固定事件，但仍不引入随机事件池或 EventFactory。
3. 为自有创新卡牌机制先拆出一个最小规格切片。
```

如果推进新的选择类型，应继续复用：

```text
Room → ChoiceRequest → GameState.submit_choice() → ChoiceResolver → GameFlow
```
