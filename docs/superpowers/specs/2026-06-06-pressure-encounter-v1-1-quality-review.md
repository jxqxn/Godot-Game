# Pressure Encounter v1.1 机制质量审查规格

## 文档元信息

```text
文档类型：机制质量审查规格 / v1.1 迭代草案
创建日期：2026-06-06
修订日期：2026-06-06
目标阶段：问答式规格迭代
前置实现：Pressure Encounter v1 已合入 main
对应 v1 规格：docs/superpowers/specs/2026-06-04-pressure-encounter-v1-design.md
对应 v1 计划：docs/superpowers/plans/2026-06-04-pressure-encounter-v1.md
对应 v1 状态：docs/superpowers/status/2026-06-04-pressure-encounter-v1-status.md
```

本规格用于 Pressure Encounter v1 合入后的第一轮机制质量审查。

v1 已经证明：

```text
Pressure Encounter 可以在当前 STS2 主干上跑通；
可以通过 EventRoom(debug_pressure_encounter) 启动；
可以复用 ChoiceRequest / ChoiceResolver / GameState.submit_choice()；
可以维护工作记忆、专注点、行动倾向轨、局势轨、core_trigger 与自动结算日志；
完整 GUT 已通过。
```

v1.1 的目标不是扩大系统，而是回答：

```text
这个已经跑通的最小循环，是否能更接近“酒馆战棋 10 费回合”的基础体验，
是否能清楚地区分“压力积攒环节”和“自动执行环节”，
以及自动执行是否能带来类似“看着胜率展开自动战斗”的快感？
```

---

## 1. 当前项目最新状态

以下结论已确认，不再作为开放问题重复追问：

```text
1. Pressure Encounter v1 已实现并合入 main。
2. v1 已通过完整 GUT。
3. v1 仍不接入默认地图。
4. v1 通过 EventRoom(debug_pressure_encounter) 手动构造验证。
5. PressureEncounterState 独立存在于 scripts/stm/encounters/pressure/。
6. GameState 只保存 current_pressure_encounter 引用。
7. ChoiceResolver 只桥接 pressure_encounter_choice，不维护规则。
8. BattleDebugScene 只显示 ChoiceRequest / choice_result 日志，不直接改规则。
9. v1 固定 3 条行动倾向轨：steady_response / forceful_response / freeze_response。
10. v1 固定 2 条局势轨：pressure / ally_trust。
11. v1 固定 2 个 core_trigger：observation_window / panic_spiral。
12. v1 已有固定自动结算管线。
13. v1.1 明确以“酒馆战棋 10 费回合基础体验”为优先目标，而不是特殊流派。
14. v1.1 中大多数普通候选卡 grasp = 暂存 + 占格，不是买入即触发。
15. v1.1 中少数特殊候选卡可以有即时正负影响，例如 emotion 污染。
16. v1.1 中 keep = 冻结关键件，不消耗 focus；成本是继续占用 working_memory。
17. v1.1 中 refresh 使用受控随机与有限候选库存池，而不是简单重建列表。
18. v1.1 的最高层体验循环是：压力积攒环节 ↔ 自动执行环节。
19. express 后候选进入 used，不在当前压力积攒环节立刻回 stock；它只可能在后续压力积攒环节重新进入可浮现池。
20. v1.1 支持数据结构上的 copy_count，但默认每张具体候选 1 份；重复类似候选主要作为后续塑造反刍、执念和情绪占据的扩展口。
21. 自动执行环节不应被设计成“事后回放”，而应是“带成果率预期的过程展示”。
22. 操作结束时，行动倾向竞争已经决出 dominant_action；outcome_rate 显示的是该 dominant_action 的成功率，不是多行动结果分布。
```

后续问题必须基于当前项目最新状态提出。已经确认并写入规格的结构，不作为 v1.1 开放问题反复追问。

---

## 2. 玩家体验主循环

Pressure Encounter 的核心不只是“在一个压力节点里操作卡牌”。

它的更高层循环应该是：

```text
压力积攒环节
→ 自动执行环节
→ 新一轮压力积攒环节
→ 新一轮自动执行环节
```

这对应酒馆战棋的：

```text
酒馆操作环节
→ 自动战斗环节
→ 下一轮酒馆操作环节
→ 下一轮自动战斗环节
```

也对应参考文档中枪战段落的体验：

```text
一系列白色检定 / 对话选择 / 信息浮现
→ 压力逐渐积累
→ 玩家最终无法避免进入红色检定式的强制行动节点
→ 先前积攒下来的压力、误判、关系、装备、技能与行动倾向集中结算
→ 局势释放，进入下一个压力状态
```

策划定义：

```text
压力积攒环节 = 玩家还能操作、搜索、暂存、保留、放弃、表达念头的阶段。
自动执行环节 = 玩家不再逐项操作，而是系统根据已积攒结构，让事情不可避免地发生的阶段。
```

玩家应该感到：

```text
刚才那些刷新、抓住、保留、放弃、表达，不是普通点击历史；
它们共同塑造了一个即将被迫执行的临场反应结构；
当自动执行环节到来时，我不是读一份事后报告，而是在看这套结构怎样当场展开。
```

---

## 3. v1.1 一句话目标

```text
在不扩大系统边界的前提下，把 Pressure Encounter v1 的操作体验从“能跑通的事件卡牌化原型”，推进到更接近“酒馆战棋 10 费回合基础体验”的候选池搜索、买入暂存、占格取舍、有限库存、关键件保留、刷新找核心、压力积攒与自动执行。
```

更短定义：

```text
v1.1 先还原基础回合与自动执行切换，不急着做特殊流派。
```

---

## 4. 本阶段非目标

v1.1 不做：

```text
默认地图接入
正式地图 UI
新 DebugScene
跨遭遇随机事件池
全局随从池
稀有度 / Tavern Tier / 权重成长
PressureEncounterFactory
current_encounter 泛化抽象
withdraw_response
bystander_exposure
第三个及以上 core_trigger
更多局势轨
完整剧情文本
完整叙事系统
完整心理系统
完整后期经济引擎
特殊流派机制
养酒馆式“进入意识即触发大量效果”的玩法
Combat / Rest / Event / Boss 替换
完整 UI 重做
复杂胜率模拟器
完整战斗预测器
多行动结果分布预测器
```

说明：

```text
默认地图接入会验证“入口”；v1.1 要验证“机制质量”。
特殊流派会验证“高级玩法变体”；v1.1 要先验证基础回合。
有限候选库存池不是跨遭遇随机事件池；它只服务当前压力积攒环节内的 refresh / grasp / discard / express 流程。
copy_count 在 v1.1 只作为数据结构能力保留，默认每张具体候选 1 份，不展开成特殊流派。
成果率展示只做轻量估算，不做复杂模拟器。
成果率不预测“会选择哪个行动”；行动倾向竞争已经在压力积攒结束时决出。
```

---

## 5. 核心原则：10 费基础回合优先

上一版草案曾提出：

```text
每类候选卡 grasp 时都有一个小的即时身份效果，express 时有主要效果。
```

该方向现在不采用。

原因：

```text
如果每张普通候选卡进入工作记忆时都立刻生效，玩家体验会偏向“满地战吼 / 入场触发”的特殊流派。
这更像酒馆战棋中的特定经济或养成流派，而不是 10 费回合的基础体验。
```

v1.1 采用以下原则：

```text
大多数普通候选卡：
- grasp = 买入 / 暂存 / 占格；
- 本身不立刻改变大局；
- 价值来自后续 express、keep、discard、core_trigger 或自动执行环节。

少数特殊候选卡：
- grasp 时可以有正面或负面即时影响；
- 例如 emotion 污染，或未来某些特殊流派卡。

refresh：
- 不再只是重建当前列表；
- 从当前压力积攒环节的有限候选库存池中受控随机抽取候选；
- grasp 会把候选从库存池移到 working_memory；
- discard / express 等操作再决定候选何时回池。
```

策划翻译：

```text
基础 10 费回合的乐趣不是“所有卡买了就触发”，而是：
我在有限经济下刷到了什么、买了什么、暂存了什么、卖了什么、保留了什么，
最后这些东西如何进入自动执行。
```

因此 Pressure Encounter v1.1 应优先还原：

```text
emergence_pool = 当前刷出的浮现候选页面
candidate_stock = 当前压力积攒环节的有限候选库存池
working_memory = 手牌 / 场面占格
focus_points = 金币 / 可用注意力
refresh = 刷酒馆 / 再想一下
grasp = 买入 / 抓住一个念头
discard = 卖掉 / 放弃一个念头，腾格子并回池
keep = 冻结关键件
express = 把暂存件转化为当前局势收益，并进入 used
core_trigger = 核心成型
dominant_action = 行动倾向竞争后的胜出行动
auto_execution = 自动战斗 / 红色检定式集中释放
outcome_rate = dominant_action 的成果率预期
```

---

## 6. 参考 Python 项目的数据架构取向

Python 参考项目的 `CardManager` 使用统一的 `piles` 字典管理不同位置：`deck`、`draw_pile`、`discard_pile`、`hand`、`exhaust_pile`。抽牌不是复制生成，而是从 `draw_pile` 移动到 `hand`；弃牌、消耗、洗牌也都是不同 pile 之间的移动。

v1.1 不照搬战斗牌堆，但采用相同的边界思想：

```text
候选不是凭空刷新生成；
候选在几个位置之间移动；
位置变化本身就是玩法规则。
```

Pressure Encounter v1.1 建议使用类似结构：

```gdscript
var candidate_piles := {
  "stock": [],            # 当前压力积攒环节的有限候选库存池
  "emergence_pool": [],   # 当前刷出的候选
  "working_memory": [],   # 已抓住 / 买入的候选
  "used": [],             # 已表达 / 已转化为局势收益的候选
  "discarded": []         # 已放弃，可回 stock 的候选
}
```

说明：

```text
不一定要立刻改成完整类；也可以在现有字段上实现同等语义。
但规格层面必须明确：候选具有库存与位置，不是每次 refresh 复制一份新候选。
```

---

## 7. 已确认操作语义

### 7.1 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
```

v1.1 固定方向：

```text
大多数普通卡 grasp 时不立刻触发强数值效果。
grasp 的基础成本是 focus 与 working_memory 占格。
grasp 后该候选从 emergence_pool 移到 working_memory。
grasp 后该候选不再留在 stock 中，不会被当前压力积攒环节的 refresh 再刷出来。
少数特殊卡可以在 grasp 时产生正负即时影响，例如 emotion 进入意识后污染。
```

### 7.2 keep

```text
keep = 冻结关键件。
```

v1.1 固定规则：

```text
keep 不消耗 focus。
keep 来源为 working_memory 中的卡。
keep 后该卡进入 kept_cards 或标记 kept。
下一压力积攒环节开始时，该卡仍留在 working_memory。
该卡继续占用 working_memory。
keep 不触发额外收益。
keep 不使该候选回 stock。
```

策划理由：

```text
酒馆战棋冻结不花金币；
冻结的成本不是金币，而是牺牲下一轮部分候选空间。
Pressure Encounter 中对应的成本就是继续占用工作记忆格。
```

### 7.3 refresh

```text
refresh = 刷酒馆 / 从有限候选库存中搜索下一批浮现候选。
```

v1.1 固定规则：

```text
refresh 消耗 focus。
refresh 增加 pressure。
refresh 从当前压力积攒环节的 stock 中受控随机抽取一批候选，写入 emergence_pool。
refresh 不从 working_memory 抽卡。
refresh 不从 used 抽卡，除非后续规则明确 used 会回 stock。
refresh 不跨压力积攒环节抽卡。
refresh 不引入全局随机事件池。
同一 seed 下 refresh 结果稳定。
```

策划理由：

```text
酒馆战棋里的刷新不是复制新随从，而是在有限随从池里展示一批候选。
你买走一个随从，它就暂时离开池子；你卖掉它，它才回池。
Pressure Encounter 中也应如此：你抓住一个念头，它已经占据你的工作记忆，不应该还在下一次 refresh 中重复浮现。
```

### 7.4 discard

```text
discard = 卖掉 / 放弃一个念头，腾格子并回池。
```

v1.1 固定方向：

```text
discard 不消耗 focus。
discard 从 working_memory 或 emergence_pool 移除卡。
如果 discard 的来源是 working_memory，则该候选回到当前压力积攒环节的 stock。
如果 discard 的来源是 emergence_pool，则该候选仍留在当前 stock，或视为没有被买走。
discard 释放 working_memory 格。
discard 不产生 focus 返还，因为 v1.1 仍不新增第二资源。
```

### 7.5 express

```text
express = 把暂存组件转化为当前局势收益。
```

v1.1 固定方向：

```text
express 消耗 focus。
express 应用该候选的主要效果。
express 后从 working_memory 移除，释放工作记忆格。
express 后候选进入 used。
express 后不在当前压力积攒环节立刻回 stock。
该候选只可能在后续压力积攒环节重新进入 stock，模拟“局势变化后类似念头重新浮现”。
```

玩家体验理由：

```text
玩家刚刚已经把这个念头说出口 / 做出来了，
它不应该马上又像没发生过一样重新浮现。
但经过一次自动执行、局势变化后，类似判断可以在新的压力阶段重新进入意识。
```

---

## 8. 重复类似候选的后续价值

v1.1 默认每张具体候选 1 份，不主动追求“同一候选多份刷出”的体验。

但后续拓展框架时，重复类似候选非常有价值：

```text
同一个情绪反复浮现；
同一种恐惧不断占据工作记忆；
同一个判断以不同措辞重复出现；
同一种冲动不断挤掉其他念头。
```

玩家体验上，这可以塑造：

```text
我不是随机又看见一张重复牌；
而是我的大脑真的被同一种情绪 / 想法 / 执念占据了。
```

因此规格保留两层结构：

```text
v1.1 当前实现：
- 支持 copy_count 字段或等价结构能力；
- 默认每张具体候选 1 份；
- 不围绕重复候选做平衡。

后续扩展：
- 可以让某类候选拥有多个 copy；
- 可以用 candidate_family 表示“类似念头”；
- 可以让压力、污染或角色状态提高某个 candidate_family 的出现密度；
- 用重复出现来表现反刍、执念、强迫性回想或情绪占据。
```

这不是 v1.1 的特殊流派，而是未来心理表现力的重要空间。

---

## 9. 压力积攒环节与自动执行环节

### 9.1 压力积攒环节

玩家在这一环节中可以：

```text
refresh：继续搜索候选，但压力上升。
grasp：买入 / 抓住候选，占用工作记忆。
discard：放弃候选，释放格子并回池。
keep：冻结关键件，不花 focus，但继续占格。
express：把候选转化为局势收益，进入 used。
quiet：处理 emotion 污染。
```

这一环节的玩家体验目标：

```text
我还在控制局面；
我还能继续搜索、暂存、取舍；
但每次刷新和犹豫都让压力更接近爆发。
```

### 9.2 自动执行环节

触发条件可以是：

```text
focus_points 耗尽；
pressure 到达阈值；
压力节点达到强制执行点；
系统进入类似红色检定的不可回避行动。
```

自动执行环节做：

```text
锁定 working_memory、used、triggered_cores、action_tendency_tracks 与 situation_tracks。
不再允许玩家继续 refresh / grasp / discard。
先根据 action_tendency_tracks 选出 dominant_action。
再根据 dominant_action、pressure、ally_trust、triggered_cores 等结构计算该行动的 outcome_rate / 成果率预期。
展示自动执行过程，让局势按步骤展开。
集中释放前面压力积攒环节产生的结构。
```

这一环节的玩家体验目标：

```text
我不能再继续准备了；
角色必须行动；
我已经知道角色会做什么，并带着这个行动的成果率，看它如何一步步变成现实。
```

### 9.3 自动执行不是事后回放

v1.1 必须修正一个表述误差：自动执行不应主要被理解为“回放”。

```text
回放 = 事情已经结束后，系统再解释刚才发生了什么。
自动执行过程展示 = 事情正在不可避免地发生，玩家带着预期成果率观看它展开。
```

它更接近酒馆战棋：

```text
你结束酒馆操作后，已经不能再干预。
自动战斗开始前，胜负方向已经由你的阵容大致决定。
如果插件显示你 73% 胜率，你会带着这个预期看自动战斗展开。
快感来自：
- 我已经知道系统会按这套阵容去打；
- 我知道这套阵容大概有多大概率打赢；
- 但过程仍然会一步步发生；
- 每个触发、碰撞、死亡、翻盘都在验证或打破这个预期。
```

Pressure Encounter 中对应的体验是：

```text
行动倾向竞争已经结束：角色会选择【强硬干预】。
系统显示：【强硬干预】成功控制局面的成果率 62%。
然后自动执行开始：角色开口、推进、迟疑、被情绪干扰、同伴是否跟上、局势是否被压住。
玩家不能再改操作，但会带着“这次强硬干预大概能不能成”的预期观看自动执行。
```

因此，v1.1 的自动执行顺序应是：

```text
1. 进入不可干预状态。
2. 根据行动倾向轨确定 dominant_action。
3. 展示 dominant_action 的 outcome_rate / 成果率预期。
4. 展示自动执行过程。
5. 展示最终后果。
6. 提供简短原因摘要，解释哪些积攒结构影响了行动与成果率。
```

原因摘要不是核心快感本身，只是帮助玩家理解。
核心快感来自“已确定行动 + 带着该行动成果率看事情发生”。

### 9.4 环节切换后的回池规则

```text
当前压力积攒环节内：
- grasp 的卡不回 stock。
- express 的卡进入 used，不回 stock。
- discard 的卡回 stock。

自动执行环节后：
- used 中的部分候选可以根据下一压力阶段规则重新进入新 stock。
- kept / working_memory 中的卡可以继续占格进入下一压力积攒环节。
- 这模拟“局势释放后，某些念头可能以新的形式重新浮现”。
```

v1.1 不需要做复杂回池条件，只需要保留这个阶段边界。

---

## 10. v1 实现观察

当前 v1 的实现形态可以概括为：

```text
1. grasp 对 observation / emotion 有明显收益。
2. express 处理 evidence / technique / relationship 的主要效果。
3. quiet 主要处理 emotion，并在 hands_shaking 上提供 steady_response +1。
4. refresh 有 pressure +1 代价，并重建当前节点基础候选池。
5. keep 可以把工作记忆卡保留到下一节点，但当前仍消耗 focus；v1.1 已确认应改为 0 focus。
6. v1 没有有限库存语义；v1.1 已确认应增加当前压力积攒环节 candidate stock。
7. v1 的自动结算更像结尾结果；v1.1 需要把它理解为“已确定行动 + 带成果率的自动执行过程展示”。
8. resolution_log 已有固定管线标签，但仍偏 debug summary。
```

按新的 v1.1 方向，当前实现的问题不是“所有卡 grasp 不够强”，而是：

```text
基础回合的买入、占格、有限库存、刷新、保留、表达、自动执行之间的取舍是否足够清楚？
```

---

## 11. 审查维度

### 11.1 候选卡基础身份

目标不是让每张卡买入即触发，而是让每类卡在“为什么值得买 / 为什么值得留 / 什么时候表达 / 什么时候放弃”上有身份。

| 类型 | v1.1 基础身份 |
|---|---|
| observation | 找行动窗口；主要服务 observation_window 与 forceful_response |
| emotion | 占格污染；不处理会推进 panic_spiral，quiet 后可提取真实风险信息 |
| relationship | 关系件；主要服务 ally_trust 与最终配合描述，买入本身不必强触发 |
| technique | 程序件；主要服务 steady_response、压力控制或表达效率 |
| evidence | 事实件；主要在 express 后改变行动倾向或 pressure |

### 11.2 操作差异

需要审查：

```text
grasp 是否像“买入 / 暂存 / 占格 / 从池中拿走”？
express 是否像“把组件转化为局势收益，并进入 used”？
quiet 是否像“处理污染，而不是免费删除坏牌”？
keep 是否像“冻结关键件”，而不是亏动作？
discard 是否像“卖掉腾格子，并让候选回池”？
refresh 是否像“从有限库存池刷下一批候选”，而不是复制重置？
```

### 11.3 经济压力

当前经济参数：

```text
每个压力积攒环节 focus_points = 3
working_memory = 3
refresh = focus -1, pressure +1，从 stock 受控随机抽候选
keep = 0 focus，但继续占 working_memory
pressure_limit = 6
copy_count = 支持字段，默认每张具体候选 1 份
```

需要审查：

```text
3 点 focus 是否足够像一个压缩后的 10 费回合？
working_memory 3 格是否足够制造占格压力？
有限 stock 是否能让 grasp / discard / refresh 更有重量？
refresh + pressure + 随机候选批次是否足够像“花钱刷核心但局势恶化”？
keep 免费但占格，是否足够像冻结？
copy_count 默认 1 是否足够验证 v1.1，而不提前引入重复候选平衡？
```

### 11.4 自动执行过程展示

当前 v1 已有固定步骤：

```text
LOCK_MEMORY
CHECK_CORES
SUMMARIZE_TENDENCIES
CHOOSE_DOMINANT_TENDENCY
APPLY_PRESSURE_MODIFIER
APPLY_ALLY_TRUST_MODIFIER
BUILD_FINAL_RESULT
WRITE_RESOLUTION_LOG
```

v1.1 应改造这些步骤的体验顺序：

```text
1. LOCK_IN：进入不可干预状态。
2. CHOOSE_DOMINANT_ACTION：根据行动倾向轨确定角色会采取的行动。
3. SHOW_OUTCOME_RATE：展示 dominant_action 的成果率。
4. EXECUTE_SEQUENCE：展示自动执行过程。
5. FINAL_CONSEQUENCE：展示最终后果。
6. CAUSE_SUMMARY：简短解释关键影响来源。
```

需要审查：

```text
dominant_action 是否让玩家明确“角色已经要这样行动了”？
outcome_rate 是否只评估该行动能否成功，而不是预测多种行动分布？
成果率是否足够让玩家带着预期观看过程？
自动执行是否像事情正在发生，而不是事后回放？
过程是否能表现“我已经不能干预了”？
最终后果是否有红色检定式不可逆感？
原因摘要是否足够解释，而不抢走过程展示的快感？
```

---

## 12. v1.1 可接受改动范围

v1.1 可以做：

```text
1. 调整候选卡效果表。
2. 调整 grasp / express / quiet / keep / refresh 的局部收益或日志。
3. 为当前压力积攒环节增加有限候选库存池 stock。
4. 为 refresh 增加受控随机抽取，但只限当前 stock。
5. 支持 copy_count 或等价结构能力，但默认每张具体候选 1 份。
6. 调整少量参数，例如 focus_points、working_memory_limit、pressure_limit、每次 refresh 显示的候选数量。
7. 增加轻量 outcome_rate / 成果率展示，且 outcome_rate 只对应 dominant_action。
8. 改造 resolution_log，使其服务“自动执行过程展示”，而不是事后回放。
9. 增加针对机制质量的 GUT 测试。
10. 更新 status 文档。
```

v1.1 不应做：

```text
1. 新 UI 主界面。
2. 新地图接入。
3. 新轨道。
4. 新 core_trigger。
5. 跨遭遇随机事件池。
6. 全局随从池。
7. 稀有度 / Tavern Tier / 权重成长。
8. Factory。
9. 特殊流派。
10. 围绕重复候选做平衡或流派。
11. 复杂胜率模拟器。
12. 完整战斗预测器。
13. 多行动结果分布预测器。
```

---

## 13. 问答式审查问题池

### 13.1 已确认：基础回合目标

```text
Q1：v1.1 是否明确以“酒馆战棋 10 费回合基础体验”为目标，而不是做特殊流派？
```

结论：是。

### 13.2 已确认：keep 的价值

```text
Q2：keep 是否需要更像“冻结关键件”？
```

结论：是。

规则：

```text
keep 不消耗 focus。
keep 的成本是继续占用 working_memory。
```

### 13.3 已确认：refresh 与有限库存

```text
Q3：refresh 如何更像“刷酒馆找核心”？
```

结论：使用当前压力积攒环节有限候选库存池 + 受控随机。

规则：

```text
每个压力积攒环节初始化自己的 stock。
refresh 从 stock 中随机抽取当前 emergence_pool。
grasp 会把候选从 stock / emergence_pool 移到 working_memory。
discard 可以让候选回 stock。
express 进入 used，不在当前压力积攒环节立刻回 stock。
测试中必须可注入 seed 或固定 RNG。
```

### 13.4 已确认：express 后是否回池

```text
Q4：express 后卡是否应从 working_memory 移除，并进入 used 而不是立刻回 stock？
```

结论：是。

规则：

```text
express 消耗 focus。
express 应用主要效果。
express 后从 working_memory 移除。
express 后进入 used。
express 不在当前压力积攒环节立刻回 stock。
express 的候选只可能在后续压力积攒环节重新进入 stock。
```

### 13.5 已确认：阶段循环

```text
Q5：Pressure Encounter 的主循环是否应是“压力积攒环节 ↔ 自动执行环节”？
```

结论：是。

玩家体验解释：

```text
压力积攒环节像酒馆操作环节，也像极乐迪斯科枪战前一系列白色检定式对话与信息积累。
自动执行环节像自动战斗，也像无法避免的红色检定式集中释放。
```

### 13.6 已确认：候选复制数

```text
Q6：每张候选在 stock 中是否允许多份 copy？
```

结论：v1.1 支持数据结构上的 copy_count，但默认每张具体候选 1 份。

玩家体验解释：

```text
当前进度下，不需要让玩家频繁刷到同一具体候选。
但后续拓展时，重复出现的类似候选可以表现“同一情绪 / 想法反复占据大脑”。
```

### 13.7 已确认：自动执行不是回放

```text
Q7：自动执行环节应该是事后回放，还是带成果率的过程展示？
```

结论：带成果率的过程展示。

玩家体验解释：

```text
玩家进入自动执行时已经不能干预。
系统先展示已经胜出的 dominant_action，以及该行动的成果率。
然后玩家带着这个预期观看事情一步步发生。
快感来自“我知道角色会这样做，也知道大概有多大概率做成，但过程仍然会展开并验证或打破我的预期”。
```

### 13.8 已确认：成果率对象

```text
Q8：成果率显示的是多种行动倾向的分布，还是最终胜出行动的成功率？
```

结论：最终胜出行动的成功率。

玩家体验解释：

```text
压力积攒环节结束时，多种行动倾向已经竞争完毕。
自动执行环节开始时，玩家应该已经知道角色会采取什么 dominant_action。
成果率显示的是这个 dominant_action 能不能成功达成目标。
```

---

## 14. 下一步问答入口

下一个需要确认的问题：

```text
从玩家体验看，成果率应该用什么形式展示给玩家？

A. 明确百分比：例如“强硬干预成功率 62%”。
B. 百分比 + 风险提示：例如“强硬干预成功率 62%，主要风险：压力过高、同伴未跟上”。
C. 只显示自然语言：例如“这次强硬干预有把握，但局势仍可能失控”。
```

建议倾向：B。

理由：

```text
玩家已经知道角色会采取 dominant_action；
百分比提供类似胜率插件的观看快感；
风险提示能让玩家理解自动执行中哪些因素最可能造成翻车，而不需要展开复杂预测器。
```
