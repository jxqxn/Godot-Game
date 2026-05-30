# STS2 Core Runtime Architecture Spine v1 状态记录

## 对应规格与计划

```text
docs/superpowers/specs/2026-05-30-sts2-core-runtime-architecture-spine-v1-design.md
docs/superpowers/plans/2026-05-30-sts2-core-runtime-architecture-spine-v1.md
```

## 当前阶段结论

Core Runtime Architecture Spine v1 已完成。

本阶段是一次行为不变的架构定型，目标不是新增玩家可见玩法，而是把已经验证过的选择、地图、房间与遭遇创建逻辑迁移到更稳定的运行时边界上。

## 完成内容

已完成并验证以下主干边界：

```text
StmChoiceResolver     处理 card_reward / rest_choice 等选择规则
StmMapNode            表示地图节点、room_payload、next_nodes
StmRoomFactory        根据 MapNode 创建 CombatRoom / RestRoom / BossRoom
StmEncounterFactory   根据 encounter_id 创建 debug_dummy / boss_dummy 遭遇
```

具体完成项：

```text
1. ChoiceResolver 已接管 card_reward / rest_choice 的具体结算规则。
2. GameState.submit_choice() 保留为公共入口，不直接承载具体选择规则。
3. MapNode 已成为固定地图节点的轻量模型。
4. MapManager 保持地图位置与可达节点职责，不创建房间。
5. RoomFactory 已接管 CombatRoom / RestRoom / BossRoom 的创建。
6. GameFlow.enter_current_room() 已通过 RoomFactory 创建当前房间。
7. EncounterFactory 已接管 debug_dummy / boss_dummy 遭遇创建。
8. CombatRoom / BossRoom 已通过 room_payload.encounter_id 创建战斗遭遇。
9. .gutconfig.json 已加入新增架构测试。
```

## 测试结果

2026-05-30 人工确认完整 GUT 通过：

```text
Scripts: 24
Tests: 187
Passing Tests: 187
Asserts: 880
```

完整测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

后续每次合并前仍应重新运行完整 GUT。

## 已知技术债

当前阶段刻意没有处理以下内容：

```text
1. EventRoom 尚未接入。
2. ChoiceResolver 当前只处理 card_reward / rest_choice。
3. RoomFactory 当前只支持 combat / rest / boss。
4. MapData 当前节点类型仍以 combat / rest / boss 为主。
5. BattleDebugScene 仍是唯一调试入口，尚未验证事件房选择展示。
6. 尚未引入正式地图 UI、随机地图、事件池、商店、遗物或精英房。
```

这些不是本阶段遗漏，而是下一阶段应按规格单独推进的内容。

## 架构审查结论

### 规格审查

```text
玩家可见行为：保持不变
card_reward：保持不变
rest_choice：保持不变
固定地图节点分支：保持不变
Boss 胜利通关：保持不变
新增非目标玩法：无
```

### 代码质量审查

```text
GameState：保留状态与 submit_choice 公共入口
ChoiceResolver：承载选择规则
MapManager：只管理地图位置与可达节点
GameFlow：管理进入房间、完成房间、推进节点、Boss 通关判断
RoomFactory：只创建房间，不处理完成规则
EncounterFactory：只创建遭遇，不修改 GameState
BattleDebugScene：继续作为显示与提交操作入口，不直接维护正式规则
```

## 下一步建议

下一步建议推进一个很小的内容验证阶段：

```text
STS2 EventRoom v1
```

目标是验证当前架构边界是否足以支持新房间类型：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom 发出 event_choice
→ ChoiceResolver 结算事件选择
→ GameFlow 完成房间并返回地图
```

第一版 EventRoom 应保持极小：

```text
允许：一个固定事件、两个固定选项、HP 变化或跳过、完成房间
禁止：随机事件池、商店、遗物、精英房、正式地图 UI、复杂叙事系统
```

## Python 参考项目边界

Python 项目只作为架构和规格参考，不作为 Godot 运行时的一部分。

EventRoom v1 可以参考 Python 项目的以下方向：

```text
地图节点 / 路径语义
Action / InputRequest 思路
Room / Event / Combat 边界
GameState 只保存状态的方向
```

但不得直接迁移完整 Python 框架，也不得让 Godot 项目依赖 Python 运行时。
