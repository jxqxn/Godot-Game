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
这个已经跑通的最小循环，是否能更接近“酒馆战棋 10 费回合”的基础体验？
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
```

后续问题必须基于当前项目最新状态提出。已经合入并通过测试的结构，不作为 v1.1 开放问题反复追问。

---

## 2. v1.1 一句话目标

```text
在不扩大系统边界的前提下，把 Pressure Encounter v1 的操作体验从“能跑通的事件卡牌化原型”，推进到更接近“酒馆战棋 10 费回合基础体验”的候选池搜索、买入暂存、占格取舍、关键件保留、刷新找核心与自动结算。
```

更短定义：

```text
v1.1 先还原 10 费回合基础体验，不急着做特殊流派。
```

---

## 3. 本阶段非目标

v1.1 不做：

```text
默认地图接入
正式地图 UI
新 DebugScene
随机事件池
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
```

说明：

```text
默认地图接入会验证“入口”；v1.1 要验证“机制质量”。
特殊流派会验证“高级玩法变体”；v1.1 要先验证基础回合。
```

---

## 4. 核心修正：从“两阶段全卡生效”改为“10 费基础回合”

上一版草案曾提出：

```text
每类候选卡 grasp 时都有一个小的即时身份效果，express 时有主要效果。
```

该方向现在暂不采用。

原因：

```text
如果每张普通候选卡进入工作记忆时都立刻生效，玩家体验会偏向“满地战吼 / 入场触发”的特殊流派。
这更像酒馆战棋中的特定经济或养成流派，而不是 10 费回合的基础体验。
```

v1.1 改为以下原则：

```text
大多数普通候选卡：
- grasp = 买入 / 暂存 / 占格；
- 本身不立刻改变大局；
- 价值来自后续 express、keep、discard、core_trigger 或最终结算。

少数特殊候选卡：
- grasp 时可以有正面或负面即时影响；
- 例如 emotion 污染，或未来某些特殊流派卡。

v1.1 不系统化特殊流派，只保留少量必要的即时影响来支撑压力机制。
```

策划翻译：

```text
基础 10 费回合的乐趣不是“所有卡买了就触发”，而是：
我在有限经济下刷到了什么、买了什么、暂存了什么、卖了什么、保留了什么、最后这些东西如何进入自动战斗。
```

因此 Pressure Encounter v1.1 应优先还原：

```text
浮现区 = 酒馆候选池
working_memory = 手牌 / 场面占格
focus_points = 金币
refresh = 刷酒馆
keep = 冻结关键件
express = 把暂存件转化为当前局势收益
discard = 卖掉 / 腾格子
core_trigger = 核心成型
自动结算管线 = 自动战斗回放
```

---

## 5. v1 实现观察

当前 v1 的实现形态可以概括为：

```text
1. grasp 对 observation / emotion 有明显收益。
2. express 处理 evidence / technique / relationship 的主要效果。
3. quiet 主要处理 emotion，并在 hands_shaking 上提供 steady_response +1。
4. refresh 有 pressure +1 代价，并重建当前节点基础候选池。
5. keep 可以把工作记忆卡保留到下一节点，但决策价值还比较薄。
6. resolution_log 已有固定管线标签，但仍偏 debug summary。
```

按新的 v1.1 方向，当前实现的问题不是“所有卡 grasp 不够强”，而是：

```text
基础回合的买入、占格、刷新、保留、表达、结算之间的取舍是否足够清楚？
```

---

## 6. 审查维度

### 6.1 候选卡基础身份

目标不是让每张卡买入即触发，而是让每类卡在“为什么值得买 / 为什么值得留 / 什么时候表达 / 什么时候放弃”上有身份。

| 类型 | v1.1 基础身份 |
|---|---|
| observation | 找行动窗口；主要服务 observation_window 与 forceful_response |
| emotion | 占格污染；不处理会推进 panic_spiral，quiet 后可提取真实风险信息 |
| relationship | 关系件；主要服务 ally_trust 与最终配合描述，买入本身不必强触发 |
| technique | 程序件；主要服务 steady_response、压力控制或表达效率 |
| evidence | 事实件；主要在 express 后改变行动倾向或 pressure |

### 6.2 操作差异

需要审查：

```text
grasp 是否像“买入 / 暂存 / 占格”？
express 是否像“把组件转化为局势收益”？
quiet 是否像“处理污染，而不是免费删除坏牌”？
keep 是否像“冻结关键件”，而不是亏动作？
discard 是否像“卖掉腾格子”，而不是无意义删除？
refresh 是否像“刷酒馆找核心”，而不是重置按钮？
```

### 6.3 经济压力

当前经济参数：

```text
每节点 focus_points = 3
working_memory = 3
refresh = focus -1, pressure +1
3 个 pressure_node
pressure_limit = 6
```

需要审查：

```text
3 点 focus 是否足够像一个压缩后的 10 费回合？
working_memory 3 格是否足够制造占格压力？
refresh + pressure 是否足够像“花钱刷核心但局势恶化”？
keep 花 1 focus 是否太贵或太弱？
```

v1.1 应优先通过参数和效果表微调，不引入新资源。

### 6.4 自动结算回放

当前已有固定步骤：

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

需要审查：

```text
玩家看到的是“自动回放”，还是“debug 字段列表”？
每一步是否解释了玩家此前操作如何导致结果？
core_trigger 是否被表现为质变，而不是普通 +1？
pressure / ally_trust 是否在结果中有体感差异？
```

v1.1 可以优化日志结构和文本，但不做完整 UI 重做。

---

## 7. v1.1 可接受改动范围

v1.1 可以做：

```text
1. 调整候选卡效果表。
2. 调整 grasp / express / quiet / keep / refresh 的局部收益或日志。
3. 调整少量参数，例如 focus_points、working_memory_limit、pressure_limit。
4. 增强 resolution_log 的自然语言解释。
5. 增加针对机制质量的 GUT 测试。
6. 更新 status 文档。
```

v1.1 不应做：

```text
1. 新系统。
2. 新 UI 主界面。
3. 新地图接入。
4. 新轨道。
5. 新 core_trigger。
6. 随机池。
7. Factory。
8. 特殊流派。
```

---

## 8. 问答式审查问题池

以下问题不是一次性全部回答，而是按优先级逐个收敛。

### 8.1 第一优先级：基础回合目标

```text
Q1：v1.1 是否明确以“酒馆战棋 10 费回合基础体验”为目标，而不是做特殊流派？
```

建议结论：是。

含义：

```text
大多数普通候选卡 grasp 时不立刻触发强效果；
核心乐趣来自有限 focus 下的 refresh / grasp / keep / discard / express 取舍；
少数特殊卡可以有正面或负面入场影响，但这不是 v1.1 主体。
```

### 8.2 第二优先级：普通卡 grasp 是否应弱化

```text
Q2：是否将大多数普通卡的 grasp 定义为“暂存 + 占格 + 轻日志”，而不是即时加轨道数值？
```

可能方向：

```text
A. 大多数普通卡 grasp 不加行动倾向，只进入 working_memory。
B. 大多数普通卡 grasp 给极小数值，例如 +0 或日志，不改变主轨道。
C. 保留 v1：observation / emotion grasp 有明显影响，其他类型主要 express 生效。
```

建议倾向：A 或 C 的折中。

建议解释：

```text
observation 可以保留轻度 grasp 价值，因为“看见行动窗口”本身会影响判断；
emotion 可以保留负面 grasp 价值，因为污染必须能成型；
relationship / technique / evidence 更适合 express 后生效。
```

### 8.3 第三优先级：keep 的价值

```text
Q3：keep 是否需要更像“冻结关键件”？
```

当前风险：

```text
keep 消耗 1 focus，并让卡继续占工作记忆格；
如果没有额外收益，玩家可能觉得它只是亏动作。
```

可能方向：

```text
A. keep 仍只做保留，不加收益。
B. keep 下个节点开始时给该卡一次小折扣或日志强化。
C. keep 不消耗 focus。
```

建议倾向：C。

理由：

```text
酒馆战棋冻结不花金币；
如果 keep 对应“冻结关键件”，v1.1 可以考虑 keep 不消耗 focus，但继续占工作记忆格，成本来自占格而不是金币。
```

### 8.4 第四优先级：refresh 搜索感

```text
Q4：refresh 现在的代价是否足够像“刷酒馆”？
```

当前规则：

```text
refresh = focus -1, pressure +1, 重建当前节点候选池并过滤工作记忆。
```

需要确认：

```text
这是否足够像“刷酒馆找核心”？
还是因为当前候选池固定，refresh 缺乏搜索感？
```

v1.1 不能引入随机池，但可以让 refresh 在当前节点的固定候选序列中轮换显示，形成确定性的搜索感。

### 8.5 第五优先级：日志是否像回放

```text
Q5：resolution_log 是先优化结构，还是先等机制效果补强后再优化？
```

建议倾向：先补基础回合操作，再优化日志。

理由：

```text
日志应该解释机制，而不是替机制制造不存在的深度。
```

---

## 9. 首轮建议结论

v1.1 第一轮建议只处理一个核心方向：

```text
把目标从“所有候选卡两阶段生效”改为“还原酒馆战棋 10 费回合基础体验”。
```

暂不处理：

```text
默认地图接入
特殊流派
参数大改
日志大改
新增核心
新增轨道
```

当前应先收敛：

```text
基础回合里，grasp / express / keep / discard / refresh 各自对应什么策划动作？
```

---

## 10. 下一步问答入口

第一个需要确认的问题：

```text
v1.1 是否明确采用“10 费基础回合优先”原则？

也就是：
- 大多数普通候选卡 grasp 时只是暂存与占格；
- 少数卡可以有即时正负影响，但这属于特殊卡或必要压力机制；
- v1.1 不急着做类似养酒馆流派的入场触发玩法；
- 优先还原 refresh / grasp / keep / discard / express 的基础取舍。
```

建议答案：是。

如果确认，下一轮规格将继续收敛：

```text
grasp / express / keep / discard / refresh 在 Pressure Encounter 里分别对应酒馆战棋 10 费回合中的哪个玩家动作？
```
