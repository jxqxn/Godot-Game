# Pressure Encounter v1 规格设计

## 文档元信息

```text
文档类型：正式规格 / 新玩法最小切片
创建日期：2026-06-04
修订日期：2026-06-04
目标阶段：规格收敛稿，等待 plan
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
→ 行动倾向逐渐成型
→ 到达临界点后由最高行动倾向自动生成结果
→ 系统按固定自动结算管线回放并输出可解释日志
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

---

## 0. 战略定位

### 0.1 长期目标

本机制的长期目标不是“给现有 STS2 框架增加一种特殊事件”。

长期目标是：

```text
用 Pressure Encounter 统一承载整个游戏的主要可玩内容。
```

未来普通事件、关键剧情、战斗、社交冲突、探索、决战，都应逐步抽象到同一个核心框架内：

```text
情境压力
→ 候选信息 / 念头 / 资源 / 机会浮现
→ 玩家用有限经济处理候选
→ 内部结构成型
→ 自动结算
→ 结果反写后续状态
```

当前 v1 只是该统一框架的第一块最小验证切片。

### 0.2 当前阶段定位

当前 Godot 项目仍处在借鉴成熟项目结构、稳定运行时骨架的阶段。现有 STS2 框架承担的是：

```text
固定地图
房间生命周期
ChoiceRequest / ChoiceResolver
GameFlow
BattleDebugScene
GUT 测试基线
```

因此，v1 选择先从 `EventRoom` 进入，并不表示 Pressure Encounter 只是一种事件玩法。

更准确的定位是：

```text
EventRoom 是 v1 的安全入口；
PressureEncounterState 是独立遭遇运行状态；
GameState 保存当前激活的 pressure encounter 引用；
Pressure Encounter 是未来统一玩法框架的种子。
```

这参考 Python 项目的分层方向：GameState 保存当前房间、当前 combat、pending input request 等运行时引用；Combat 本身是独立对象；输入请求是声明式结构。Godot 侧不照搬 Python，但采用相同的边界思路。

### 0.3 分阶段迁移原则

```text
v1：通过 EventRoom 启动独立 PressureEncounterState，验证最小压力遭遇循环。
v2：验证该循环能否承载更高密度、后期经济式的关键遭遇。
v3：抽象出可配置的 Pressure Encounter 数据结构，减少手写事件逻辑。
v4+：逐步评估 Combat / Rest / Event / Boss 等房间是否迁移到统一遭遇框架下。
```

本阶段只处理 v1。

---

## 1. 当前项目最新状态

以下结论已确认，不再作为开放问题重复追问：

```text
1. Pressure Encounter 长期目标是统一承载整个游戏，而不是普通事件旁支。
2. v1 仍通过 EventRoom 启动，因为它是当前最安全入口。
3. PressureEncounterState 是独立遭遇运行状态，不属于 EventRoom 字段集合。
4. PressureEncounterState 路径固定为 scripts/stm/encounters/pressure/。
5. GameState 保存 current_pressure_encounter 引用，但不摊平保存内部玩法字段。
6. request_type 使用 pressure_encounter_choice，不使用 pressure_event_choice，也暂不使用 encounter_choice。
7. ChoiceResolver 只桥接并转发 pressure_action，不维护具体玩法规则。
8. v1 不进入 Combat，不替换所有房间类型，不做完整后期经济引擎。
9. v1 固定使用 3 条行动倾向轨：steady_response / forceful_response / freeze_response。
10. v1 固定使用 2 条局势轨：pressure / ally_trust。
11. v1 固定使用 2 个 core_trigger：observation_window / panic_spiral。
12. v1 必须包含固定自动结算管线，而不只是最终日志摘要。
13. emotion / quiet 必须体现“真实信息价值”，不能只做负面污染。
14. v1 不使用会暗示额外局势轨的卡牌命名，例如 risk_bystander_exposed。
```

后续每一个问题都必须基于**项目最新状态**提出。已经确认并写入规格的结论，不应继续作为开放问题反复追问；若新结论使旧问题失效，应及时删除或改写旧问题。

---

## 2. Intake 判断

### 2.1 任务类型

```text
新玩法 / 结构性扩展 / 统一框架种子 / 调试原型
```

本阶段目标不是新增普通卡牌、敌人或地图节点，而是在现有房间与选择系统上验证未来统一遭遇框架的最小切片。

### 2.2 是否需要规格与计划

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

### 2.3 主干接入点

本阶段应优先复用现有主干，并新增一个独立 encounter 状态对象：

```text
StmEventRoom                         v1 安全入口
PressureEncounterState               独立玩法运行状态
StmGameState.current_pressure_encounter
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
1. StmEventRoom 只负责识别 debug_pressure_encounter、创建并启动 PressureEncounterState。
2. PressureEncounterState 维护 focus_points / working_memory / tracks / chain_counts / resolution_log 等玩法状态。
3. StmGameState 只保存 current_pressure_encounter 引用，不摊平保存 Pressure Encounter 的内部字段。
4. StmChoiceResolver 负责解析 pressure_encounter_choice，并把 pressure_action 转发给 current_pressure_encounter。
5. BattleDebugScene 只显示状态、按钮和日志，只提交 option_id，不直接修改压力遭遇状态。
6. GameFlow 仍只负责进入房间、完成房间、推进地图节点。
```

### 2.4 非目标

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
一次性替换 Combat / Rest / Event / Boss
全游戏迁移到 Pressure Encounter
把 PressureEncounterState 写死为 EventRoom 字段或普通事件规则
把 focus_points / working_memory / tracks 等内部字段摊平进 GameState
current_encounter 泛化抽象
withdraw_response 行动倾向轨
bystander_exposure 或其他复杂局势轨
第三个及以上 core_trigger
自由战斗式结算
只解释结果、不提供固定自动结算管线
把 emotion 卡做成纯负面 debuff
```

说明：长期目标是统一框架；v1 只做最低限度的结构验证，不实现完整高频循环、大量连锁或全游戏迁移。

### 2.5 BDD/TDD 切片

第一条建议测试：

```text
scripts/stm/tests/test_pressure_encounter_v1.gd
```

首个测试方法名建议：

```gdscript
func test_pressure_event_enter_creates_first_pressure_encounter_choice_request() -> void:
```

Given / When / Then 行为注释：

```gdscript
# Given 一个 room_payload.event_id 为 debug_pressure_encounter 的 EventRoom
# When 房间 enter(game_state)
# Then game_state.current_pressure_encounter 不为空
# And game_state.current_choice_request 应为 pressure_encounter_choice
# And 选择标题应显示第一个压力节点
# And 选项中至少包含抓住 / 放弃 / 重新浮现等压力遭遇操作
```

第一条预期失败：

```text
EventRoom 目前只支持 debug_fountain，GameState 也尚无 current_pressure_encounter。
```

### 2.6 风险与红线

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

## 3. 一句话目标

实现一个固定结构化事件原型：

```text
玩家在一个压力情境中，不直接选择最终行动，而是通过有限专注点处理浮现候选卡，使 3 条行动倾向发生变化；候选卡在工作记忆中形成占格、保留、放弃、连锁与污染压力；当压力达到临界点后，系统选择最高行动倾向，并沿固定自动结算管线输出可解释结果。
```

更短定义：

```text
把普通事件选择，从“直接点选结果”，改造成“压力下搜索并加工候选信息 → 行动倾向成型 → 固定自动结算管线生成结果”的最小事件原型。
```

### 3.1 必须保护的体验

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

### 3.2 与“普通事件”的关系

长期目标中，Pressure Encounter 应代替普通事件，而不是作为普通事件旁边的特殊玩法。

但 v1 中仍暂时从 `EventRoom` 启动，只是因为：

```text
1. EventRoom 已经接入 ChoiceRequest / ChoiceResolver / GameFlow。
2. 它是验证最小切片风险最低的入口。
3. 它允许我们在不修改 Combat、不修改地图主干的前提下验证统一框架的核心循环。
```

因此，v1 规格中的 `debug_pressure_encounter` 不应被理解为“又一个事件内容”，而应被理解为：

```text
未来统一遭遇框架的第一个可测试实例。
```

---

## 4. 本阶段设计原则

### 4.1 保持最小实现

本阶段只验证结构，不追求内容规模。

最小内容：

```text
1 个固定事件：debug_pressure_encounter
1 个独立 PressureEncounterState
3 个压力节点
8-12 张静态候选卡
3 条行动倾向轨：steady_response / forceful_response / freeze_response
2 条局势轨：pressure / ally_trust
每个节点 3 点专注点
工作记忆上限 3
至少 2 种 chain_tag：observation / emotion
2 个 core_trigger：observation_window / panic_spiral
1 条固定自动结算管线
1 份可解释日志
```

### 4.2 不直接替换战斗系统

本阶段不进入 `StmCombat`。

Pressure Encounter v1 先通过 `StmEventRoom` 启动，但核心状态不属于 EventRoom。

原因：

```text
1. 当前 Combat 是稳定主干，不应为新玩法原型直接重构。
2. 压力遭遇 v1 还没有证明自己能承载战斗密度。
3. EventRoom 已经通过 ChoiceRequest / ChoiceResolver 与 GameFlow 接通。
4. 先在事件房验证行为，可降低对现有战斗主干的破坏风险。
5. 核心状态独立，后续迁移到 Combat / Boss / Rest 外壳时不必复制事件房逻辑。
```

### 4.3 EventRoom 是启动入口，不是状态归属

推荐架构：

```text
PressureEncounterState
= 独立玩法运行状态，路径使用 scripts/stm/encounters/pressure/。

GameState.current_pressure_encounter
= 当前激活的压力遭遇引用，类似 current_combat 的运行时引用。

EventRoom
= v1 暂时启动 debug_pressure_encounter 的入口。

ChoiceResolver
= 把 pressure_encounter_choice 的 pressure_action 转发给 current_pressure_encounter。

BattleDebugScene
= 只显示 ChoiceRequest 和日志。
```

实现时应尽量让核心状态和规则与 `EventRoom` 解耦：

```text
PressureEncounterState 不应依赖清泉事件等具体 EventRoom 语义。
pressure_encounter_choice 的 payload 不应写死普通事件选项语义。
resolution_log 不应只服务于事件房 UI。
```

### 4.4 行动不是按钮，而是结算结果

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

### 4.5 固定自动结算管线必须存在

参考文档强调的不是“显示一行最终结果”，而是“进入固定顺序的自动结算”。v1 不复刻枪战伤亡顺序，但必须保留固定管线感。

v1 固定自动结算管线：

```text
1. 锁定最终工作记忆与已处理候选。
2. 检查 observation_window 与 panic_spiral。
3. 汇总 3 条行动倾向轨。
4. 按平局优先级选择 dominant_action_tendency。
5. 根据 pressure 修正局势失控描述。
6. 根据 ally_trust 修正同伴配合描述。
7. 生成 final_result。
8. 按上述顺序输出 resolution_log。
```

该管线是 v1 的自动战斗回放替代物，不允许退化为普通事件结论。

### 4.6 自动结果必须可解释

每次完成压力遭遇后，日志必须展示：

```text
最终结果是什么
哪条行动倾向最高
它为什么最高
哪些候选卡产生了影响
哪些局势变量参与了修正
哪些 core_trigger 参与了修正
固定自动结算管线如何一步步得到结果
玩家是否能复盘整个过程
```

如果玩家无法理解为什么发生该结果，本阶段即视为失败。

### 4.7 自走棋化约束

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

### 4.8 后期经济流派的最小转译

```text
重新浮现 = 搜索燃料，但会提高压力。
抓住 = 买入 / 暂存一个临场信息组件。
表达 = 触发该组件的局势或行动倾向收益。
放弃 = 腾出工作记忆格。
安抚 = 清理污染核心的成型风险，同时提取情绪牌中的真实信息。
保留 = 冻结关键件到下一压力节点。
同标签累计 = 最小核心成型。
最终结算 = 自动回放该临场反应结构。
```

v1 不需要做复杂循环，但至少要让玩家看到这些结构的雏形。

---

## 5. 核心概念

| 概念 | 代码建议名 | 说明 |
|---|---|---|
| 压力遭遇 | `pressure_encounter` | 未来统一遭遇框架的最小实例，v1 暂由 EventRoom 启动 |
| 压力遭遇状态 | `PressureEncounterState` | 独立玩法运行状态，不是 EventRoom 字段集合 |
| 当前压力遭遇 | `current_pressure_encounter` | GameState 中保存的当前激活遭遇引用 |
| 压力节点 | `pressure_node` | 遭遇流程中的一个短决策窗口 |
| 浮现候选卡 | `emergence_card` | 当前节点浮现的观察、证据、干扰、关系或技巧提示 |
| 浮现区 | `emergence_pool` | 当前可处理的候选卡列表，承担候选池搜索功能 |
| 工作记忆 | `working_memory` | 玩家暂时抓住的候选卡，容量有限，承担占格与保留压力 |
| 专注点 | `focus_points` | 每个节点可用的操作预算，承担经济约束 |
| 行动倾向轨 | `action_tendency_tracks` | 3 条最终可能结果的竞争数值 |
| 局势轨 | `situation_tracks` | v1 只包含 pressure 与 ally_trust |
| 连锁标签 | `chain_tag` | 候选卡的简单类别，用于最低限度的同类累计 |
| 核心触发 | `core_trigger` | 同类候选处理达到阈值后的质变效果；v1 固定 2 个 |
| 固定自动结算管线 | `auto_resolution_pipeline` | 按固定顺序生成并回放结果 |
| 可解释日志 | `resolution_log` | 玩家可见的结果解释 |

---

## 6. 最小玩法循环

```text
进入 debug_pressure_encounter 事件房
↓
EventRoom 创建 PressureEncounterState
↓
GameState.current_pressure_encounter 指向该状态
↓
PressureEncounterState 生成第一个 pressure_encounter_choice
↓
进入压力节点 1
↓
生成 emergence_pool
↓
玩家用 focus_points 执行有限操作
↓
ChoiceResolver 将 pressure_action 转发给 current_pressure_encounter
↓
候选卡效果写入 working_memory / action_tendency_tracks / situation_tracks / chain_counts / resolution_log
↓
玩家选择保留、放弃、安抚或重新浮现部分候选，形成占格与经济压力
↓
节点结束，压力上升
↓
进入压力节点 2 / 3
↓
压力达到临界点或节点耗尽
↓
进入固定自动结算管线
↓
锁定工作记忆与已处理候选
↓
检查 observation_window 与 panic_spiral 是否触发
↓
汇总并结算最高 action_tendency_track
↓
套用 pressure / ally_trust 修正
↓
生成 final_result 与 resolution_log
↓
PressureEncounterState 标记完成
↓
EventRoom complete
↓
GameFlow 返回地图推进
```

长期目标中，上述循环应逐步成为所有主要房间内容的统一原型；v1 只验证这一循环是否成立。

---

## 7. 数据模型规格

### 7.1 PressureEncounterState

新增独立轻量 RefCounted 状态类。

命名与路径：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
```

本路径作为 v1 结论，不再作为开放问题追问。

字段建议：

```gdscript
var event_id: String = "debug_pressure_encounter"
var node_index: int = 0
var phase: String = "pressure_node"
var is_completed: bool = false

var focus_points: int = 0
var max_focus_points_per_node: int = 3

var emergence_pool: Array = []
var working_memory: Array = []
var working_memory_limit: int = 3
var kept_cards: Array = []
var quieted_cards: Array = []
var used_cards: Array = []

var action_tendency_tracks: Dictionary = {}
var situation_tracks: Dictionary = {}
var chain_counts: Dictionary = {}
var triggered_cores: Array[String] = []

var prior_flags: Dictionary = {}
var auto_resolution_steps: Array[String] = []
var resolution_log: Array[String] = []
var final_result: Dictionary = {}
```

职责建议：

```text
1. 初始化压力遭遇。
2. 生成当前 pressure_encounter_choice 所需的标题、选项和 detail。
3. 处理 pressure_action。
4. 维护工作记忆、专注点、行动倾向轨、局势轨、连锁与日志。
5. 判断是否进入临界结算。
6. 按固定自动结算管线生成 final_result 与 resolution_log。
```

不应由 EventRoom、ChoiceResolver 或 BattleDebugScene 维护这些规则。

### 7.2 GameState 持有当前遭遇引用

建议在 `StmGameState` 中新增：

```gdscript
var current_pressure_encounter = null
```

职责边界：

```text
GameState 只保存当前激活 PressureEncounterState 的引用。
GameState 不摊平保存 focus_points / working_memory / tracks / chain_counts。
GameState.submit_choice() 仍是公共输入入口。
```

长期如果出现更多统一遭遇类型，可再评估是否升级为：

```gdscript
var current_encounter = null
```

v1 暂不做该抽象，避免过早泛化。

### 7.3 action_tendency_tracks

v1 固定 3 条行动倾向轨：

```gdscript
{
  "steady_response": 0,      # 稳住局面 / 继续处理
  "forceful_response": 0,    # 强硬干预 / 立即行动
  "freeze_response": 0       # 僵住 / 无法行动
}
```

v1 不做：

```gdscript
"withdraw_response"          # 后退 / 自保 / 避免介入，留到 v2
```

理由：

```text
1. 3 条已经足以验证“行动倾向成型 → 自动结算”的核心循环。
2. withdraw_response 与 freeze_response 的心理差异重要，但会增加 v1 认知和测试复杂度。
3. action_tendency_tracks 是 Dictionary / Map，未来加入 withdraw_response 不破坏架构。
```

这些不是玩家直接选择的按钮，而是候选卡效果累积后的自动结算对象。

### 7.4 situation_tracks

v1 固定 2 条局势轨：

```gdscript
{
  "pressure": 0,
  "pressure_limit": 6,
  "ally_trust": 0
}
```

说明：

```text
pressure      全局压力，达到 pressure_limit 后进入最终结算。
ally_trust    同伴是否相信玩家角色最后的判断。
```

v1 不做：

```text
bystander_exposure
多 NPC 关系网
复杂伤亡分支
其他复杂局势变量
```

理由：

```text
1. pressure 验证压力推进与临界结算。
2. ally_trust 验证关系回声能否进入系统结算。
3. 2 条局势轨已经足以支撑 v1 的可解释日志。
4. situation_tracks 同样是 Dictionary / Map，未来扩展 bystander_exposure 不破坏架构。
```

### 7.5 core_trigger

v1 固定 2 个 core_trigger：一个正向核心，一个污染核心。

#### 7.5.1 observation_window

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

设计目的：

```text
让玩家感到“我通过处理观察类候选，凑出了一个行动窗口”。
这是正向构筑成型。
```

#### 7.5.2 panic_spiral

```gdscript
{
  "id": "panic_spiral",
  "title": "恐慌螺旋",
  "chain_tag": "emotion_unquieted",
  "threshold": 2,
  "effects": [
    {"target": "action", "key": "freeze_response", "op": "add", "value": 1},
    {"target": "log", "key": "core_triggered", "op": "flag", "value": "panic_spiral"}
  ]
}
```

设计目的：

```text
让玩家感到“污染也会成型”。
情绪 / 干扰类候选不是单次 debuff，而是可能累积成自动结算结构。
```

`panic_spiral` 的最小规则：

```text
emotion 类候选被 grasp 后，若没有通过 quiet 处理，则计入 emotion_unquieted。
emotion_unquieted 达到 2 时，触发 panic_spiral。
quiet 可以从 emotion_unquieted 中移除一张相关候选，或阻止该候选进入 emotion_unquieted。
```

v1 不做第三个核心，例如 `trust_anchor`。`ally_trust` 只作为局势轨参与日志与结算修正。

### 7.6 emergence_card

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
| `chain_tags` | 最小连锁类别，v1 至少使用 `observation` 与 `emotion` |
| `allowed_actions` | 本卡允许的玩家操作 |
| `availability` | 是否允许浮现的规则 |
| `effects` | 不同操作对应的效果列表 |
| `flavor` | UI 文本，不参与结算 |

### 7.7 Effect

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

---

## 8. 玩家操作规格

每个压力节点中，玩家只允许少量操作，避免变成完整卡牌游戏。

| 操作 | 建议 action | 来源 | 成本 | 说明 |
|---|---|---|---:|---|
| 抓住 | `grasp` | 浮现区候选卡 | 1 | 移入工作记忆并应用 grasp 效果 |
| 表达 | `express` | 工作记忆候选卡 | 1 | 把该候选用于当前节点并应用 express 效果 |
| 安抚干扰 | `quiet` | 情绪 / 干扰类候选卡 | 1 | 阻止或移除 emotion_unquieted 累计，并提取情绪牌中的真实信息价值 |
| 保留 | `keep` | 工作记忆候选卡 | 1 | 下个节点继续保留，类似冻结关键件 |
| 放弃 | `discard` | 工作记忆或浮现区候选卡 | 0 | 移除该候选，释放工作记忆格 |
| 重新浮现 | `refresh` | 当前浮现区 | 1 + 压力上升 | 重新生成候选卡，搜索燃料但局势恶化 |

命名注意：

```text
不要使用旧原型中的“扶植 / 压制”作为正式代码或 UI 操作名。
```

### 8.1 操作必须形成的取舍

实现与 UI 展示应让玩家能看见：

```text
抓住会占用工作记忆。
保留会消耗专注点。
放弃会腾格子，但可能断开连锁。
重新浮现会搜索新候选，但提高压力。
quiet 可以降低 panic_spiral 的成型风险，但会消耗专注点。
情绪类候选既是污染，也可能是真实信息。
```

### 8.2 emotion / quiet 的真实信息价值

参考文档中，情绪牌不是“错误念头”，而是身体和人格在压力下提供的真实材料。v1 必须体现这一点。

最小规则：

```text
1. emotion 牌被 grasp 后，会推进 freeze_response 或 emotion_unquieted。
2. emotion 牌若被 quiet，不只是删除 debuff：
   - 阻止或移除该牌对 emotion_unquieted 的推进；
   - 记录一条 insight log，说明玩家从情绪中读出了真实风险；
   - 至少 1 张 emotion 卡的 quiet 效果应提供小额正向价值。
3. v1 不新增情绪洞察轨道，避免范围膨胀。
```

v1 示例：

```text
quiet【手在发抖】：
- 移除或阻止 emotion_unquieted +1
- steady_response +1
- 日志记录：身体正在提醒你风险，而不只是拖慢你。
```

这可以验证“情绪既是污染，也是信息”。

---

## 9. 压力节点 MVP

### 9.1 Node 1：看清局面

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
手在发抖：grasp 时 freeze_response +1, emotion_unquieted +1；quiet 时移除或阻止 emotion_unquieted，并 steady_response +1
按流程来：steady_response +2, technique +1
```

### 9.2 Node 2：说出关键信息

目标：让前期 flag 解锁的证据类候选进入事件，并产生收益与风险。

候选卡建议：

```text
evidence_not_simple       事情不是表面那样     chain_tags: evidence
situation_closing_in      局势正在收紧         chain_tags: observation
self_doubt                我可能又搞砸了       chain_tags: emotion
keep_talking              继续拖住局面         chain_tags: technique
```

说明：

```text
不使用 risk_bystander_exposed 之类命名，因为 v1 不存在 bystander_exposure 局势轨。
如果要保留“旁观者风险”风味，只通过 pressure 与日志表达，不新增数据字段。
```

典型效果：

```text
事情不是表面那样：steady_response +1, pressure -1, evidence +1
局势正在收紧：forceful_response +1, pressure +1, observation +1
我可能又搞砸了：grasp 时 freeze_response +1, emotion_unquieted +1；quiet 时移除或阻止 emotion_unquieted，并记录“自我怀疑提醒你不要鲁莽”
继续拖住局面：steady_response +1, pressure +1, technique +1
```

### 9.3 Node 3：临界前一秒

目标：让行动倾向开始明显分化，并让前面保留或累计的 chain_tag 进入结算。

候选卡建议：

```text
act_now                   现在必须行动       chain_tags: technique
ally_can_hear_you         同伴听得见你       chain_tags: relationship
body_locks_up             身体僵住了         chain_tags: emotion
```

典型效果：

```text
现在必须行动：forceful_response +2, pressure +1, technique +1
同伴听得见你：steady_response +1, ally_trust +1, relationship +1
身体僵住了：grasp 时 freeze_response +1, emotion_unquieted +1；quiet 时移除或阻止 emotion_unquieted，并记录“身体锁死是在提醒你临界已到”
```

说明：v1 不做 `withdraw_possible`，因为 `withdraw_response` 已推迟到 v2。

### 9.4 临界结算

满足任一条件后进入结算：

```text
1. node_index 已完成 3 个压力节点
2. situation_tracks.pressure >= situation_tracks.pressure_limit
3. 玩家选择一个明确的 end_node / wait_for_resolution 操作（若实现阶段需要）
```

进入结算后，不直接显示结果；必须先走固定自动结算管线。

---

## 10. 结果结算规格

### 10.1 最高行动倾向

结算时选择数值最高的行动倾向：

```gdscript
func resolve_dominant_action_tendency(tracks: Dictionary) -> String:
    # 返回 steady_response / forceful_response / freeze_response 中数值最高的 key
```

v1 平局优先级：

```text
freeze_response
> forceful_response
> steady_response
```

理由：压力情境下，如果玩家没有把某种行动倾向明显构筑起来，默认更容易僵住。

### 10.2 结果类型

MVP 固定 3 种结果：

| 结果 id | 触发倾向 | 说明 |
|---|---|---|
| `result_steady` | `steady_response` | 角色稳住局面，风险偏低 |
| `result_forceful` | `forceful_response` | 角色强硬干预，可能保护关键对象，但压力上升 |
| `result_freeze` | `freeze_response` | 角色僵住，局势代价上升 |

### 10.3 局势修正

最终结果应参考局势轨：

```text
ally_trust 高：结果日志提到同伴理解或配合。
pressure 高：结果日志提到局势已经不可完全控制。
triggered_cores 非空：结果日志提到哪些核心触发影响了最终倾向。
```

MVP 不需要实现复杂分支树，只需要在 `final_result` 与 `resolution_log` 中表现这些差异。

### 10.4 固定自动结算管线

最终结果不应只显示一行结论。

应按固定顺序回放：

```text
1. LOCK_MEMORY
   列出最终工作记忆与已处理候选。

2. CHECK_CORES
   列出 observation_window 与 panic_spiral 的触发状态。

3. SUMMARIZE_TENDENCIES
   列出 steady_response / forceful_response / freeze_response 的最终数值。

4. CHOOSE_DOMINANT_TENDENCY
   使用平局优先级选择最高行动倾向。

5. APPLY_PRESSURE_MODIFIER
   根据 pressure / pressure_limit 输出局势失控程度描述。

6. APPLY_ALLY_TRUST_MODIFIER
   根据 ally_trust 输出同伴是否理解、配合或迟疑的描述。

7. BUILD_FINAL_RESULT
   生成 result_steady / result_forceful / result_freeze。

8. WRITE_RESOLUTION_LOG
   将以上步骤写入玩家可见日志。
```

这相当于叙事版自动战斗回放。

---

## 11. ChoiceRequest 接入规格

### 11.1 request_type

新增：

```text
pressure_encounter_choice
```

原因：

```text
1. 不把该玩法锁死为 EventRoom 的特殊事件选择。
2. 与 PressureEncounterState / current_pressure_encounter 命名一致。
3. 仍复用 StmGameState.submit_choice() 与 StmChoiceResolver。
4. 不新增第二套 ChoiceRequest，只是新增一种 request_type。
```

暂不使用更泛化的 `encounter_choice`，避免过早占用未来所有遭遇类型的总接口名。

### 11.2 ChoiceOption payload

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

### 11.3 ChoiceResolver 责任

`StmChoiceResolver` 新增分支：

```gdscript
"pressure_encounter_choice":
    return _resolve_pressure_encounter_choice(game_state, request, option)
```

`_resolve_pressure_encounter_choice()` 应只做：

```text
1. 校验 payload。
2. 从 game_state.current_pressure_encounter 取得当前 PressureEncounterState。
3. 调用 PressureEncounterState 处理 pressure_action。
4. 根据处理结果更新 current_choice_request。
5. 若遭遇完成，则 clear_choice_request()、清理 current_pressure_encounter、并 complete room。
6. 返回 choice_result，用 message 描述本次操作。
```

不要在 BattleDebugScene 中实现这些规则。ChoiceResolver 也不应直接维护工作记忆、专注点、连锁等规则，只负责转发和桥接。

---

## 12. EventRoom 接入规格

### 12.1 event_id

新增固定事件 id：

```text
debug_pressure_encounter
```

`StmEventRoom.enter(game_state)` 在识别该 event_id 时，不再创建普通 `event_choice`，而是：

```text
1. 创建 PressureEncounterState。
2. 调用其初始化逻辑。
3. 写入 game_state.current_pressure_encounter。
4. 从 PressureEncounterState 获取第一个 pressure_encounter_choice。
5. 交给 GameState 保存为 current_choice_request。
```

### 12.2 状态存放结论

MVP 不建议把 PressureEncounterState 只作为 EventRoom 字段保存。

推荐结构：

```text
PressureEncounterState 是独立运行状态，放在 scripts/stm/encounters/pressure/。
GameState 保存 current_pressure_encounter 引用。
EventRoom 只负责创建并启动该状态。
ChoiceResolver 只把 pressure_action 转发给 current_pressure_encounter。
BattleDebugScene 只显示 ChoiceRequest 和日志，不直接读写规则。
```

理由：

```text
1. 避免把未来统一框架写死成 EventRoom 的特殊规则。
2. 与 Python 参考项目中 GameState 持有 current_combat、Combat 自身独立的分层方向一致。
3. 便于未来 Combat / Boss / Rest 外壳逐步迁移到同一 Encounter 内核。
4. 避免 GameState 变成承载所有玩法字段的大杂烩。
```

### 12.3 未来迁移注意

由于长期目标是统一框架，实施时应避免让 `PressureEncounterState` 强依赖 EventRoom。

例如：

```text
不要在状态类中写 room_type == "event" 的判断。
不要把 debug_fountain 的 heal / leave 语义混入压力遭遇状态。
不要假设 Pressure Encounter 永远只在地图 event 节点中出现。
```

---

## 13. BattleDebugScene 显示规格

BattleDebugScene 不写规则，只显示 ChoiceRequest。

MVP 可以复用现有 choice panel，不新增复杂 UI。

但 `ChoiceRequest.title` 与 `ChoiceOption.label/detail` 应包含足够信息：

```text
标题：压力遭遇：节点 1 / 看清局面
选项：抓住【对方快失控了】（专注 -1，强硬干预 +1，占用工作记忆，observation +1）
选项：抓住【手在发抖】（专注 -1，僵住 +1，占用工作记忆，未安抚情绪 +1）
选项：安抚【手在发抖】（专注 -1，移除未安抚情绪累计，稳住 +1，记录身体风险提示）
选项：表达【同伴在等你的判断】（专注 -1，同伴信任 +1，relationship +1）
选项：保留【事情不是表面那样】（专注 -1，下个节点继续保留）
选项：放弃【手在发抖】（释放工作记忆格）
选项：重新浮现（专注 -1，压力 +1）
```

日志面板应显示：

```text
抓住【对方快失控了】：强硬干预 +1，observation +1。
安抚【手在发抖】：未安抚情绪 -1，稳住 +1；身体正在提醒你风险。
工作记忆：1 / 3。
压力上升：1 / 6。
当前行动倾向：稳住 1，强硬 2，僵住 0。
核心进度：observation_window 1 / 2，panic_spiral 0 / 2。
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

## 14. 测试规格

### 14.1 新增测试文件

建议新增：

```text
scripts/stm/tests/test_pressure_encounter_v1.gd
scripts/stm/tests/test_choice_resolver_pressure_encounter_v1.gd
scripts/stm/tests/test_battle_debug_pressure_encounter_v1.gd
```

若范围过大，MVP 第一阶段只新增前两个。

### 14.2 必测行为

#### 测试 1：EventRoom 可创建压力遭遇选择并挂载独立状态

```gdscript
func test_pressure_event_enter_creates_first_pressure_encounter_choice_request() -> void:
    # Given 一个 event_id 为 debug_pressure_encounter 的 EventRoom
    # When enter(game_state)
    # Then game_state.current_pressure_encounter 不为空
    # And current_pressure_encounter 是独立 PressureEncounterState
    # And current_choice_request.request_type == "pressure_encounter_choice"
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

#### 测试 5：observation_window 可以触发正向核心

```gdscript
func test_pressure_observation_window_triggers_forceful_bonus() -> void:
    # Given observation 标签累计达到 2
    # When 检查 core_trigger
    # Then triggered_cores 包含 observation_window
    # And forceful_response 增加
    # And resolution_log 记录该核心触发
```

#### 测试 6：panic_spiral 可以触发污染核心

```gdscript
func test_pressure_unquieted_emotion_triggers_panic_spiral() -> void:
    # Given emotion_unquieted 累计达到 2
    # When 检查 core_trigger
    # Then triggered_cores 包含 panic_spiral
    # And freeze_response 增加
    # And resolution_log 记录该核心触发
```

#### 测试 7：quiet 可以阻止或移除未安抚情绪累计

```gdscript
func test_pressure_quiet_prevents_panic_spiral_progress() -> void:
    # Given working_memory 中有一张 emotion 候选卡
    # When submit_choice("quiet_xxx")
    # Then emotion_unquieted 不应因该候选继续累计
    # And panic_spiral 未被该候选推进
```

#### 测试 8：quiet 可以从 emotion 牌中提取真实信息价值

```gdscript
func test_pressure_quiet_emotion_can_create_insight_value() -> void:
    # Given working_memory 中有 hands_shaking
    # When submit_choice("quiet_hands_shaking")
    # Then steady_response 增加
    # And resolution_log 记录身体风险提示
```

#### 测试 9：最高行动倾向自动生成结果

```gdscript
func test_pressure_event_resolves_highest_action_tendency() -> void:
    # Given forceful_response 高于其他行动倾向
    # When 压力遭遇进入最终结算
    # Then final_result.id == "result_forceful"
    # And resolution_log 解释 forceful_response 为什么最高
```

#### 测试 10：固定自动结算管线按顺序输出日志

```gdscript
func test_pressure_auto_resolution_pipeline_writes_ordered_steps() -> void:
    # Given 压力遭遇进入最终结算
    # When resolve_auto_resolution()
    # Then resolution_log 按顺序包含 LOCK_MEMORY / CHECK_CORES / SUMMARIZE_TENDENCIES / CHOOSE_DOMINANT_TENDENCY / APPLY_PRESSURE_MODIFIER / APPLY_ALLY_TRUST_MODIFIER / BUILD_FINAL_RESULT
```

#### 测试 11：房间完成后回到 GameFlow 并清理当前压力遭遇

```gdscript
func test_pressure_event_completion_marks_room_completed() -> void:
    # Given 压力事件已完成最终结算
    # When resolver 处理完成
    # Then game_state.current_choice_request == null
    # And game_state.current_pressure_encounter == null
    # And room.is_completed == true
    # And GameFlow 可以推进到下一节点
```

### 14.3 完整测试命令

```powershell
godot -s addons/gut/gut_cmdln.gd
```

本阶段完成后，完整 GUT 必须通过。

---

## 15. 可解释日志规格

最终日志必须至少包含：

```text
固定自动结算管线：
- LOCK_MEMORY
- CHECK_CORES
- SUMMARIZE_TENDENCIES
- CHOOSE_DOMINANT_TENDENCY
- APPLY_PRESSURE_MODIFIER
- APPLY_ALLY_TRUST_MODIFIER
- BUILD_FINAL_RESULT

最终结果：result_forceful / result_steady / result_freeze
dominant track：forceful_response
行动倾向明细：
- steady_response: X
- forceful_response: Y
- freeze_response: Z
关键来源：
- 【候选卡 A】使 forceful_response +1
- 【候选卡 B】使 freeze_response +1
- quiet【候选卡 C】从情绪中提取真实风险信息
- refresh 使 pressure +1
工作记忆摘要：
- 已处理候选：A, B, C
- 最终工作记忆占用：N / 3
核心摘要：
- observation_window: 2 / 2，已触发，forceful_response +1
- panic_spiral: 2 / 2，已触发，freeze_response +1
局势摘要：
- pressure: A / B
- ally_trust: D
```

日志是玩家可见功能，不是 debug-only。

### 15.1 日志的体验目标

日志不能只解释数值，还要解释结构：

```text
你不是直接选择了最终结果。
你通过搜索候选、占用与释放工作记忆、保留关键件、触发连锁，使某条行动倾向成型。
未处理的情绪污染也可能累积成 panic_spiral，参与最终自动结算。
被 quiet 的情绪并非消失，而是被转化为可理解的风险信息。
最终结果来自固定自动结算管线，而不是普通事件分支。
```

---

## 16. 规格自检：边界

```text
只新增一个固定压力遭遇实例：通过
新增独立 PressureEncounterState：通过
PressureEncounterState 路径固定为 scripts/stm/encounters/pressure/：通过
GameState 只保存 current_pressure_encounter 引用：通过
request_type 固定为 pressure_encounter_choice：通过
v1 固定 3 条行动倾向轨：通过
v1 固定 2 条局势轨：通过
v1 固定 2 个 core_trigger：通过
v1 有固定自动结算管线：通过
emotion / quiet 有真实信息价值：通过
不使用会暗示 bystander_exposure 的卡牌命名：通过
不新增随机事件池：通过
不新增 EventFactory：通过
不修改 Combat：通过
不修改 StmCard.can_play 语义：通过
不修改 TerminalResult：通过
不修改 project.godot：通过
不新增独立 DebugScene：通过
不恢复旧原型目录或命名：通过
不实现完整后期经济引擎：通过
不一次性替换所有房间类型：通过
```

---

## 17. 规格自检：与当前架构的关系

### 17.1 复用现有架构

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

并新增：

```text
PressureEncounterState
StmGameState.current_pressure_encounter
```

### 17.2 不应复用或修改的部分

本阶段不应改动：

```text
StmCombat
StmCard.can_play()
StmCardManager 战斗牌堆语义
ActionQueue 结算语义
MapData 默认地图，除非实施计划明确增加一个可选 debug_pressure_encounter 节点
```

### 17.3 是否需要地图接入

本阶段有两种方式：

```text
A. 测试内通过 EventRoom 直接构造 debug_pressure_encounter。
B. 后续计划阶段再决定是否把 debug_pressure_encounter 接入默认固定地图。
```

规格建议：MVP 第一阶段先用测试直接构造，不急于修改默认地图。

原因：避免和当前已经验证的默认 7 层地图产生不必要耦合。

---

## 18. 验收标准

本阶段通过条件：

```text
1. 完整 GUT 通过。
2. debug_pressure_encounter 可创建 PressureEncounterState，并挂到 game_state.current_pressure_encounter。
3. debug_pressure_encounter 可创建 pressure_encounter_choice。
4. 玩家可以通过 submit_choice 执行 grasp / express / quiet / discard / refresh 中的最小子集。
5. ChoiceResolver 将 pressure_action 转发给 current_pressure_encounter，而不是自己维护玩法规则。
6. focus_points、working_memory、action_tendency_tracks、situation_tracks 会按规则变化。
7. action_tendency_tracks 只包含 steady_response / forceful_response / freeze_response。
8. situation_tracks 只包含 pressure / pressure_limit / ally_trust。
9. refresh 必须有压力代价。
10. working_memory 必须形成占格压力，discard 必须能释放格子。
11. observation_window 能由 observation 累计触发，并影响 forceful_response 或日志。
12. panic_spiral 能由未 quiet 的 emotion 累计触发，并影响 freeze_response 或日志。
13. quiet 能阻止或移除 emotion_unquieted 对 panic_spiral 的推进。
14. quiet 至少能在 hands_shaking 上产生一条真实信息价值：steady_response +1 或等价日志效果。
15. 最终结果由最高 action_tendency_track 自动生成，而不是玩家直接点击最终结果。
16. 最终结算必须走固定自动结算管线，并按顺序写入日志。
17. 结果日志能解释为什么生成该结果，并解释候选池、工作记忆、核心触发、局势与固定结算管线的作用。
18. EventRoom 完成后 GameFlow 可继续推进，并清理 current_pressure_encounter。
19. BattleDebugScene 不直接维护压力遭遇规则。
20. 不引入 AGENTS.md 禁止的旧原型体系或平行系统。
21. 规格表达必须承认：Pressure Encounter 是未来统一框架种子，而不是普通事件旁支。
```

体验验收补充：

```text
测试者应能说：我刚才不是在选事件选项，而是在让一个临场反应引擎跑起来。
```

---

## 19. 失败信号

如果实现或测试后出现以下情况，应视为设计偏离：

```text
1. 玩家直接点击“最终行动”按钮，而不是处理候选卡。
2. 候选卡只是普通 buff，无法解释结果生成。
3. refresh 没有代价，变成无脑抽答案。
4. 工作记忆只是已选列表，没有占格、保留、放弃压力。
5. 只有正向核心，没有污染核心，导致玩法像奖励系统而不是压力系统。
6. panic_spiral 无法被 quiet 影响，导致玩家无法处理污染。
7. emotion 牌只有负面污染，没有任何真实信息价值。
8. 最终结算只是摘要日志，没有固定自动结算管线。
9. 使用 risk_bystander_exposed 等名称暗示 v1 已经有 bystander_exposure 轨。
10. BattleDebugScene 直接修改 pressure state。
11. 规则绕过 GameState.submit_choice()。
12. 新增第二套 GameFlow / ChoiceRequest / DebugScene。
13. 使用旧原型禁区命名或恢复旧目录。
14. 自动结果没有可解释日志。
15. 实现把 Pressure Encounter 写死为普通事件小玩法，阻碍后续统一框架迁移。
16. 试图在 v1 中一次性替换现有 Combat / Rest / Event / Boss，导致范围失控。
17. PressureEncounterState 只作为 EventRoom 字段存在，导致 Combat / Boss / Rest 未来无法复用。
18. GameState 摊平保存 focus_points / working_memory / tracks 等内部字段，变成玩法规则大杂烩。
19. ChoiceResolver 直接维护工作记忆、连锁或最终结算，导致规则分散。
20. v1 重新引入 withdraw_response，导致行动倾向范围失控。
21. v1 重新引入 bystander_exposure 或多 NPC 局势轨，导致局势层过早复杂化。
22. v1 引入第三个及以上 core_trigger，导致 MVP 范围膨胀。
```

---

## 20. 审查提问

以下问题用于规格审查和头脑风暴，帮助发现项目方向偏差。

重要原则：后续每一个问题都必须基于**项目最新状态**提出。已经确认并写入规格的结论，不应继续作为开放问题反复追问；若新结论使旧问题失效，应及时删除或改写旧问题。

### 20.1 关于项目方向

```text
1. 这个切片是否仍然服务于“先稳定中期循环”的目标，而不是过早进入完整叙事系统？
2. 这套结构是否能迁移到原创题材，而不是依赖参考案例的枪战语境？
3. 未来统一框架是否还需要保留 Combat / Rest / Event / Boss 这些房间类型作为外壳，还是最终只保留不同 pressure encounter 模板？
```

### 20.2 关于玩家体验

```text
1. 玩家是否能明确感到：自己不是在选事件选项，而是在进行候选池搜索、工作记忆占格、专注点经济、候选卡连锁、行动倾向成型与自动结算回放？
2. 玩家是否能看懂自己处理的是“当前浮现的信息”，而不是普通手牌？
3. 玩家是否能接受最终行动不是直接选择，而是由行动倾向自动生成？
4. 可解释日志应该显示多少数值，多少自然语言？
5. refresh 的代价是否只做压力上升，还是还需要工作记忆污染？
6. emotion / quiet 的“真实信息价值”是否足够，还是需要更明确的情绪洞察结构留到 v2？
```

### 20.3 关于实现边界

```text
1. GameState 新增 current_pressure_encounter 是否足够，还是应直接抽象 current_encounter？
2. BattleDebugScene 目前 choice panel 是否足够显示该玩法，还是需要先增强 ChoiceOption.detail？
3. 是否需要为 choice_result 增加 detail / state_summary 字段？这会不会影响现有测试？
4. 是否先不接入默认地图，只用 GUT 和手动构造验证？
```

### 20.4 关于 MVP 范围

```text
1. 3 个压力节点是否已经足够验证循环？
2. 8-12 张候选卡是否过多？是否应先压到 8 张？
3. 最终结果是否需要多个叙事分支，还是只需要一条结果日志？
```

### 20.5 关于长期风险

```text
1. 这个机制是否会变成复杂对话 UI，而不是自走棋式构筑体验？
2. 如果玩家觉得“没刷到关键卡所以输了”，如何通过前期 flag 与日志纠正这种感受？
3. 如果后续加入更多节点，如何避免每个事件都要手写大量特殊逻辑？
4. 什么时候才值得引入 PressureEncounterFactory？当前阶段是否明确不需要？
5. 当前术语是否足够避开旧原型禁区，同时又能承接真正想验证的机制？
6. 如果后续要表现后期经济流派的高密度操作感，哪些内容必须留到 v2，而不是塞进 v1？
7. 如果长期统一所有玩法，如何避免过早抽象导致性能、可维护性和测试复杂度失控？
```

---

## 21. 后续计划建议

若本规格经审查后方向正确，下一步计划文件应只覆盖：

```text
1. 新增最小 PressureEncounterState。
2. 新增 GameState.current_pressure_encounter 引用。
3. 新增 debug_pressure_encounter EventRoom 启动分支。
4. 新增 pressure_encounter_choice 解析，并转发给 current_pressure_encounter。
5. 新增 3 个压力节点与 8-12 张静态候选卡。
6. 新增 3 条行动倾向轨：steady_response / forceful_response / freeze_response。
7. 新增 2 条局势轨：pressure / ally_trust。
8. 新增工作记忆占格与 discard 释放格子。
9. 新增 refresh 压力代价。
10. 新增 observation_window 与 panic_spiral 两个 core_trigger。
11. 新增 quiet 对 emotion_unquieted / panic_spiral 的处理。
12. 新增 emotion / quiet 的最小真实信息价值。
13. 新增固定自动结算管线。
14. 新增可解释日志。
15. 新增 GUT 测试。
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
全游戏迁移
Combat / Rest / Event / Boss 替换
current_encounter 泛化抽象
withdraw_response
bystander_exposure
第三个及以上 core_trigger
```

---

## 22. 一句话验收

本规格成功时，测试者应能说：

```text
我没有直接选择最终行动，但我理解为什么系统生成了这个结果；
我处理过的候选卡、刷新代价、工作记忆占格、核心触发和局势变量，都能在固定自动结算管线中复盘；
情绪不是单纯坏牌，它既可能污染我，也可能提醒我真实风险；
这不像多步事件选项，更像我在压力下让一个临场反应引擎跑起来。
```

本规格失败时，测试者会说：

```text
这只是一个复杂的事件选项列表，或者系统替我随机决定了结果。
```

长期目标成功时，测试者应能进一步说：

```text
我感觉战斗、事件、探索和关键剧情不是不同系统，而是同一个压力遭遇框架在不同情境下的变体。
```
