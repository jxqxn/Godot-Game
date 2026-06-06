# Pressure Encounter v1.1 机制质量审查规格

## 文档元信息

```text
文档类型：机制质量审查规格 / v1.1 收敛版
创建日期：2026-06-06
修订日期：2026-06-06
目标阶段：可转实施计划
对应实施计划：docs/superpowers/plans/2026-06-06-pressure-encounter-v1-1-plan.md
前置实现：Pressure Encounter v1 已合入 main
最高优先级玩法参照：炉石传说酒馆战棋
```

---

## 1. 当前确认结论

```text
1. Pressure Encounter v1 已实现并合入 main。
2. v1.1 继续优先验证机制质量，不急着接默认地图。
3. v1.1 的核心参照是炉石传说酒馆战棋 10 费回合基础体验。
4. 压力积攒环节对应酒馆操作环节。
5. 自动执行环节对应自动团战环节。
6. 大多数普通候选卡 grasp = 暂存 + 占格，不是买入即触发。
7. 少数特殊候选卡可以有即时正负影响，例如 emotion 污染。
8. keep = 冻结关键件，不消耗 focus；成本是继续占用 working_memory。
9. refresh 使用受控随机与有限候选库存池，而不是简单重建列表。
10. 未 grasp 的 emergence_pool 候选不会永久消失；它们在下一次 refresh 时仍可回到 stock 可抽范围。
11. grasp 才会让候选离开 stock 可抽范围。
12. discard 只作用于 working_memory 中已抓住的候选，并让候选回 stock。
13. express 后候选进入 used，不在当前压力积攒环节立刻回 stock。
14. v1.1 支持数据结构上的 copy_count，但默认每张具体候选 1 份。
15. 重复类似候选主要作为后续塑造反刍、执念和情绪占据的扩展口。
16. 自动执行环节不是事后回放，而是带成果率预期的过程展示。
17. 操作结束时，行动倾向竞争已经决出 dominant_action。
18. outcome_rate 显示 dominant_action 的主目标成功率，不是多行动结果分布。
19. outcome_rate 为 0..100 的整数，计算后必须 clamp。
20. 不把结果僵硬画成 Hope/Fear 四象限；Daggerheart 只提供“成功率之外还有过程收益/损失”的启发。
21. 自动执行的重点是：胜率与实际结果之间，还有许多潜在收益和损失需要通过实际过程展示。
22. v1.1 暂时只做 4 类基础自动执行事件：主目标推进、关系协同、情绪干扰、代价/下一轮铺垫。
23. 架构上必须为后续更多事件类型留足空间，不得把事件系统写死成这 4 类。
24. v1.1 不新增大型 phase scheduler；沿用 v1 既有自动结算入口，将其解释为 auto_execution。
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

玩家应该感到：

```text
我刚才还能操作、搜索、暂存、保留、放弃、表达。
现在准备阶段结束了。
角色必须行动。
我带着一个成果率，看这套积累如何不可避免地展开。
```

对应酒馆战棋：

```text
酒馆操作环节
→ 自动团战环节
```

对应《极乐迪斯科》枪战：

```text
一系列白色检定 / 对话选择 / 信息浮现
→ 压力逐渐积累
→ 玩家最终无法避免进入红色检定式强制行动节点
→ 先前积攒下来的压力、误判、关系、装备、技能与行动倾向集中进入自动执行
```

---

## 3. 一句话目标

```text
在不扩大系统边界的前提下，把 Pressure Encounter v1 从“能跑通的事件卡牌化原型”，推进到更接近酒馆战棋基础回合的候选池搜索、买入暂存、有限库存、占格取舍、冻结关键件、胜率预期与自动执行过程展示。
```

v1.1 不是完整自动战斗模拟器，只验证：

```text
玩家带着 dominant_action 的成果率进入自动执行后，
能否看到前面压力积攒出的念头、关系、情绪、关键件，
在过程中产生真实收益和真实损失。
```

---

## 4. 非目标

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
新增 phase scheduler
第三个及以上 core_trigger
更多局势轨
完整后期经济引擎
特殊流派机制
完整战斗预测器
复杂胜率模拟器
多行动结果分布预测器
硬编码 Hope/Fear 四象限结果表
复杂事件连锁系统
完整站位 / 伤害 / 血量系统
```

---

## 5. 核心机制类比

```text
emergence_pool = 当前刷出的浮现候选页面
candidate_stock = 当前压力积攒环节的有限候选库存池
working_memory = 手牌 / 场面占格
focus_points = 金币 / 可用注意力
refresh = 刷酒馆 / 再想一下
grasp = 买入 / 抓住一个念头
discard = 卖掉 / 放弃已抓住的念头，腾格子并回池
keep = 冻结关键件
express = 把暂存件转化为当前局势收益，并进入 used
core_trigger = 核心成型
dominant_action = 行动倾向竞争后的胜出行动
outcome_rate = dominant_action 的主目标成功率
auto_execution_events = 自动执行过程中发生的收益/损失/触发/伤害/成长/保留事件
final_consequence = 主目标结果 + 实际过程价值
```

---

## 6. 候选库存与位置语义

建议概念：

```gdscript
candidate_piles = {
  "stock": [],            # 当前压力积攒环节的有限候选库存池
  "emergence_pool": [],   # 当前刷出的浮现候选页
  "working_memory": [],   # 已抓住 / 买入的候选
  "used": [],             # 已表达 / 已转化为局势收益的候选
  "discarded": []         # 已放弃，可回 stock 的候选记录
}
```

规则：

```text
每个压力积攒环节初始化 stock。
refresh 从 stock 的可抽范围中生成 emergence_pool。
未被 grasp 的 emergence_pool 候选，在下一次 refresh 时仍可回到 stock 可抽范围。
grasp 将候选从 emergence_pool 移到 working_memory，并从 stock 可抽范围移除。
discard 只作用于 working_memory，将候选放回 stock。
express 将 working_memory 中的候选移到 used。
used 不在当前压力积攒环节回 stock。
```

设计原因：

```text
在酒馆战棋里，看见随从不等于池子减少；买走才减少。
未购买的候选不能因为 refresh 永久消失。
```

---

## 7. 操作语义

### 7.1 refresh

```text
refresh 消耗 focus。
refresh 增加 pressure。
refresh 从当前 stock 可抽范围受控随机抽一批候选，写入 emergence_pool。
refresh 不从 working_memory / used 抽卡。
refresh 替换当前 emergence_pool；未 grasp 的旧 emergence_pool 不算损失。
同一 seed 下 refresh 结果稳定。
```

### 7.2 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
大多数普通卡 grasp 时不触发强数值效果。
少数特殊卡可保留即时影响，例如 emotion 污染。
```

### 7.3 discard

```text
discard 不消耗 focus。
discard 只作用于 working_memory。
discard 释放 working_memory 格。
discard 将候选回到 stock 可抽范围。
discard 不返还 focus。
```

### 7.4 keep

```text
keep 不消耗 focus。
keep 继续占用 working_memory。
keep 不触发额外收益。
keep 不使候选回 stock。
```

### 7.5 express

```text
express 消耗 focus。
express 应用候选主要效果。
express 后从 working_memory 移除。
express 后进入 used。
express 不在当前压力积攒环节回 stock。
```

### 7.6 quiet

```text
quiet 用于处理 emotion 污染。
quiet 不是免费删除坏牌。
quiet 可以降低后续自动执行中的情绪干扰，或把情绪转化成可用信息。
```

---

## 8. 自动执行阶段

v1.1 不新增大型 phase scheduler。

```text
沿用 v1 已有自动结算入口 / resolve_auto_resolution 触发点。
将该阶段解释为 auto_execution。
后续版本再扩展为多轮“压力积攒 ↔ 自动执行”循环。
```

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

建议顺序：

```text
1. LOCK_IN：进入不可干预状态。
2. CHOOSE_DOMINANT_ACTION：行动倾向竞争决出 dominant_action。
3. SHOW_OUTCOME_RATE：展示 dominant_action 的主目标成功率。
4. BUILD_EXECUTION_EVENTS：根据锁定状态生成自动执行事件流。
5. EXECUTE_SEQUENCE：展示自动执行过程中的事件流。
6. FINAL_CONSEQUENCE：展示主目标是否达成，以及局势进入什么状态。
7. VALUE_SUMMARY：总结这场自动执行实际赚了什么、亏了什么。
8. CAUSE_SUMMARY：简短解释哪些积累结构影响了成功率和事件流。
```

---

## 9. dominant_action 与 outcome_rate

v1.1 继续使用现有倾向轨：

```text
steady_response
forceful_response
freeze_response
```

平局处理必须稳定：

```text
优先级建议：steady_response > forceful_response > freeze_response
或沿用现有 v1 规则；但必须在测试中固定。
```

outcome_rate 只表示 dominant_action 达成主目标的概率。

建议默认公式：

```text
base_rate_by_action = 50
+ dominant_action 轨道强度 * 5
+ triggered_cores 每个 +8
+ ally_trust * 5
- pressure * 5
- unresolved_emotion_count * 8
- panic_spiral_count * 5
最后 clamp 到 0..100
```

说明：

```text
这些数值不是最终平衡，只是 v1.1 可测试默认值。
应作为常量实现，便于后续调参。
```

---

## 10. v1.1 自动执行事件范围

v1.1 只做 4 类基础事件。

```text
1. 主目标推进事件
2. 关系协同事件
3. 情绪干扰事件
4. 代价 / 下一轮铺垫事件
```

### 10.1 主目标推进事件

用途：让玩家看到 dominant_action 是否接近成功。

要求：每次自动执行至少生成 1 条主目标推进事件。

### 10.2 关系协同事件

用途：让玩家看到前面积累的关系 / 信任是否在自动执行中触发。

触发来源示例：

```text
ally_trust
relationship card
used relationship candidates
kept relationship candidates
```

### 10.3 情绪干扰事件

用途：让玩家看到未处理情绪或已处理情绪在关键时刻的影响。

触发来源示例：

```text
unquieted emotion
quieted emotion
panic_spiral
freeze_response
```

### 10.4 代价 / 下一轮铺垫事件

用途：展示赢了也可能亏、输了也可能赚。

要求：每次自动执行至少生成 1 条影响 value_summary 或 next_round_delta 的事件。如果没有明显收益或损失，生成 neutral summary。

---

## 11. 自动执行事件架构要求

建议事件结构：

```gdscript
{
  "event_id": "kim_follows_window",
  "event_type": "relationship_synergy",
  "event_tags": ["relationship", "ally", "window"],
  "source_ids": ["ally_waiting", "ally_can_hear_you"],
  "trigger_reason": "ally_trust >= 1",
  "display_text": "Kim 看懂了你的眼神，提前移动到侧面。",
  "value_delta": {
    "ally_trust": 1
  },
  "next_round_delta": {},
  "severity": "positive"
}
```

v1.1 最小字段：

```text
event_id
event_type
display_text
severity
value_delta
source_ids
```

字段约束：

```text
event_type：字符串，可扩展，不限于 4 个硬编码 enum。
severity：建议 positive / negative / neutral。
value_delta：可以为空字典；为空代表该事件仅用于过程表现。
source_ids：可以为空数组，但应优先记录候选卡、core、状态来源。
```

预留字段：

```text
event_tags
trigger_reason
next_round_delta
priority
chain_key
```

后续可扩展事件类型示例：

```text
revenge_like_trigger      类复仇：受到压力/伤害后触发收益
deathrattle_like_trigger  类亡语：某个念头/资源失去时触发收益或代价
growth_trigger            成长：失败或承压后提高后续能力
shield_trigger            保护：关系/证据/准备吸收一次代价
position_trigger          站位：空间位置或注意力位置改变结果
resource_loss             关键件损失
opponent_growth           对方虽然受挫但获得成长
rumination_trigger        反刍：同类念头在下一轮更容易出现
```

---

## 12. final_consequence / value_summary

自动执行结束后，输出两层结果：

```text
final_consequence：主目标结果。
value_summary：过程中的实际收益和损失。
```

要求：

```text
final_consequence 不替代事件流。
value_summary 是事件流的归纳，不是事后硬编解释。
value_summary 汇总 value_delta / next_round_delta。
每次自动执行至少有 objective_progress 事件。
每次自动执行至少有事件影响 value_summary / next_round_delta，或生成 neutral summary。
```

---

## 13. 《极乐迪斯科》枪战类比

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

---

## 14. 完成定义

v1.1 完成时，应满足：

```text
1. 候选在 stock / emergence_pool / working_memory / used / discarded 之间移动。
2. 未 grasp 的 emergence_pool 候选不会永久消失。
3. refresh 是受控随机，不是简单重建列表。
4. keep 不消耗 focus。
5. discard 只作用于 working_memory，并让候选回 stock。
6. express 后进入 used，不在当前压力积攒环节回 stock。
7. 压力积攒结束后生成 dominant_action。
8. 自动执行前展示 dominant_action 的 outcome_rate。
9. outcome_rate 是 0..100 的整数，并对应 dominant_action 主目标成功率。
10. 自动执行生成至少 4 类基础事件中的若干条。
11. 每次自动执行至少有 objective_progress 事件。
12. 每次自动执行至少有事件影响 value_summary / next_round_delta，或生成 neutral summary。
13. 自动执行结束生成 final_consequence 与 value_summary。
14. auto_execution_events 采用可扩展事件结构。
15. 新增/更新 GUT 覆盖关键路径。
16. 更新 status 文档。
```
