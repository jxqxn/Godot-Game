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
外部参考：docs/superpowers/references/2026-06-06-daggerheart-hope-fear-mda.md
最高优先级玩法参照：炉石传说酒馆战棋
```

本规格用于 Pressure Encounter v1 合入后的第一轮机制质量审查。

v1.1 的目标不是扩大系统，而是让已经跑通的最小循环更接近酒馆战棋基础回合体验：

```text
压力积攒环节：像酒馆操作。
自动执行环节：像自动团战。
```

---

## 1. 当前已确认结论

以下内容已确认，后续提问不再重复追问：

```text
1. Pressure Encounter v1 已实现并合入 main。
2. v1 已通过完整 GUT。
3. v1 仍不接入默认地图。
4. v1.1 继续优先验证机制质量，不急着接默认地图。
5. v1.1 以炉石传说酒馆战棋 10 费回合基础体验为第一参照。
6. 大多数普通候选卡 grasp = 暂存 + 占格，不是买入即触发。
7. 少数特殊候选卡可以有即时正负影响，例如 emotion 污染。
8. keep = 冻结关键件，不消耗 focus；成本是继续占用 working_memory。
9. refresh 使用受控随机与有限候选库存池，而不是简单重建列表。
10. express 后候选进入 used，不在当前压力积攒环节立刻回 stock。
11. v1.1 支持数据结构上的 copy_count，但默认每张具体候选 1 份。
12. 重复类似候选主要作为后续塑造反刍、执念和情绪占据的扩展口。
13. 自动执行环节不是事后回放，而是带成果率预期的过程展示。
14. 操作结束时，行动倾向竞争已经决出 dominant_action。
15. outcome_rate 显示的是 dominant_action 的主目标成功率，不是多行动结果分布。
16. 不再把结果僵硬画成四象限；Daggerheart 只提供“成功率之外还有附带收益/损失”的启发。
17. 自动执行的重点是：胜率与实际结果之间，还有许多潜在收益和损失需要通过过程展示。
```

---

## 2. 玩家体验主循环

Pressure Encounter 的最高层循环是：

```text
压力积攒环节
→ 自动执行环节
→ 新一轮压力积攒环节
→ 新一轮自动执行环节
```

对应酒馆战棋：

```text
酒馆操作环节
→ 自动团战环节
→ 下一轮酒馆操作环节
→ 下一轮自动团战环节
```

对应《极乐迪斯科》枪战段落：

```text
一系列白色检定 / 对话选择 / 信息浮现
→ 压力逐渐积累
→ 玩家最终无法避免进入红色检定式强制行动节点
→ 先前积攒下来的压力、误判、关系、装备、技能与行动倾向集中进入自动执行
→ 局势释放，进入下一个压力状态
```

玩家应该感到：

```text
我刚才还能操作、搜索、暂存、保留、放弃、表达。
现在准备阶段结束了。
角色必须行动。
我带着一个成果率，看这套积累如何不可避免地展开。
```

---

## 3. v1.1 一句话目标

```text
在不扩大系统边界的前提下，把 Pressure Encounter v1 从“能跑通的事件卡牌化原型”，推进到更接近酒馆战棋基础回合的候选池搜索、买入暂存、有限库存、占格取舍、冻结关键件、胜率预期与自动执行过程展示。
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
完整战斗预测器
复杂胜率模拟器
多行动结果分布预测器
硬编码 Hope/Fear 四象限结果表
```

说明：

```text
Daggerheart 只能帮助我们理解“成功/失败之外还有过程收益和过程损失”。
但 Pressure Encounter 的自动执行体验必须优先参考酒馆战棋自动团战。
```

---

## 5. 核心原则：酒馆战棋基础回合优先

v1.1 的基础类比：

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
outcome_rate = dominant_action 的主目标成功率
auto_execution_events = 自动执行过程中发生的收益/损失/触发/伤害/成长/保留事件
final_consequence = 主目标结果 + 实际过程价值
```

玩家操作完毕后，系统不应该只给一个简单结果：

```text
成功 / 失败
```

而应该进入类似酒馆战棋自动团战的过程：

```text
行动已锁定。
成果率已显示。
过程开始自动展开。
玩家不能干预，但会看见触发了什么、赚到了什么、亏掉了什么、下一轮局势如何改变。
```

---

## 6. 参考 Python 项目的数据架构取向

Python 参考项目的 `CardManager` 使用统一的 `piles` 字典管理不同位置：`deck`、`draw_pile`、`discard_pile`、`hand`、`exhaust_pile`。

v1.1 不照搬战斗牌堆，但采用同样边界思想：

```text
候选不是凭空刷新生成。
候选在几个位置之间移动。
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

规格层面必须明确：

```text
候选具有库存与位置，不是每次 refresh 复制一份新候选。
```

---

## 7. 已确认操作语义

### 7.1 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
```

规则：

```text
大多数普通卡 grasp 时不立刻触发强数值效果。
grasp 的基础成本是 focus 与 working_memory 占格。
grasp 后该候选从 emergence_pool 移到 working_memory。
grasp 后该候选不再留在 stock 中，不会被当前压力积攒环节的 refresh 再刷出来。
少数特殊卡可以在 grasp 时产生正负即时影响，例如 emotion 进入意识后污染。
```

### 7.2 refresh

```text
refresh = 刷酒馆 / 从有限候选库存中搜索下一批浮现候选。
```

规则：

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

玩家体验：

```text
我花了一点注意力继续想。
眼前浮现新的可能性。
但时间过去了，压力更高了。
```

### 7.3 discard

```text
discard = 卖掉 / 放弃一个念头，腾格子并回池。
```

规则：

```text
discard 不消耗 focus。
discard 从 working_memory 或 emergence_pool 移除卡。
如果 discard 的来源是 working_memory，则该候选回到当前压力积攒环节的 stock。
如果 discard 的来源是 emergence_pool，则该候选仍留在当前 stock，或视为没有被买走。
discard 释放 working_memory 格。
discard 不产生 focus 返还，因为 v1.1 仍不新增第二资源。
```

### 7.4 keep

```text
keep = 冻结关键件。
```

规则：

```text
keep 不消耗 focus。
keep 来源为 working_memory 中的卡。
keep 后该卡进入 kept_cards 或标记 kept。
下一压力积攒环节开始时，该卡仍留在 working_memory。
该卡继续占用 working_memory。
keep 不触发额外收益。
keep 不使该候选回 stock。
```

玩家体验：

```text
我不花 focus 留住一个关键念头。
但它会继续占据工作记忆，减少下一轮可操作空间。
```

### 7.5 express

```text
express = 把暂存组件转化为当前局势收益。
```

规则：

```text
express 消耗 focus。
express 应用该候选的主要效果。
express 后从 working_memory 移除，释放工作记忆格。
express 后候选进入 used。
express 后不在当前压力积攒环节立刻回 stock。
该候选只可能在后续压力积攒环节重新进入 stock，模拟“局势变化后类似念头重新浮现”。
```

玩家体验：

```text
我已经把这个念头说出口 / 做出来了。
它不应该马上又像没发生过一样重新浮现。
但经过一次自动执行、局势变化后，类似判断可以在新的压力阶段重新进入意识。
```

### 7.6 quiet

```text
quiet = 处理 emotion 污染。
```

规则方向：

```text
quiet 不是免费删除坏牌。
quiet 应该把未处理情绪转化为可用信息或降低后续损失。
quiet 后的收益/损失应在自动执行过程中体现，而不只是即时数值变化。
```

---

## 8. 重复类似候选的后续价值

v1.1 默认每张具体候选 1 份，不主动追求“同一候选多份刷出”的体验。

但后续拓展框架时，重复类似候选非常有价值：

```text
同一个情绪反复浮现。
同一种恐惧不断占据工作记忆。
同一个判断以不同措辞重复出现。
同一种冲动不断挤掉其他念头。
```

玩家体验：

```text
我不是随机又看见一张重复牌。
而是我的大脑真的被同一种情绪 / 想法 / 执念占据了。
```

v1.1 保留结构能力：

```text
支持 copy_count 字段或等价结构能力。
默认每张具体候选 1 份。
不围绕重复候选做平衡。
```

后续扩展可引入：

```text
candidate_family
压力 / 污染 / 角色状态影响某个 family 的出现密度
反刍、执念、强迫性回想或情绪占据
```

---

## 9. 自动执行环节：不是回放，而是带胜率的团战过程

### 9.1 自动执行触发

触发条件可以是：

```text
focus_points 耗尽。
pressure 到达阈值。
压力节点达到强制执行点。
系统进入类似红色检定的不可回避行动。
```

### 9.2 自动执行输入

进入自动执行时锁定：

```text
working_memory
used
kept_cards
triggered_cores
action_tendency_tracks
situation_tracks
pressure
ally_trust
emotion 污染状态
```

### 9.3 自动执行顺序

v1.1 自动执行建议顺序：

```text
1. LOCK_IN：进入不可干预状态。
2. CHOOSE_DOMINANT_ACTION：行动倾向竞争决出 dominant_action。
3. SHOW_OUTCOME_RATE：展示 dominant_action 的主目标成功率。
4. EXECUTE_SEQUENCE：展示自动执行过程中的事件流。
5. FINAL_CONSEQUENCE：展示主目标是否达成，以及局势进入什么状态。
6. VALUE_SUMMARY：总结这场自动执行实际赚了什么、亏了什么。
7. CAUSE_SUMMARY：简短解释哪些积累结构影响了成功率和事件流。
```

### 9.4 outcome_rate 的含义

```text
outcome_rate 只表示 dominant_action 达成主目标的概率。
```

它不表示：

```text
角色会选择哪个行动。
自动执行会触发哪些收益。
自动执行会付出哪些代价。
最终整体赚亏。
```

玩家体验：

```text
我已经知道角色会强硬干预。
我知道强硬干预有 62% 概率压住局面。
但我还不知道过程里会触发什么、亏掉什么、留下什么。
```

### 9.5 auto_execution_events 的含义

`auto_execution_events` 是自动执行的核心观看内容。

它对应酒馆战棋团战中的：

```text
复仇触发
亡语触发
圣盾挡关键攻击
核心随从活下来
赢了打多少血
输了有没有触发成长
对面虽然输了但赚到收益
输团还被入很多血
关键件死亡
下一轮经济与战力格局变化
```

Pressure Encounter 中对应：

```text
Kim 是否抓住窗口行动
同伴是否跟上
情绪污染是否打断表达
保留的关键念头是否在执行中派上用场
证据是否降低误判代价
关系是否吸收一次失败
压力是否导致额外伤害
强硬行动是否压住局面但损害信任
失败是否暴露真正矛盾，打开下一轮机会
```

这些事件不能被简化成固定四象限。四象限最多作为事后摘要语言，不是系统骨架。

### 9.6 final_consequence 与 value_summary

自动执行结束后，玩家应看到两层结果：

```text
final_consequence：主目标结果。
value_summary：过程中的实际收益和损失。
```

例子：

```text
主目标：强硬干预成功，第一波失控被压住。
收益：Kim 获得行动窗口；你保住了一个关键证据；下一轮 ally_trust +1。
损失：压力没有释放干净；对方进入更危险状态；你承受一次伤害。
```

这比“希望成功 / 恐惧成功”更包容，也更像酒馆战棋。

---

## 10. 用《极乐迪斯科》枪战理解自动执行

玩家在枪战前的操作相当于压力积攒：

```text
对白选择
白色检定
装备准备
关系积累
信息理解
恐惧处理
临场念头筛选
```

进入枪战时，dominant_action 已经确定，例如：

```text
dominant_action：强硬干预
主目标：阻止枪战立刻全面失控
outcome_rate：62%
```

但自动执行不是直接开奖：

```text
成功：阻止失控
失败：没阻止失控
```

真正像酒馆团战的是过程中的事件流：

```text
你抢先开口，压住对方半秒。
Kim 抓住窗口行动。
你之前没有处理好的恐惧让你迟疑了一拍。
同伴信任不足，没有完全跟上。
对方仍然造成伤害。
你保住了一个关键判断，但牺牲了谈判余地。
局势没有彻底崩，但下一轮压力更高。
```

玩家带着 62% 成果率观看这个过程，快感来自：

```text
我知道主行动大概能不能成。
但我不知道这场“压力团战”里会触发哪些收益和损失。
我会看着每个积累过的念头、关系、污染、核心触发在过程里发挥作用或造成代价。
```

---

## 11. v1 实现观察

当前 v1 的实现形态：

```text
1. grasp 对 observation / emotion 有明显收益。
2. express 处理 evidence / technique / relationship 的主要效果。
3. quiet 主要处理 emotion，并在 hands_shaking 上提供 steady_response +1。
4. refresh 有 pressure +1 代价，并重建当前节点基础候选池。
5. keep 当前仍消耗 focus；v1.1 已确认应改为 0 focus。
6. v1 没有有限库存语义；v1.1 已确认应增加当前压力积攒环节 candidate_stock。
7. v1 的自动结算更像最终结果日志；v1.1 需要改成带成果率的自动执行过程展示。
```

v1.1 审查重点：

```text
基础回合的买入、占格、有限库存、刷新、保留、表达、自动执行事件流之间的取舍是否足够清楚？
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
7. 增加轻量 outcome_rate，且 outcome_rate 只对应 dominant_action 的主目标成功率。
8. 增加 auto_execution_events，用来展示自动执行过程中的收益/损失事件。
9. 增加 final_consequence / value_summary。
10. 增加针对机制质量的 GUT 测试。
11. 更新 status 文档。
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
14. 僵硬四象限结果表。
```

---

## 13. 问答式审查问题池

### 13.1 已确认：酒馆战棋优先

```text
Q：是否以酒馆战棋作为第一玩法参照？
```

结论：是。

```text
外部 TRPG 规则只能提供结构启发，不能覆盖自走棋自动团战体验。
```

### 13.2 已确认：压力积攒 / 自动执行

```text
Q：Pressure Encounter 的主循环是否应是“压力积攒环节 ↔ 自动执行环节”？
```

结论：是。

```text
压力积攒环节像酒馆操作。
自动执行环节像自动团战，也像无法避免的红色检定式集中释放。
```

### 13.3 已确认：成果率对象

```text
Q：成果率显示的是多种行动倾向的分布，还是最终胜出行动的成功率？
```

结论：最终胜出行动的主目标成功率。

```text
压力积攒结束时，多种行动倾向已经竞争完毕。
自动执行开始时，玩家已经知道角色会采取什么 dominant_action。
outcome_rate 显示这个 dominant_action 能不能达成主目标。
```

### 13.4 已确认：不能僵硬四象限

```text
Q：是否把 Daggerheart 的四种结果僵硬画成系统四象限？
```

结论：否。

```text
系统应该更包容。
胜率与最终结果之间有大量潜在收益和损失，需要通过实际自动执行事件流展示。
四象限最多作为分析语言，不是实现骨架。
```

### 13.5 已确认：自动执行核心观看内容

```text
Q：自动执行阶段的核心观看内容是什么？
```

结论：不是回放，也不是四象限落点，而是带着成果率观看事件流。

```text
玩家知道主行动和主行动成功率。
然后观看实际过程里触发了哪些收益、损失、保留、成长、伤害与下一轮压力。
```

---

## 14. 下一步问答入口

下一个需要确认的问题：

```text
从玩家体验看，v1.1 的 auto_execution_events 至少应该包含哪几类事件？

候选方向：
1. 主目标推进事件：行动是否接近成功。
2. 关系协同事件：同伴是否跟上、信任是否吸收代价。
3. 情绪干扰事件：恐惧、迟疑、僵住是否打断执行。
4. 关键件收益事件：保留 / 表达的念头是否在执行中触发价值。
5. 代价事件：伤害、压力残留、关系损伤、下一轮风险。
6. 下一轮铺垫事件：失败但获得信息，或成功但留下新压力。
```

建议倾向：v1.1 先保留 4 类：主目标推进、关系协同、情绪干扰、代价/铺垫。
