# AGENTS.md

本文件是项目协作规则，供后续人工协作者和代码 Agent 读取。任何实现前都应先确认本文件与 `README.md` 中的当前项目状态。

## 思维语言规则

你的所有思考内容（thinking/reasoning）和代码注释必须使用**中文**，无论上下文语言是什么。

要求：

- 每次开始新的 thinking 时，第一句必须为：**【中文思维链】**。
- 该标记仅存在于 thinking 中，绝对不要出现在最终回复里。
- 违反时必须立即切回中文，并重新以【中文思维链】开头。

## 当前项目方向

项目是基于 Godot 的卡牌战斗原型，当前主线围绕 STS2 复刻方向推进。

当前已完成并验证：

```text
手牌优先级排序与自动出牌 v1
自动出牌预览与不可打原因展示 v1.1
card_reward 战斗奖励选择
rest_choice 休息房选择
固定地图节点分支 v1
Core Runtime Architecture Spine v1
STS2 EventRoom v1
```

当前核心架构边界：

```text
StmGameState          保存运行时状态，提供 submit_choice() 公共入口
StmChoiceResolver     处理 card_reward / rest_choice / event_choice 等选择规则
StmMapNode            表示地图节点、room_payload、next_nodes
StmMapManager         管理当前位置和可达节点
StmGameFlow           管理进入房间、推进节点、Boss 通关判断
StmRoomFactory        根据 MapNode 创建房间
StmEncounterFactory   根据 encounter_id 创建战斗遭遇
BattleDebugScene      显示状态并提交玩家操作，不直接维护规则
```

EventRoom v1 已按以下方向接入并通过完整 GUT：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom 发出 event_choice
→ ChoiceResolver 结算事件选择
→ GameFlow 完成房间并返回地图
```

## 开发流程规则

### 1. 先规格，再计划，再实现

新功能或结构性重构必须先写规格文档：

```text
docs/superpowers/specs/YYYY-MM-DD-xxx-design.md
```

然后写实施计划：

```text
docs/superpowers/plans/YYYY-MM-DD-xxx.md
```

规格和计划确认后，才进入代码实现。

### 2. 行为驱动开发（BDD）最高优先级

在编写任何正式代码之前，必须先在测试方法中写出 Given-When-Then 模式的行为注释和测试方法名。

禁止在完成行为注释之前，编写正式代码。

### 3. 最小 TDD

每一步只做能让当前测试通过的最小实现。

失败处理原则：

```text
只看第一条失败
定位根因
只修根因
不借机扩大范围
不借机新增玩法
```

### 4. 双重审查

实现后必须做：

```text
规格审查
代码质量审查
```

重点检查：

```text
是否符合规格目标
是否越过非目标范围
是否破坏现有玩家可见行为
是否引入平行系统
是否把规则写进 UI
是否绕过 GameFlow / GameState / ChoiceResolver / RoomFactory 等主干边界
```

## 测试命令

运行所有单元测试：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

当前基线：

```text
Scripts: 28
Tests: 199
Passing Tests: 199
Asserts: 962
```

每次合并前必须重新运行完整 GUT。

GUT 退出时可能出现 ObjectDB / resources still in use 警告；当前功能验收以 `All tests passed` 和退出码 0 为准。

## 开发红线

禁止恢复或新增以下旧原型体系：

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

禁止新增以下平行系统：

```text
第二套 GameState
第二套 GameFlow
第二套 MapManager
第二套 ChoiceRequest
第二套 ActionQueue
第二套 Combat 结算
第二套 DebugScene 运行时
```

除非有明确规格和用户确认，否则不要修改：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) bool 语义
Python 参考项目
```

## 调试工具边界

`BattleDebugScene` 是当前唯一允许提供数值编辑器的调试 UI，但它不应新增正式规则职责。

允许的 debug-only 状态入口：

```text
StmGameState.debug_apply_combat_values(values, enemy)
StmGameState.debug_clear_current_combat()
StmMapManager.debug_set_floors_for_test(floors)
StmGameFlow.debug_set_map_floors_for_test(floors)
```

规则：

```text
正式玩法规则不得调用 debug_* 入口。
BattleDebugScene 后续新增调试写状态行为时，应优先走 debug_* 入口。
BattleDebugScene 不得直接修改 MapManager / Room 完成状态 / Deck 规则状态。
不要把 debug_* 入口扩展成第二套 Combat 结算或第二套 GameFlow。
```

其中地图注入相关 debug_* 入口只允许 GUT / 测试使用，正式调试场景不应调用。

## Python 参考项目使用规则

Python 项目只作为架构和规格参考，不作为 Godot 运行时的一部分。

可以参考：

```text
地图节点 / 路径语义
Action / InputRequest 思路
Room / Event / Combat 边界
GameState 只保存状态的方向
```

不要直接迁移完整 Python 框架，不要把 Godot 项目改成依赖 Python 运行时。

## 新功能接入建议

新增内容应优先复用当前主干边界。

例如后续 Smith / upgrade / 更多 EventRoom 内容应按以下方向接入：

```text
Room 发出 ChoiceRequest
→ GameState.submit_choice(option_id)
→ ChoiceResolver 结算选择
→ GameFlow 完成房间并返回地图
```

不要把事件选择直接写进 `GameState`，不要让 `BattleDebugScene` 直接修改 HP / Deck / MapManager。

如果确实需要调试数值编辑，应通过 `StmGameState.debug_apply_combat_values()` 等明确 debug-only 入口，并保持正式规则路径不依赖这些入口。

## 文档维护规则

每完成一个阶段，应同步检查：

```text
README.md
AGENTS.md
docs/superpowers/specs/
docs/superpowers/plans/
docs/superpowers/status/
```

如果功能已经通过完整 GUT，应补充或更新 status 文档，记录：

```text
完成内容
测试结果
已知技术债
下一步建议
```
