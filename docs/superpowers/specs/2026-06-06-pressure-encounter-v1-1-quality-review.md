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
13. v1.1 明确以“酒馆战棋 10 费回合基础体验”为优先目标，而不是特殊流派。
14. v1.1 中大多数普通候选卡 grasp = 暂存 + 占格，不是买入即触发。
15. v1.1 中少数特殊候选卡可以有即时正负影响，例如 emotion 污染。
16. v1.1 中 keep = 冻结关键件，不消耗 focus；成本是继续占用 working_memory。
17. v1.1 中 refresh 使用受控随机与有限候选库存池，而不是简单重建列表。
```

后续问题必须基于当前项目最新状态提出。已经确认并写入规格的结构，不作为 v1.1 开放问题反复追问。

---

## 2. v1.1 一句话目标

```text
在不扩大系统边界的前提下，把 Pressure Encounter v1 的操作体验从“能跑通的事件卡牌化原型”，推进到更接近“酒馆战棋 10 费回合基础体验”的候选池搜索、买入暂存、占格取舍、有限库存、关键件保留、刷新找核心与自动结算。
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
```

说明：

```text
默认地图接入会验证“入口”；v1.1 要验证“机制质量”。
特殊流派会验证“高级玩法变体”；v1.1 要先验证基础回合。
有限候选库存池不是跨遭遇随机事件池；它只服务当前 pressure_node 内的 refresh / grasp / discard / express 流程。
```

---

## 4. 核心原则：10 费基础回合优先

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
- 价值来自后续 express、keep、discard、core_trigger 或最终结算。

少数特殊候选卡：
- grasp 时可以有正面或负面即时影响；
- 例如 emotion 污染，或未来某些特殊流派卡。

refresh：
- 不再只是重建当前列表；
- 从当前节点的有限候选库存池中受控随机抽取候选；
- grasp 会把候选从库存池移到 working_memory；
- discard / express 等操作再决定候选是否回池。
```

策划翻译：

```text
基础 10 费回合的乐趣不是“所有卡买了就触发”，而是：
我在有限经济下刷到了什么、买了什么、暂存了什么、卖了什么、保留了什么、最后这些东西如何进入自动战斗。
```

因此 Pressure Encounter v1.1 应优先还原：

```text
浮现区 = 酒馆候选池当前刷出的页面
candidate_stock = 当前节点有限候选库存池
working_memory = 手牌 / 场面占格
focus_points = 金币
refresh = 刷酒馆
grasp = 买入 / 抓住一个念头
discard = 卖掉 / 放弃一个念头，腾格子并回池
keep = 冻结关键件
express = 把暂存件转化为当前局势收益，是否回池待确认
core_trigger = 核心成型
自动结算管线 = 自动战斗回放
```

---

## 5. 参考 Python 项目的数据架构取向

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
  "stock": [],            # 当前 pressure_node 的有限候选库存池
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

## 6. 已确认操作语义

### 6.1 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
```

v1.1 固定方向：

```text
大多数普通卡 grasp 时不立刻触发强数值效果。
grasp 的基础成本是 focus 与 working_memory 占格。
grasp 后该候选从 emergence_pool 移到 working_memory。
grasp 后该候选不再留在 stock 中，不会被 refresh 再刷出来。
少数特殊卡可以在 grasp 时产生正负即时影响，例如 emotion 进入意识后污染。
```

### 6.2 keep

```text
keep = 冻结关键件。
```

v1.1 固定规则：

```text
keep 不消耗 focus。
keep 来源为 working_memory 中的卡。
keep 后该卡进入 kept_cards 或标记 kept。
下一 pressure_node 开始时，该卡仍留在 working_memory。
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

### 6.3 refresh

```text
refresh = 刷酒馆 / 从有限候选库存中搜索下一批浮现候选。
```

v1.1 固定规则：

```text
refresh 消耗 focus。
refresh 增加 pressure。
refresh 从当前 pressure_node 的 stock 中受控随机抽取一批候选，写入 emergence_pool。
refresh 不从 working_memory 抽卡。
refresh 不从 used 抽卡，除非后续规则明确 used 会回 stock。
refresh 不跨 pressure_node 抽卡。
refresh 不引入全局随机事件池。
同一 seed 下 refresh 结果稳定。
```

策划理由：

```text
酒馆战棋里的刷新不是复制新随从，而是在有限随从池里展示一批候选。
你买走一个随从，它就暂时离开池子；你卖掉它，它才回池。
Pressure Encounter 中也应如此：你抓住一个念头，它已经占据你的工作记忆，不应该还在下一次 refresh 中重复浮现。
```

### 6.4 discard

```text
discard = 卖掉 / 放弃一个念头，腾格子并回池。
```

v1.1 固定方向：

```text
discard 不消耗 focus。
discard 从 working_memory 或 emergence_pool 移除卡。
如果 discard 的来源是 working_memory，则该候选回到当前节点 stock。
如果 discard 的来源是 emergence_pool，则该候选仍留在当前节点 stock，或视为没有被买走。
discard 释放 working_memory 格。
discard 不产生 focus 返还，因为 v1.1 仍不新增第二资源。
```

策划理由：

```text
这对应酒馆战棋的卖出：它释放格子，并让该对象回到池中。
但 Pressure Encounter 暂不做金币返还，因为 focus 仍是压缩经济，不是完整酒馆经济。
```

---

## 7. 待收敛操作语义

### 7.1 express

待确认：

```text
express 是否应对应“把暂存组件转化为当前局势收益”？
```

建议方向：是。

待确认的关键不是是否消耗 focus，而是：

```text
express 后该候选是否回 stock？
```

可能规则：

```text
A. express 后移到 used，不回 stock。
   含义：这个念头已经被说出 / 做出，不能再被当作未处理候选刷出来。

B. express 后移到 used，并在节点结束后回 stock。
   含义：当前节点不能重复表达，但后续节点可能重新浮现类似念头。

C. express 后移除 working_memory 并立刻回 stock。
   含义：更像卖出，但会让 express 和 discard 边界变弱。
```

建议倾向：A。

理由：

```text
express 应该像“把组件转化为局势收益”。
它释放工作记忆格，但这个具体候选已被使用，不应马上回到 refresh 池里重复出现。
```

---

## 8. v1 实现观察

当前 v1 的实现形态可以概括为：

```text
1. grasp 对 observation / emotion 有明显收益。
2. express 处理 evidence / technique / relationship 的主要效果。
3. quiet 主要处理 emotion，并在 hands_shaking 上提供 steady_response +1。
4. refresh 有 pressure +1 代价，并重建当前节点基础候选池。
5. keep 可以把工作记忆卡保留到下一节点，但当前仍消耗 focus；v1.1 已确认应改为 0 focus。
6. v1 没有有限库存语义；v1.1 已确认应增加当前节点 candidate stock。
7. resolution_log 已有固定管线标签，但仍偏 debug summary。
```

按新的 v1.1 方向，当前实现的问题不是“所有卡 grasp 不够强”，而是：

```text
基础回合的买入、占格、有限库存、刷新、保留、表达、结算之间的取舍是否足够清楚？
```

---

## 9. 审查维度

### 9.1 候选卡基础身份

目标不是让每张卡买入即触发，而是让每类卡在“为什么值得买 / 为什么值得留 / 什么时候表达 / 什么时候放弃”上有身份。

| 类型 | v1.1 基础身份 |
|---|---|
| observation | 找行动窗口；主要服务 observation_window 与 forceful_response |
| emotion | 占格污染；不处理会推进 panic_spiral，quiet 后可提取真实风险信息 |
| relationship | 关系件；主要服务 ally_trust 与最终配合描述，买入本身不必强触发 |
| technique | 程序件；主要服务 steady_response、压力控制或表达效率 |
| evidence | 事实件；主要在 express 后改变行动倾向或 pressure |

### 9.2 操作差异

需要审查：

```text
grasp 是否像“买入 / 暂存 / 占格 / 从池中拿走”？
express 是否像“把组件转化为局势收益，并进入 used”？
quiet 是否像“处理污染，而不是免费删除坏牌”？
keep 是否像“冻结关键件”，而不是亏动作？
discard 是否像“卖掉腾格子，并让候选回池”？
refresh 是否像“从有限库存池刷下一批候选”，而不是复制重置？
```

### 9.3 经济压力

当前经济参数：

```text
每节点 focus_points = 3
working_memory = 3
refresh = focus -1, pressure +1，从 stock 受控随机抽候选
keep = 0 focus，但继续占 working_memory
3 个 pressure_node
pressure_limit = 6
```

需要审查：

```text
3 点 focus 是否足够像一个压缩后的 10 费回合？
working_memory 3 格是否足够制造占格压力？
有限 stock 是否能让 grasp / discard / refresh 更有重量？
refresh + pressure + 随机候选批次是否足够像“花钱刷核心但局势恶化”？
keep 免费但占格，是否足够像冻结？
```

### 9.4 自动结算回放

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

## 10. v1.1 可接受改动范围

v1.1 可以做：

```text
1. 调整候选卡效果表。
2. 调整 grasp / express / quiet / keep / refresh 的局部收益或日志。
3. 为当前 pressure_node 增加有限候选库存池 stock。
4. 为 refresh 增加受控随机抽取，但只限当前节点 stock。
5. 调整少量参数，例如 focus_points、working_memory_limit、pressure_limit、每次 refresh 显示的候选数量、每张候选在 stock 中的 copy 数。
6. 增强 resolution_log 的自然语言解释。
7. 增加针对机制质量的 GUT 测试。
8. 更新 status 文档。
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
```

---

## 11. 问答式审查问题池

以下问题不是一次性全部回答，而是按优先级逐个收敛。

### 11.1 已确认：基础回合目标

```text
Q1：v1.1 是否明确以“酒馆战棋 10 费回合基础体验”为目标，而不是做特殊流派？
```

结论：是。

### 11.2 已确认：keep 的价值

```text
Q2：keep 是否需要更像“冻结关键件”？
```

结论：是。

规则：

```text
keep 不消耗 focus。
keep 的成本是继续占用 working_memory。
```

### 11.3 已确认：refresh 与有限库存

```text
Q3：refresh 如何更像“刷酒馆找核心”？
```

结论：使用当前节点有限候选库存池 + 受控随机。

规则：

```text
每个 pressure_node 初始化自己的 stock。
refresh 从 stock 中随机抽取当前 emergence_pool。
grasp 会把候选从 stock / emergence_pool 移到 working_memory。
discard 可以让候选回 stock。
express 默认进入 used，不立刻回 stock，待确认。
测试中必须可注入 seed 或固定 RNG。
```

### 11.4 待确认：express 后是否回池

```text
Q4：express 后卡是否应从 working_memory 移除，并进入 used 而不是回 stock？
```

建议倾向：是。

理由：

```text
express 是“表达 / 使用”这个念头。
它应该释放工作记忆格，但不应该让同一个念头立刻回到 refresh 池里再次刷出。
这样 express 与 discard 的边界更清楚：
discard = 放弃并回池；
express = 使用并进入 used。
```

### 11.5 待确认：是否需要候选复制数

```text
Q5：每张候选在 stock 中是否允许多份 copy？
```

建议倾向：v1.1 先允许配置 copy_count，但默认每张 1 份。

理由：

```text
酒馆战棋同一随从在池中有有限个数；
Pressure Encounter 也可以保留这个数据结构能力；
但 v1.1 内容很少，默认每张 1 份最容易测试。
```

---

## 12. 下一步问答入口

下一个需要确认的问题：

```text
express 后候选是否进入 used，并且不立刻回 stock？

也就是：
- express 消耗 focus；
- express 应用主要效果；
- express 后从 working_memory 移除；
- 该候选进入 used；
- 它不会在当前节点后续 refresh 中再次出现；
- discard 才是让候选回 stock 的操作。
```

建议答案：是。
