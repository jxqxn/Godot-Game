# Pressure Encounter v1 规格设计

## 文档元信息

```text
文档类型：正式规格草案 / 新玩法最小切片
创建日期：2026-06-04
修订日期：2026-06-04
目标阶段：规格审查前草案
对应参考：docs/references/disco-gunfight-cardification/
```

本规格用于把 `docs/references/disco-gunfight-cardification/` 中的外部案例机制，抽象为当前 Godot 项目可审查、可测试、可逐步实现的最小玩法切片。

本规格**不是**直接复刻参考案例中的人物、地点、枪战或具体文本；本规格只提炼一种机制结构：

```text
压力情境
→ 浮现候选池
→ 玩家用有限专注点搜索、抓取、暂存、表达、安抚、保留、放弃、重新浮现
→ 工作记忆形成占格压力
→ 候选卡之间产生最低限度的连锁收益与污染
→ 若干行动倾向逐渐成型
→ 到达临界点后由最高行动倾向自动生成结果
→ 系统按固定顺序回放结算并输出可解释日志
→ 房间完成并回到现有 GameFlow
```

本阶段必须避免退化为“多步事件选项”。它要验证的是一种更接近自走棋后期经济回合的体验：

```text
候选池搜索
→ 工作记忆占格
→ 专注点经济
→ 候选卡连锁
→ 行动倾向成型
→ 自动结算回放
```

## 0. Intake 判断

### 0.1 任务类型

```text
新玩法 / 结构性扩展 / 调试原型
```

本阶段目标不是新增普通卡牌、敌人或地图节点，而是在现有房间与选择系统上验证一个新的结构化事件原型。

### 0.2 是否需要规格与计划

需要。

本文件为规格：

```text
docs/superpowers/specs/2026-06-04-pressure-encounter-v1-design.md
```

若本规格审查通过，后续应再创建实施计划：

```text
docs/superpowers/plans/2026-06-04-pressure-encounter-v1.md
```

在计划确认前，不进入代码实现。

### 0.3 主干接入点

本阶段应优先复用现有主干：

```text
StmEventRoom
StmChoiceRequest
StmChoiceOption
StmGameState.submit_choice(option_id)
StmChoiceResolver
StmGameFlow
StmRoomFactory
BattleDebugScene
GUT
```

规则边界：

```text
1. StmEventRoom 负责进入结构化事件并发出选择请求。
2. StmGameState 只保存当前选择请求与运行时状态，不直接写具体事件规则。
3. StmChoiceResolver 负责解析本阶段新增的压力事件选择规则。
4. BattleDebugScene 只显示状态、按钮和日志，只提交 option_id，不直接修改压力事件状态。
5. GameFlow 仍只负责进入房间、完成房间、推进地图节点。
```

### 0.4 非目标

本阶段明确不做：

```text
完整叙事系统
完整剧情文本
完整心理系统
完整装备系统
完整调查系统
完整技能树
新战斗系统
新地图系统
正式地图 UI
随机事件池
事件工厂 EventFactory
第二套 GameState / GameFlow / MapManager / ChoiceRequest / ActionQueue
第二套 Combat 结算
独立新 DebugScene
完整后期经济引擎
复杂 APM 操作
```

说明：本规格虽然要求保留自走棋式“经济回合感”，但 v1 只做最低限度的结构验证，不实现完整高频循环或大量连锁。

### 0.5 BDD/TDD 切片

第一条建议测试：

```text
scripts/stm/tests/test_pressure_encounter_v1.gd
```

首个测试方法名建议：

```gdscript
func test_pressure_event_enter_creates_first_pressure_choice_request() -> void:
```

Given / When / Then 行为注释：

```gdscript
# Given 一个 room_payload.event_id 为 debug_pressure_encounter 的 EventRoom
# When 房间 enter(game_state)
# Then game_state.current_choice_request 应为 pressure_event_choice
# And 选择标题应显示第一个压力节点
# And 选项中至少包含抓住 / 放弃 / 重新浮现等压力事件操作
```

第一条预期失败：

```text
EventRoom 目前只支持 debug_fountain，尚不会创建 pressure_event_choice。
```

### 0.6 风险与红线

本规格不得触碰：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) bool 语义
Python 参考项目
```

本规格不得恢复 AGENTS.md 中禁止的旧原型体系。

因此，本阶段命名避免使用旧体系命名，统一使用：

```text
pressure_encounter
emergence_card
action_tendency_track
situation_track
focus_points
working_memory
chain_tag
core_trigger
resolution_log
```

而不是恢复旧目录、旧场景或旧运行时。

---

## 1. 背景

当前 Godot 项目已完成 STS2 风格基础主干：固定地图、战斗房、休息房、事件房、Boss 房、奖励选择、休息选择、事件选择，以及自动出牌预览。

最新主线状态说明，当前建议的后续方向之一是：

```text
为自有创新卡牌机制先拆出一个最小规格切片。
```

本规格即对该建议的响应。

参考目录 `docs/references/disco-gunfight-cardification/` 已收纳外部机制拆解，但该目录明确不是正式开发规格。本规格将其抽象为一个不依赖具体题材的最小 Godot 接入切片。

---

## 2. 一句话目标

实现一个固定结构化事件原型：

```text
玩家在一个压力情境中，不直接选择最终行动，而是通过有限专注点处理浮现候选卡，使若干行动倾向发生变化；候选卡在工作记忆中形成占格、保留、放弃、连锁与污染压力；当压力达到临界点后，系统选择最高行动倾向并输出可解释结果。
```

更短定义：

```text
把普通事件选择，从“直接点选结果”，改造成“压力下搜索并加工候选信息 → 行动倾向成型 → 自动生成结果”的最小事件原型。
```

### 2.1 必须保护的体验

本机制不应表现为多步事件选择。

它必须表现为：

```text
候选池搜索
→ 工作记忆占格
→ 专注点经济
→ 候选卡连锁
→ 行动倾向成型
→ 自动结算回放
```

玩家应感到：

```text
我刚才不是在选事件选项，而是在让一个临场反应引擎跑起来。
```

---

## 3. 本阶段设计原则

### 3.1 保持最小实现

本阶段只验证结构，不追求内容规模。

最小内容建议：

```text
1 个固定事件：debug_pressure_encounter
3 个压力节点
8-12 张静态候选卡
3-4 条行动倾向轨
2-4 条局势轨
每个节点 3 点专注点
工作记忆上限 3
1-2 种最小连锁标签
1 次自动结果结算
1 份可解释日志
```

### 3.2 不直接替换战斗系统

本阶段不进入 `StmCombat`。

压力遭遇应先作为 `StmEventRoom` 的结构化事件分支存在。

原因：

```text
1. 当前 Combat 是稳定主干，不应为新玩法原型直接重构。
2. 压力遭遇本质上更像结构化事件，而不是 HP 战斗。
3. EventRoom 已经通过 ChoiceRequest / ChoiceResolver 与 GameFlow 接通。
4. 先在事件房验证行为，可降低对现有战斗主干的破坏风险。
```

### 3.3 行动不是按钮，而是结算结果

玩家不应直接看到或点击：

```text
执行最终行动 A
执行最终行动 B
执行最终行动 C
```

玩家应处理候选卡：

```text
抓住某个观察
表达某个证据
安抚某个干扰
保留某个关系回声
放弃某个暂时无用的信息
重新浮现一组候选
```

候选卡改变行动倾向轨。到达临界点后，最高行动倾向自动成为结果。

### 3.4 自动结果必须可解释

本阶段的核心不是复杂分支，而是解释链。

每次完成压力遭遇后，日志必须展示：

```text
最终结果是什么
哪条行动倾向最高
它为什么最高
哪些候选卡产生了影响
哪些局势变量参与了修正
哪些连锁标签或核心触发参与了修正
玩家是否能复盘整个过程
```

如果玩家无法理解为什么发生该结果，本阶段即视为失败。

### 3.5 自走棋化约束

本阶段必须避免做成：

```text
事件节点 1：选一个按钮
事件节点 2：再选一个按钮
事件节点 3：再选一个按钮
最后显示结果
```

正确方向是：

```text
浮现区像候选池，不是固定选项列表。
工作记忆像手牌空间，不是单纯“已选历史”。
专注点像经济预算，不是普通行动次数。
候选卡既可能是燃料，也可能是污染，也可能是核心组件。
保留、放弃、重新浮现要形成真实取舍。
最终结果要像自动战斗回放，而不是普通事件结论。
```

### 3.6 后期经济流派的最小转译

后期自走棋经济流派的关键不是“钱多”，而是：

```text
搜索燃料
买入 / 暂存组件
触发收益
腾格子
保留关键件
形成核心
把经济回合产物压缩成自动战斗结构
```

本阶段的最小转译是：

```text
重新浮现 = 搜索燃料，但会提高压力。
抓住 = 买入 / 暂存一个临场信息组件。
表达 = 触发该组件的局势或行动倾向收益。
放弃 = 腾出工作记忆格。
保留 = 冻结关键件到下一压力节点。
同标签累计 = 最小核心成型。
最终结算 = 自动回放该临场反应结构。
```

v1 不需要做复杂循环，但至少要让玩家看到这些结构的雏形。

---

## 4. 核心概念

| 概念 | 代码建议名 | 说明 |
|---|---|---|
| 压力遭遇 | `pressure_encounter` | 一个结构化事件原型，不是 Combat |
| 压力节点 | `pressure_node` | 原事件流程中的一个短决策窗口 |
| 浮现候选卡 | `emergence_card` | 当前节点浮现的观察、证据、干扰、关系或技巧提示 |
| 浮现区 | `emergence_pool` | 当前可处理的候选卡列表，承担候选池搜索功能 |
| 工作记忆 | `working_memory` | 玩家暂时抓住的候选卡，容量有限，承担占格与保留压力 |
| 专注点 | `focus_points` | 每个节点可用的操作预算，承担经济约束 |
| 行动倾向轨 | `action_tendency_tracks` | 最终可能结果的竞争数值 |
| 局势轨 | `situation_tracks` | 压力、暴露、稳定、信任等场景变量 |
| 连锁标签 | `chain_tag` | 候选卡的简单类别，用于最低限度的同类累计 |
| 核心触发 | `core_trigger` | 同类候选处理达到阈值后的质变效果 |
| 可解释日志 | `resolution_log` | 玩家可见的结果解释 |

---

## 5. 最小玩法循环

```text
进入 debug_pressure_encounter 事件房
↓
初始化 PressureEncounterState
↓
进入压力节点 1
↓
生成 emergence_pool
↓
玩家用 focus_points 执行有限操作
↓
候选卡效果写入 working_memory / action_tendency_tracks / situation_tracks / chain_counts / resolution_log
↓
玩家选择保留、放弃或重新浮现部分候选，形成占格与经济压力
↓
节点结束，压力上升
↓
进入压力节点 2 / 3
↓
若某类 chain_tag 达到阈值，触发最小 core_trigger
↓
压力达到临界点或节点耗尽
↓
结算最高 action_tendency_track
↓
生成最终结果
↓
按日志回放关键来源、连锁触发和局势修正
↓
EventRoom complete
↓
GameFlow 返回地图推进
```

---

## 6. 数据模型规格

### 6.1 PressureEncounterState

建议新增轻量 RefCounted 状态类，或先在 EventRoom 内以 Dictionary 维护。

命名建议：

```text
scripts/stm/events/pressure_encounter_state.gd
```

若实现阶段认为新增文件过多，也可先用 `Dictionary`，但测试中必须能读取关键字段。

字段建议：

```gdscript
var event_id: String = "debug_pressure_encounter"
var node_index: int = 0
var phase: String = "pressure_node"

var focus_points: int = 0
var max_focus_points_per_node: int = 3

var emergence_pool: Array = []
var working_memory: Array = []
var working_memory_limit: int = 3
var kept_cards: Array = []

var action_tendency_tracks: Dictionary = {}
var situation_tracks: Dictionary = {}
var chain_counts: Dictionary = {}
var triggered_cores: Array[String] = []

var prior_flags: Dictionary = {}
var resolution_log: Array[String] = []
var final_result: Dictionary = {}
```

### 6.2 action_tendency_tracks

MVP 可以先做 3 条，也可以保留 4 条。

最小 3 条版本：

```gdscript
{
  "steady_response": 0,      # 稳住局面 / 继续处理
  "forceful_response": 0,    # 强硬干预 / 立即行动
  "freeze_response": 0       # 僵住 / 无法行动
}
```

扩展 4 条版本：

```gdscript
{
  "steady_response": 0,
  "forceful_response": 0,
  "freeze_response": 0,
  "withdraw_response": 0     # 后退 / 自保 / 避免介入
}
```

规格倾向：MVP 第一版优先 3 条，减少认知负担；若审查认为自保倾向不可缺，再保留 4 条。

注意：这些不是玩家直接选择的按钮，而是候选卡效果累积后的自动结算对象。

### 6.3 situation_tracks

MVP 可以先做 2 条，再扩展到 4 条。

最小 2 条版本：

```gdscript
{
  "pressure": 0,
  "pressure_limit": 6,
  "ally_trust": 0
}
```

扩展 4 条版本：

```gdscript
{
  "pressure": 0,
  "pressure_limit": 6,
  "bystander_exposure": 0,
  "ally_trust": 0
}
```

说明：

```text
pressure              全局压力，达到 pressure_limit 后进入最终结算
ally_trust            同伴是否相信玩家角色最后的判断
bystander_exposure    旁观者或第三方被卷入的风险
```

本阶段不做多 NPC 关系网，不做复杂伤亡分支。

### 6.4 emergence_card

候选卡可以先用 Dictionary 定义。

字段建议：

```gdscript
{
  "id": "observed_instability",
  "title": "对方快失控了",
  "card_type": "observation",
  "source": "scene_pressure",
  "chain_tags": ["observation"],
  "allowed_actions": ["grasp", "express", "discard"],
  "availability": [],
  "effects": {
    "grasp": [
      {"target": "action", "key": "forceful_response", "op": "add", "value": 1},
      {"target": "chain", "key": "observation", "op": "add", "value": 1}
    ],
    "express": [
      {"target": "situation", "key": "pressure", "op": "add", "value": 1}
    ]
  },
  "flavor": "你意识到，对方并没有自己表现得那么稳。"
}
```

字段说明：

| 字段 | 说明 |
|---|---|
| `id` | 稳定唯一 id |
| `title` | UI 显示名 |
| `card_type` | `observation` / `evidence` / `emotion` / `relationship` / `technique` |
| `source` | `scene_pressure` / `prior_flag` / `relationship` / `skill_like` |
| `chain_tags` | 最小连锁类别，MVP 只需 1-2 种标签 |
| `allowed_actions` | 本卡允许的玩家操作 |
| `availability` | 是否允许浮现的规则 |
| `effects` | 不同操作对应的效果列表 |
| `flavor` | UI 文本，不参与结算 |

### 6.5 Effect

效果格式：

```gdscript
{
  "target": "action",       # action / situation / focus / memory / chain / log
  "key": "forceful_response",
  "op": "add",             # add / set / flag
  "value": 1,
  "note": "强硬干预倾向 +1"
}
```

MVP 只需要支持：

```text
add
set
flag
```

`target = chain` 用于更新 `chain_counts`，不需要复杂脚本回调。

不需要乘法、条件表达式、复杂脚本回调。

### 6.6 core_trigger

MVP 需要至少 1 个最低限度的核心触发，避免玩法退化为“每张牌只是普通 buff”。

建议格式：

```gdscript
{
  "id": "observation_window",
  "title": "行动窗口",
  "chain_tag": "observation",
  "threshold": 2,
  "effects": [
    {"target": "action", "key": "forceful_response", "op": "add", "value": 1},
    {"target": "log", "key": "core_triggered", "op": "flag", "value": "observation_window"}
  ]
}
```

MVP 可选核心：

```text
observation_window：处理 2 张 observation 标签卡后触发，forceful_response +1。
trust_anchor：处理 2 张 relationship 标签卡后触发，steady_response +1 或 ally_trust +1。
panic_spiral：未安抚的 emotion 标签累计 2 后触发，freeze_response +1。
```

建议第一版只实现 `observation_window` 与 `panic_spiral` 中的一个，避免范围过大。

---

## 7. 玩家操作规格

每个压力节点中，玩家只允许少量操作，避免变成完整卡牌游戏。

| 操作 | 建议 action | 来源 | 成本 | 说明 |
|---|---|---|---:|---|
| 抓住 | `grasp` | 浮现区候选卡 | 1 | 移入工作记忆并应用 grasp 效果 |
| 表达 | `express` | 工作记忆候选卡 | 1 | 把该候选用于当前节点并应用 express 效果 |
| 安抚干扰 | `quiet` | 情绪 / 干扰类候选卡 | 1-2 | 降低干扰效果或从工作记忆移除 |
| 保留 | `keep` | 工作记忆候选卡 | 1 | 下个节点继续保留，类似冻结关键件 |
| 放弃 | `discard` | 工作记忆或浮现区候选卡 | 0 | 移除该候选，释放工作记忆格 |
| 重新浮现 | `refresh` | 当前浮现区 | 1 + 压力上升 | 重新生成候选卡，搜索燃料但局势恶化 |

命名注意：

```text
不要使用旧原型中的“扶植 / 压制”作为正式代码或 UI 操作名。
```

### 7.1 操作必须形成的取舍

实现与 UI 展示应让玩家能看见：

```text
抓住会占用工作记忆。
保留会消耗专注点。
放弃会腾格子，但可能断开连锁。
重新浮现会搜索新候选，但提高压力。
情绪类候选既是污染，也可能是真实信息。
```

---

## 8. 压力节点 MVP

### 8.1 Node 1：看清局面

目标：让玩家理解浮现区、工作记忆、专注点和行动倾向轨。

候选卡建议：

```text
observed_instability      对方快失控了       chain_tags: observation
ally_waiting              同伴在等你的判断   chain_tags: relationship
hands_shaking             手在发抖           chain_tags: emotion
basic_procedure           按流程来           chain_tags: technique
```

典型效果：

```text
对方快失控了：forceful_response +1, pressure +1, observation +1
同伴在等你的判断：steady_response +1, ally_trust +1, relationship +1
手在发抖：freeze_response +2, forceful_response -1, emotion +1
按流程来：steady_response +2, technique +1
```

### 8.2 Node 2：说出关键信息

目标：让前期 flag 解锁的证据类候选进入事件，并产生收益与风险。

候选卡建议：

```text
evidence_not_simple       事情不是表面那样     chain_tags: evidence
risk_bystander_exposed    旁观者会被卷进来     chain_tags: observation
self_doubt                我可能又搞砸了       chain_tags: emotion
keep_talking              继续拖住局面         chain_tags: technique
```

典型效果：

```text
事情不是表面那样：steady_response +1, pressure -1, bystander_exposure +1, evidence +1
旁观者会被卷进来：forceful_response +1, bystander_exposure +1, observation +1
我可能又搞砸了：freeze_response +1, emotion +1
继续拖住局面：steady_response +1, pressure +1, technique +1
```

### 8.3 Node 3：临界前一秒

目标：让行动倾向开始明显分化，并让前面保留或累计的 chain_tag 进入结算。

候选卡建议：

```text
act_now                   现在必须行动       chain_tags: technique
withdraw_possible         现在后退还来得及   chain_tags: emotion
ally_can_hear_you         同伴听得见你       chain_tags: relationship
body_locks_up             身体僵住了         chain_tags: emotion
```

典型效果：

```text
现在必须行动：forceful_response +2, pressure +1, technique +1
现在后退还来得及：withdraw_response +2 或 freeze_response +1, emotion +1
同伴听得见你：steady_response +1, ally_trust +1, relationship +1
身体僵住了：freeze_response +2, emotion +1
```

### 8.4 临界结算

满足任一条件后进入结算：

```text
1. node_index 已完成 3 个压力节点
2. situation_tracks.pressure >= situation_tracks.pressure_limit
3. 玩家选择一个明确的 end_node / wait_for_resolution 操作（若实现阶段需要）
```

进入结算前，应先检查 `chain_counts` 是否触发 `core_trigger`。

---

## 9. 结果结算规格

### 9.1 最高行动倾向

结算时选择数值最高的行动倾向：

```gdscript
func resolve_dominant_action_tendency(tracks: Dictionary) -> String:
    # 返回数值最高的 key
```

平局优先级建议：

```text
freeze_response
> withdraw_response
> forceful_response
> steady_response
```

如果 MVP 只保留 3 条行动倾向，则平局优先级为：

```text
freeze_response
> forceful_response
> steady_response
```

理由：压力情境下，僵住和自保应是更强的默认惯性；玩家需要通过候选卡处理让稳定或强硬行动超过它们。

### 9.2 结果类型

MVP 只需要 3-4 种结果：

| 结果 id | 触发倾向 | 说明 |
|---|---|---|
| `result_steady` | `steady_response` | 角色稳住局面，风险偏低 |
| `result_forceful` | `forceful_response` | 角色强硬干预，可能保护关键对象，但压力上升 |
| `result_freeze` | `freeze_response` | 角色僵住，第三方风险上升 |
| `result_withdraw` | `withdraw_response` | 可选；角色后退自保，自己风险下降，但局势代价上升 |

### 9.3 局势修正

最终结果应参考局势轨：

```text
bystander_exposure 高：结果日志提到第三方被卷入风险
ally_trust 高：结果日志提到同伴理解或配合
pressure 高：结果日志提到局势已经不可完全控制
triggered_cores 非空：结果日志提到哪些核心触发影响了最终倾向
```

MVP 不需要实现复杂分支树，只需要在 `final_result` 与 `resolution_log` 中表现这些差异。

### 9.4 自动结算回放

最终结果不应只显示一行结论。

应按固定顺序回放：

```text
1. 列出最终工作记忆与已处理候选。
2. 列出触发过的 chain_tag 与 core_trigger。
3. 列出最终行动倾向数值。
4. 选择最高倾向。
5. 套用局势轨修正。
6. 输出最终结果。
```

这相当于叙事版自动战斗回放。

---

## 10. ChoiceRequest 接入规格

### 10.1 request_type

建议新增：

```text
pressure_event_choice
```

原因：

```text
1. 与现有 event_choice 区分，避免把结构化压力规则塞进普通清泉事件。
2. 仍复用 StmGameState.submit_choice() 与 StmChoiceResolver。
3. 不新增第二套 ChoiceRequest，只是新增一种 request_type。
```

### 10.2 ChoiceOption payload

每个选项的 payload 建议：

```gdscript
{
  "action": "pressure_action",
  "pressure_action": "grasp",
  "card_id": "observed_instability"
}
```

或：

```gdscript
{
  "action": "pressure_action",
  "pressure_action": "refresh"
}
```

### 10.3 ChoiceResolver 责任

`StmChoiceResolver` 新增分支：

```gdscript
"pressure_event_choice":
    return _resolve_pressure_event_choice(game_state, request, option)
```

`_resolve_pressure_event_choice()` 应只做：

```text
1. 校验 payload。
2. 调用压力遭遇状态对象处理玩家操作。
3. 根据处理结果更新 current_choice_request。
4. 若遭遇完成，则 clear_choice_request() 并 complete room。
5. 返回 choice_result，用 message 描述本次操作。
```

不要在 BattleDebugScene 中实现这些规则。

---

## 11. EventRoom 接入规格

### 11.1 event_id

新增固定事件 id：

```text
debug_pressure_encounter
```

`StmEventRoom.enter(game_state)` 在识别该 event_id 时，不再创建普通 `event_choice`，而是初始化压力遭遇状态并创建第一个 `pressure_event_choice`。

### 11.2 状态存放

MVP 可选两种方案，实施计划阶段需二选一。

方案 A：状态存在 EventRoom 字段中。

```gdscript
var pressure_encounter_state = null
```

优点：范围小，生命周期自然随房间结束。

方案 B：状态存在 GameState 的临时字段中。

```gdscript
var current_pressure_encounter = null
```

优点：ChoiceResolver 更容易访问。

建议：MVP 优先方案 A，但 ChoiceRequest.context 必须携带 room，使 ChoiceResolver 能通过 request.context.room 访问状态。

类似现有 EventRoom 记录结果的方式。

---

## 12. BattleDebugScene 显示规格

BattleDebugScene 不写规则，只显示 ChoiceRequest。

MVP 可以复用现有 choice panel，不新增复杂 UI。

但 `ChoiceRequest.title` 与 `ChoiceOption.label/detail` 应包含足够信息：

```text
标题：压力遭遇：节点 1 / 看清局面
选项：抓住【对方快失控了】（专注 -1，强硬干预 +1，占用工作记忆）
选项：表达【同伴在等你的判断】（专注 -1，同伴信任 +1，relationship +1）
选项：保留【事情不是表面那样】（专注 -1，下个节点继续保留）
选项：放弃【手在发抖】（释放工作记忆格）
选项：重新浮现（专注 -1，压力 +1）
```

日志面板应显示：

```text
抓住【对方快失控了】：强硬干预 +1，observation +1。
工作记忆：1 / 3。
压力上升：1 / 6。
当前行动倾向：稳住 1，强硬 2，僵住 0。
当前连锁：observation 1 / 2。
```

注意：

```text
不要让 BattleDebugScene 直接读写压力遭遇规则状态。
它只根据 ChoiceRequest 和 result.message / result.detail 显示。
```

如果现有 `choice_result` 结构不足以承载详细日志，实施计划阶段可考虑在 result 中附加非破坏性字段：

```gdscript
"detail": "..."
"state_summary": "..."
```

但不得破坏既有测试对 `ok/code/message/request_type/selected_option_id` 的语义。

---

## 13. 测试规格

### 13.1 新增测试文件

建议新增：

```text
scripts/stm/tests/test_pressure_encounter_v1.gd
scripts/stm/tests/test_choice_resolver_pressure_event_v1.gd
scripts/stm/tests/test_battle_debug_pressure_event_v1.gd
```

若范围过大，MVP 第一阶段只新增前两个。

### 13.2 必测行为

#### 测试 1：EventRoom 可创建压力事件选择

```gdscript
func test_pressure_event_enter_creates_first_pressure_choice_request() -> void:
    # Given 一个 event_id 为 debug_pressure_encounter 的 EventRoom
    # When enter(game_state)
    # Then current_choice_request.request_type == "pressure_event_choice"
    # And title 包含压力节点信息
```

#### 测试 2：抓住候选卡会消耗专注点并进入工作记忆

```gdscript
func test_pressure_choice_grasp_card_moves_card_to_working_memory() -> void:
    # Given 当前压力节点浮现了 observed_instability
    # When submit_choice("grasp_observed_instability")
    # Then focus_points 减少 1
    # And working_memory 包含 observed_instability
    # And forceful_response 增加
    # And working_memory 占用增加
```

#### 测试 3：重新浮现有代价

```gdscript
func test_pressure_choice_refresh_increases_pressure() -> void:
    # Given 当前压力节点仍有专注点
    # When submit_choice("refresh")
    # Then focus_points 减少 1
    # And situation_tracks.pressure 增加 1
    # And emergence_pool 被重新生成
```

#### 测试 4：放弃候选卡会释放工作记忆格

```gdscript
func test_pressure_choice_discard_releases_working_memory_slot() -> void:
    # Given working_memory 已包含一张候选卡
    # When submit_choice("discard_xxx")
    # Then working_memory 不再包含该候选卡
    # And 后续可继续 grasp 新候选卡
```

#### 测试 5：同标签累计可以触发最小核心

```gdscript
func test_pressure_chain_tag_can_trigger_minimal_core() -> void:
    # Given observation 标签累计达到阈值
    # When 检查 core_trigger
    # Then triggered_cores 包含 observation_window
    # And resolution_log 记录该核心触发
```

#### 测试 6：最高行动倾向自动生成结果

```gdscript
func test_pressure_event_resolves_highest_action_tendency() -> void:
    # Given forceful_response 高于其他行动倾向
    # When 压力遭遇进入最终结算
    # Then final_result.id == "result_forceful"
    # And resolution_log 解释 forceful_response 为什么最高
```

#### 测试 7：房间完成后回到 GameFlow

```gdscript
func test_pressure_event_completion_marks_room_completed() -> void:
    # Given 压力事件已完成最终结算
    # When resolver 处理完成
    # Then game_state.current_choice_request == null
    # And room.is_completed == true
    # And GameFlow 可以推进到下一节点
```

### 13.3 完整测试命令

```powershell
godot -s addons/gut/gut_cmdln.gd
```

本阶段完成后，完整 GUT 必须通过。

---

## 14. 可解释日志规格

最终日志必须至少包含：

```text
最终结果：result_forceful / result_steady / result_freeze / result_withdraw
 dominant track：forceful_response
行动倾向明细：
- steady_response: X
- forceful_response: Y
- freeze_response: Z
- withdraw_response: W
关键来源：
- 【候选卡 A】使 forceful_response +1
- 【候选卡 B】使 freeze_response +2
- refresh 使 pressure +1
工作记忆摘要：
- 已处理候选：A, B, C
- 最终工作记忆占用：N / 3
连锁摘要：
- observation: 2 / 2，触发 observation_window
- emotion: 1 / 2，未触发 panic_spiral
局势摘要：
- pressure: A / B
- bystander_exposure: C
- ally_trust: D
```

日志是玩家可见功能，不是 debug-only。

### 14.1 日志的体验目标

日志不能只解释数值，还要解释结构：

```text
你不是直接选择了最终结果。
你通过搜索候选、占用与释放工作记忆、保留关键件、触发连锁，使某条行动倾向成型。
最终结果来自这条倾向的自动结算。
```

---

## 15. 规格自检：边界

```text
只新增一个固定压力事件：通过
不新增随机事件池：通过
不新增 EventFactory：通过
不修改 Combat：通过
不修改 StmCard.can_play 语义：通过
不修改 TerminalResult：通过
不修改 project.godot：通过
不新增独立 DebugScene：通过
不恢复旧原型目录或命名：通过
不实现完整后期经济引擎：通过
```

---

## 16. 规格自检：与当前架构的关系

### 16.1 复用现有架构

本规格复用：

```text
StmEventRoom
StmChoiceRequest
StmChoiceOption
StmGameState.submit_choice()
StmChoiceResolver
StmGameFlow
BattleDebugScene choice_panel
BattleDebugScene log_panel
```

### 16.2 不应复用或修改的部分

本阶段不应改动：

```text
StmCombat
StmCard.can_play()
StmCardManager 战斗牌堆语义
ActionQueue 结算语义
MapData 默认地图，除非实施计划明确增加一个可选 debug_pressure_encounter 节点
```

### 16.3 是否需要地图接入

本阶段有两种方式：

```text
A. 测试内通过 EventRoom 直接构造 debug_pressure_encounter。
B. 后续计划阶段再决定是否把 debug_pressure_encounter 接入默认固定地图。
```

规格建议：MVP 第一阶段先用测试直接构造，不急于修改默认地图。

原因：避免和当前已经验证的默认 7 层地图产生不必要耦合。

---

## 17. 验收标准

本阶段通过条件：

```text
1. 完整 GUT 通过。
2. debug_pressure_encounter 可创建 pressure_event_choice。
3. 玩家可以通过 submit_choice 执行 grasp / express / quiet / discard / refresh 中的最小子集。
4. focus_points、working_memory、action_tendency_tracks、situation_tracks 会按规则变化。
5. refresh 必须有压力代价。
6. working_memory 必须形成占格压力，discard 必须能释放格子。
7. 至少 1 种 chain_tag 或 core_trigger 能影响结算或日志。
8. 最终结果由最高 action_tendency_track 自动生成，而不是玩家直接点击最终结果。
9. 结果日志能解释为什么生成该结果，并解释候选池、工作记忆、连锁和局势的作用。
10. EventRoom 完成后 GameFlow 可继续推进。
11. BattleDebugScene 不直接维护压力事件规则。
12. 不引入 AGENTS.md 禁止的旧原型体系或平行系统。
```

体验验收补充：

```text
测试者应能说：我刚才不是在选事件选项，而是在让一个临场反应引擎跑起来。
```

---

## 18. 失败信号

如果实现或测试后出现以下情况，应视为设计偏离：

```text
1. 玩家直接点击“最终行动”按钮，而不是处理候选卡。
2. 候选卡只是普通 buff，无法解释结果生成。
3. refresh 没有代价，变成无脑抽答案。
4. 工作记忆只是已选列表，没有占格、保留、放弃压力。
5. 没有任何连锁、标签累计或核心触发，导致玩法像复杂事件 UI。
6. BattleDebugScene 直接修改 pressure state。
7. 规则绕过 GameState.submit_choice()。
8. 新增第二套 GameFlow / ChoiceRequest / DebugScene。
9. 使用旧原型禁区命名或恢复旧目录。
10. 自动结果没有可解释日志。
```

---

## 19. 审查提问

以下问题用于规格审查和头脑风暴，帮助发现项目方向偏差。

### 19.1 关于项目方向

```text
1. 这个切片是否仍然服务于“先稳定中期循环”的目标，而不是过早进入完整叙事系统？
2. 压力遭遇是否应该先作为 EventRoom 原型，而不是进入 Combat？
3. 这个机制最终想替代普通事件，还是只作为少数关键节点使用？
4. 这套结构是否能迁移到原创题材，而不是依赖参考案例的枪战语境？
```

### 19.2 关于玩家体验

```text
1. 玩家是否能明确感到：自己不是在选事件选项，而是在进行候选池搜索、工作记忆占格、专注点经济、候选卡连锁、行动倾向成型与自动结算回放？
2. 玩家是否能看懂自己处理的是“当前浮现的信息”，而不是普通手牌？
3. 玩家是否能接受最终行动不是直接选择，而是由行动倾向自动生成？
4. 可解释日志应该显示多少数值，多少自然语言？
5. refresh 的代价应该是压力上升，还是工作记忆污染，还是两者都有？
6. 情绪 / 干扰类候选卡是负担，还是也应该提供某种真实信息价值？
7. 同标签累计和 core_trigger 是否足够让玩家感到“构筑成型”，还是会显得过于抽象？
```

### 19.3 关于实现边界

```text
1. PressureEncounterState 应放在 EventRoom 字段，还是 GameState 临时字段？
2. 是否新增 request_type = pressure_event_choice，还是复用 event_choice 并扩展 action？
3. BattleDebugScene 目前 choice panel 是否足够显示该玩法，还是需要先增强 ChoiceOption.detail？
4. 是否需要为 choice_result 增加 detail / state_summary 字段？这会不会影响现有测试？
5. 是否先不接入默认地图，只用 GUT 和手动构造验证？
```

### 19.4 关于 MVP 范围

```text
1. 3 个压力节点是否已经足够验证循环？
2. 8-12 张候选卡是否过多？是否应先压到 8 张？
3. 4 条行动倾向轨是否过多？是否可以先做 3 条：稳住 / 强硬 / 僵住？
4. 局势轨是否应该先只保留 pressure 与 ally_trust？
5. 最终结果是否需要多个叙事分支，还是只需要一条结果日志？
6. v1 是否只需要 1 个 core_trigger，还是应至少包含一个正向核心和一个污染核心？
```

### 19.5 关于长期风险

```text
1. 这个机制是否会变成复杂对话 UI，而不是自走棋式构筑体验？
2. 如果玩家觉得“没刷到关键卡所以输了”，如何通过前期 flag 与日志纠正这种感受？
3. 如果后续加入更多节点，如何避免每个事件都要手写大量特殊逻辑？
4. 什么时候才值得引入 PressureEventFactory？当前阶段是否明确不需要？
5. 当前术语是否足够避开旧原型禁区，同时又能承接真正想验证的机制？
6. 如果后续要表现后期经济流派的高密度操作感，哪些内容必须留到 v2，而不是塞进 v1？
```

---

## 20. 后续计划建议

若本规格经审查后方向正确，下一步计划文件应只覆盖：

```text
1. 新增最小 PressureEncounterState。
2. 新增 debug_pressure_encounter EventRoom 分支。
3. 新增 pressure_event_choice 解析。
4. 新增 3 个压力节点与 8-12 张静态候选卡。
5. 新增工作记忆占格与 discard 释放格子。
6. 新增 refresh 压力代价。
7. 新增 1 个最小 chain_tag / core_trigger。
8. 新增可解释日志。
9. 新增 GUT 测试。
```

计划文件不应包含：

```text
完整 UI 重做
默认地图接入
随机事件池
完整叙事内容
复杂技能系统
装备系统
多角色关系系统
完整后期经济引擎
```

---

## 21. 一句话验收

本规格成功时，测试者应能说：

```text
我没有直接选择最终行动，但我理解为什么系统生成了这个结果；
我处理过的候选卡、刷新代价、工作记忆占格、连锁触发和局势变量，都能在结果日志中复盘；
这不像多步事件选项，更像我在压力下让一个临场反应引擎跑起来。
```

本规格失败时，测试者会说：

```text
这只是一个复杂的事件选项列表，或者系统替我随机决定了结果。
```
