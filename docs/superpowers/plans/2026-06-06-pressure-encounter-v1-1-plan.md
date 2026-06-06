# Pressure Encounter v1.1 实施计划

## 文档元信息

```text
文档类型：实施计划 / Codex 参考
创建日期：2026-06-06
修订日期：2026-06-06
前置规格：docs/superpowers/specs/2026-06-06-pressure-encounter-v1-1-quality-review.md
前置状态：Pressure Encounter v1 已合入 main，完整 GUT 已通过
目标版本：v1.1
最高优先级玩法参照：炉石传说酒馆战棋
```

---

## 1. v1.1 实施目标

v1.1 的目标不是扩展完整新系统，而是把 v1 从“能跑通的事件卡牌化原型”推进到更接近酒馆战棋基础回合的体验：

```text
压力积攒环节 = 酒馆操作环节
自动执行环节 = 自动团战环节
```

玩家体验目标：

```text
玩家在压力积攒环节中 refresh / grasp / discard / keep / express。
操作结束后，行动倾向竞争决出 dominant_action。
系统显示 dominant_action 的主目标成果率 outcome_rate。
随后进入不可干预的自动执行过程。
玩家看到前面积攒的念头、关系、情绪、关键件如何在过程中触发收益和损失。
```

---

## 2. 非目标

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

## 3. 自检后消除的关键歧义

本节是对原计划的自检修正，Codex 实现时必须遵守。

### 3.1 emergence_pool 未买走候选的处理

按酒馆战棋体验，真正让库存减少的是“买走 / grasp”，不是“看见”。

```text
refresh 展示 emergence_pool。
玩家没有 grasp 的候选，在下一次 refresh / 离开当前显示页时，应重新保持或回到 stock 可抽范围。
grasp 的候选才从 stock 中移出，进入 working_memory。
```

因此 v1.1 语义是：

```text
emergence_pool = 当前展示页，不是永久移除区。
stock = 当前压力积攒环节的可抽库存。
```

### 3.2 discard 的范围

v1.1 中 discard 只处理已经 grasp 的候选，也就是 working_memory 中的候选。

```text
discard = 卖掉 / 放弃已抓住的念头。
discard 来源：working_memory。
discard 效果：释放 working_memory 格，并让该候选回到 stock。
```

不对 emergence_pool 做 discard。未抓取的 emergence_pool 候选通过 refresh 自然回到可抽范围。

### 3.3 自动执行触发时机

v1.1 不新增独立 phase scheduler。

```text
沿用 v1 已有自动结算入口 / resolve_auto_resolution 触发点。
把该阶段解释为 auto_execution。
后续版本再扩展为多轮“压力积攒 ↔ 自动执行”循环。
```

### 3.4 outcome_rate 数值边界

v1.1 的 outcome_rate 必须是整数百分比：

```text
范围：0 到 100
显示：例如 62%
内部计算后必须 clamp 到 0..100
```

### 3.5 事件不是纯文本

`auto_execution_events` 可以有过程表现事件，但每次自动执行至少要有：

```text
1 条 objective_progress 或等价主目标事件，用于 final_consequence。
至少 1 条能进入 value_summary 或 next_round_delta 的结果价值事件。
```

如果没有明显收益或损失，也应输出一个中性 summary 项，例如：

```text
本轮没有获得额外优势，也没有留下新的明显代价。
```

### 3.6 next_round_delta 的应用边界

v1.1 可以先生成 `next_round_delta`，不必须完整应用到未来系统。

```text
若当前 v1 流程已有下一 pressure_node，可在安全范围内应用。
若没有稳定下一阶段入口，则先记录在 final_result / value_summary 中，供后续迭代使用。
```

---

## 4. 推荐实施顺序

v1.1 应按以下顺序实施，避免一次性改动过大。

```text
Step 1：候选位置语义与有限库存
Step 2：基础操作规则修正
Step 3：压力积攒结束锁定输入
Step 4：dominant_action 与 outcome_rate
Step 5：auto_execution_events 最小事件流
Step 6：final_consequence / value_summary
Step 7：GUT 测试与文档状态更新
```

---

## 5. Step 1：候选位置语义与有限库存

### 5.1 目标

让候选卡不再像“每次 refresh 复制生成”，而是在几个位置之间移动。

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

不要求一定用这个 exact 字段名；但必须实现同等位置语义。

### 5.2 规则

```text
每个压力积攒环节初始化 stock。
refresh 从 stock 的可抽范围中生成 emergence_pool。
未被 grasp 的 emergence_pool 候选，在下一次 refresh 时仍可回到 stock 可抽范围。
grasp 将候选从 emergence_pool 移到 working_memory，并从 stock 可抽范围移除。
discard 将 working_memory 中的候选放回 stock。
express 将 working_memory 中的候选移到 used。
used 不在当前压力积攒环节回 stock。
```

### 5.3 copy_count

v1.1 数据结构支持 copy_count 或等价能力，但默认每张具体候选 1 份。

```text
当前不围绕重复候选做平衡。
后续可用 copy_count / candidate_family 表现反刍、执念、情绪占据。
```

### 5.4 验收标准

```text
grasp 后同一候选不会在当前 pressure accumulation 的后续 refresh 中再次出现。
未 grasp 的 emergence_pool 候选不会永久消失，后续 refresh 可再次出现。
discard working_memory 中的候选后，该候选可以再次进入 stock 可抽范围。
express 后候选进入 used，不会在当前 pressure accumulation 的 refresh 中再次出现。
同一 seed 下 refresh 结果稳定。
```

---

## 6. Step 2：基础操作规则修正

### 6.1 refresh

```text
refresh 消耗 focus。
refresh 增加 pressure。
refresh 从当前 stock 可抽范围受控随机抽一批候选，写入 emergence_pool。
refresh 不从 working_memory / used 抽卡。
refresh 会替换当前 emergence_pool；未 grasp 的旧 emergence_pool 不算损失。
```

测试要求：

```text
必须支持固定 seed 或可注入 RNG。
GUT 不依赖不可控随机。
```

### 6.2 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
大多数普通卡 grasp 时不触发强数值效果。
少数特殊卡可保留即时影响，例如 emotion 污染。
```

### 6.3 discard

```text
discard 不消耗 focus。
discard 只作用于 working_memory。
discard 释放 working_memory 格。
discard 将候选回到 stock 可抽范围。
discard 不返还 focus。
```

### 6.4 keep

```text
keep 不消耗 focus。
keep 继续占用 working_memory。
keep 不触发额外收益。
keep 不使候选回 stock。
```

### 6.5 express

```text
express 消耗 focus。
express 应用候选主要效果。
express 后从 working_memory 移除。
express 后进入 used。
express 不在当前压力积攒环节回 stock。
```

### 6.6 quiet

```text
quiet 用于处理 emotion 污染。
quiet 不是免费删除坏牌。
quiet 可以降低后续自动执行中的情绪干扰，或把情绪转化成可用信息。
```

v1.1 可先保留现有 quiet 效果，但需要在自动执行事件中体现其价值。

---

## 7. Step 3：压力积攒结束锁定输入

### 7.1 目标

进入自动执行时，玩家不再能继续操作。

锁定以下输入：

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

### 7.2 触发边界

```text
v1.1 沿用当前 v1 自动结算入口。
不要新增大型 phase scheduler。
可把现有 resolve_auto_resolution 语义重命名 / 包装为 auto_execution，但不要重构整套房间流。
```

### 7.3 验收标准

```text
进入 auto_execution 后，refresh / grasp / discard / keep / express 不再可用。
auto_execution 使用锁定快照，不被后续字段变化干扰。
```

---

## 8. Step 4：dominant_action 与 outcome_rate

### 8.1 dominant_action

压力积攒结束时，根据 action_tendency_tracks 决出 dominant_action。

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

### 8.2 outcome_rate

outcome_rate 只表示 dominant_action 达成主目标的概率。

它不表示：

```text
角色会选择哪个行动。
自动执行会触发哪些收益。
自动执行会付出哪些代价。
最终整体赚亏。
```

### 8.3 轻量计算建议

v1.1 不做复杂胜率模拟器。

建议先用简单确定公式：

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

上述数值不是最终平衡，只是 v1.1 可测试默认值。Codex 可以实现为常量，便于后续调参。

示例：

```text
强硬干预成功率 62%
```

### 8.4 验收标准

```text
自动执行开始前可读到 dominant_action。
自动执行开始前可读到 outcome_rate。
outcome_rate 是 0..100 的整数。
outcome_rate 对应 dominant_action 主目标成功率，而不是多行动分布。
```

---

## 9. Step 5：auto_execution_events 最小事件流

### 9.1 目标

v1.1 只做 4 类基础事件，但事件数据结构必须可扩展。

四类基础事件：

```text
1. 主目标推进事件
2. 关系协同事件
3. 情绪干扰事件
4. 代价 / 下一轮铺垫事件
```

### 9.2 事件结构

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

### 9.3 事件类型 1：主目标推进

用途：让玩家看到 dominant_action 是否接近成功。

触发来源示例：

```text
dominant_action
outcome_rate
triggered_cores
pressure
```

要求：每次自动执行至少生成 1 条主目标推进事件。

### 9.4 事件类型 2：关系协同

用途：让玩家看到前面积累的关系 / 信任是否在自动执行中触发。

触发来源示例：

```text
ally_trust
relationship card
used relationship candidates
kept relationship candidates
```

### 9.5 事件类型 3：情绪干扰

用途：让玩家看到未处理情绪或已处理情绪在关键时刻的影响。

触发来源示例：

```text
unquieted emotion
quieted emotion
panic_spiral
freeze_response
```

### 9.6 事件类型 4：代价 / 下一轮铺垫

用途：展示赢了也可能亏、输了也可能赚。

触发来源示例：

```text
pressure
forceful overcommit
failed main goal
successful but costly action
used evidence
kept observation
```

要求：每次自动执行至少生成 1 条影响 value_summary 或 next_round_delta 的事件。如果没有明显收益或损失，生成 neutral summary。

### 9.7 扩展要求

v1.1 只实现 4 类基础事件，但不得把事件系统写死成这 4 类。

后续应能自然扩展：

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

## 10. Step 6：final_consequence / value_summary

自动执行结束后，输出两层结果：

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

注意：

```text
final_consequence 不替代事件流。
value_summary 是事件流的归纳，不是事后硬编解释。
value_summary 汇总 value_delta / next_round_delta。
```

---

## 11. Step 7：测试计划

### 11.1 候选库存测试

```text
refresh 从 stock 可抽范围生成 emergence_pool。
未 grasp 的 emergence_pool 候选在下一次 refresh 后仍可再次出现。
grasp 后候选不再出现在 stock / 后续 refresh。
discard 后候选回 stock。
express 后候选进入 used，不回当前 stock。
同一 seed 下 refresh 结果稳定。
```

### 11.2 keep 测试

```text
keep 不消耗 focus。
keep 后候选继续占 working_memory。
下一压力积攒环节仍可见 kept card。
```

### 11.3 dominant_action / outcome_rate 测试

```text
压力积攒结束后可得到 dominant_action。
outcome_rate 绑定 dominant_action。
outcome_rate 是 0..100 的整数。
outcome_rate 不是多行动分布。
pressure / ally_trust / core_trigger 能影响 outcome_rate。
平局 dominant_action 结果稳定。
```

### 11.4 auto_execution_events 测试

```text
每次 auto_execution 至少生成 objective_progress 事件。
满足 ally_trust 条件时生成 relationship_synergy 事件。
存在 unquieted emotion 时生成 emotion_interference 事件。
存在 quieted emotion 时可以生成正向 emotion 事件或降低负向事件。
高 pressure 时生成 cost_or_setup 事件。
triggered observation_window 可以生成 objective_progress 事件。
事件包含 event_id / event_type / display_text / severity / value_delta / source_ids。
至少 1 条事件影响 value_summary 或 next_round_delta；否则生成 neutral summary。
```

### 11.5 final_consequence / value_summary 测试

```text
自动执行结束后生成 final_consequence。
自动执行结束后生成 value_summary。
value_summary 汇总 auto_execution_events 中的 value_delta / next_round_delta。
```

---

## 12. 风险与控制

### 12.1 风险：v1.1 变成完整自动战斗模拟器

控制：

```text
只做 4 类基础事件。
不做复杂连锁。
不做站位、血量、完整伤害系统。
```

### 12.2 风险：事件只是漂亮文本

控制：

```text
每次自动执行至少有 1 条事件进入 value_summary / final_consequence / next_round_delta。
过程表现事件可以存在，但不能全部都是表现文本。
```

### 12.3 风险：架构写死，后续难扩展

控制：

```text
使用 event_type / event_tags / source_ids / value_delta / next_round_delta。
event_type 用字符串或可扩展标识，不要写成不可扩展固定 enum。
不要把 4 类事件写成不可扩展固定分支。
```

### 12.4 风险：随机导致测试不稳定

控制：

```text
refresh 必须支持 seed 或 RNG 注入。
GUT 中使用固定 seed。
```

---

## 13. 完成定义

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
