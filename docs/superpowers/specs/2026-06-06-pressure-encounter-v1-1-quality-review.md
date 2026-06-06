# Pressure Encounter v1.1 机制质量审查规格

## 文档元信息

```text
文档类型：机制质量审查规格 / v1.1 迭代草案
创建日期：2026-06-06
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
这个已经跑通的最小循环，是否已经产生接近自走棋式的取舍和构筑感？
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
在不扩大系统边界的前提下，审查并补强候选卡效果、玩家操作差异、经济压力和自动结算回放，使 Pressure Encounter v1 从“能跑通”推进到“能验证初步手感”。
```

更短定义：

```text
v1.1 是机制手感补强，不是新系统扩张。
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
Combat / Rest / Event / Boss 替换
完整 UI 重做
```

说明：

```text
默认地图接入会验证“入口”；v1.1 要验证“机制质量”。
如果机制质量尚未稳定，过早接地图会让后续调试成本上升。
```

---

## 4. v1 实现观察

当前 v1 的实现形态可以概括为：

```text
1. grasp 主要对 observation / emotion 产生强效果。
2. express 才处理 evidence / technique / relationship 的主要效果。
3. quiet 主要处理 emotion，并在 hands_shaking 上提供 steady_response +1。
4. refresh 有 pressure +1 代价，并重建当前节点基础候选池。
5. keep 可以把工作记忆卡保留到下一节点，但当前 UI / 日志层面的决策价值还比较薄。
6. resolution_log 已有固定管线标签，但更接近 debug summary，叙事回放感仍可补强。
```

这意味着 v1.1 不应该先问“要不要接地图”，而应该先问：

```text
当前 grasp / express / quiet / keep / refresh 是否真的形成互相不同的取舍？
```

---

## 5. 审查维度

### 5.1 候选卡效果密度

需要审查：

```text
observation 是否过强？
emotion 是否已经足够像“污染 + 信息”？
relationship 是否太像单纯 ally_trust +1？
technique 是否太像 steady_response +1？
evidence 是否太像 forceful_response +1？
```

目标不是让每张卡都复杂，而是让每类卡至少有清晰的机制身份。

候选机制身份建议：

| 类型 | 当前倾向 | v1.1 应审查的身份 |
|---|---|---|
| observation | 发现行动窗口 | 搜索 / 成型 forceful 的主要燃料 |
| emotion | 污染与身体信号 | 未处理会成型 panic，处理后能提取信息 |
| relationship | 同伴信任 | 是否应更明显影响结算可信度 |
| technique | 程序与方法 | 是否应稳定 pressure 或提高操作效率 |
| evidence | 事实锚点 | 是否应区分“稳住”与“强硬”的方向 |

### 5.2 操作差异

需要审查：

```text
grasp 是否只是“买入卡”？
express 是否只是“打出卡”？
quiet 是否只是 emotion 专用 cleanse？
keep 是否真的有冻结关键件的价值？
discard 是否只是清格子，还是也影响连锁断裂？
refresh 是否已经产生“刷牌找核心”的压力？
```

v1.1 不一定全部修改，但必须明确每个操作在玩家心智中的定位。

### 5.3 经济压力

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
3 点 focus 是否足够让玩家觉得紧？
working_memory 3 格是否足够制造占格压力？
refresh + pressure 是否足够像“花钱刷核心但局势恶化”？
keep 花 1 focus 是否太贵或太弱？
```

v1.1 应优先通过参数和效果表微调，不引入新资源。

### 5.4 自动结算回放

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

## 6. v1.1 可接受改动范围

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
```

---

## 7. 问答式审查问题池

以下问题不是一次性全部回答，而是按优先级逐个收敛。

### 7.1 第一优先级：候选卡操作差异

```text
Q1：v1.1 是否应该优先补强“grasp 与 express 的差异”？
```

当前风险：

```text
grasp 主要对 observation / emotion 有明显收益；
relationship / technique / evidence 更像是等 express 才生效；
这可能导致玩家把非 observation / emotion 卡理解为“先占格，后点一次”的延迟按钮。
```

可能方向：

```text
A. 保持现状：grasp = 暂存，express = 生效。
B. 轻微补强：每类卡 grasp 时都有一个小的即时身份，express 时有主要效果。
C. 重做操作语义：grasp 只占格不生效，express 才全部生效。
```

建议倾向：B。

理由：

```text
v1.1 不应重做系统；
但每类卡 grasp 时至少应该让玩家感到“抓住这个念头本身就改变了局面”。
```

### 7.2 第二优先级：keep 的价值

```text
Q2：keep 是否需要在 v1.1 获得更明确的收益？
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

建议倾向：B 或 C，待问答收敛。

### 7.3 第三优先级：refresh 压力

```text
Q3：refresh 现在的代价是否足够？
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

v1.1 不能引入随机池，但可以让 refresh 日志和候选轮换更明确。

### 7.4 第四优先级：日志是否像回放

```text
Q4：resolution_log 是先优化结构，还是先等机制效果补强后再优化？
```

建议倾向：先补机制效果，再优化日志。

理由：

```text
日志应该解释机制，而不是替机制制造不存在的深度。
```

---

## 8. 首轮建议结论

v1.1 第一轮建议只处理一个核心方向：

```text
补强每类候选卡在 grasp / express 两阶段的身份差异。
```

暂不处理：

```text
默认地图接入
参数大改
日志大改
keep 大改
refresh 大改
```

原因：

```text
如果候选卡本身没有足够差异，后续经济、日志和地图接入都会缺少支撑。
```

---

## 9. 下一步问答入口

第一个需要确认的问题：

```text
v1.1 是否采用“两阶段候选卡效果”原则？

也就是：
- grasp：抓住这个念头时，立刻产生一个小的身份效果；
- express：把它表达 / 付诸当前局面时，产生主要效果。
```

建议答案：是。

如果确认，下一轮规格将继续收敛：

```text
每类卡的 grasp 小效果与 express 主效果分别是什么？
```
