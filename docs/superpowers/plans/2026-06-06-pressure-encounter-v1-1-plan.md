# Pressure Encounter v1.1 实施计划

## 文档元信息

```text
文档类型：实施计划 / Codex 参考
创建日期：2026-06-06
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

## 3. 推荐实施顺序

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

## 4. Step 1：候选位置语义与有限库存

### 4.1 目标

让候选卡不再像“每次 refresh 复制生成”，而是在几个位置之间移动。

建议概念：

```gdscript
candidate_piles = {
  "stock": [],            # 当前压力积攒环节的有限候选库存池
  "emergence_pool": [],   # 当前刷出的浮现候选
  "working_memory": [],   # 已抓住 / 买入的候选
  "used": [],             # 已表达 / 已转化为局势收益的候选
  "discarded": []         # 已放弃，可回 stock 的候选
}
```

不要求一定用这个 exact 字段名；但必须实现同等位置语义。

### 4.2 规则

```text
每个压力积攒环节初始化 stock。
refresh 从 stock 中抽出 emergence_pool。
grasp 将候选从 emergence_pool 移到 working_memory。
discard 可将 working_memory 中的候选放回 stock。
express 将候选从 working_memory 移到 used。
used 不在当前压力积攒环节回 stock。
```

### 4.3 copy_count

v1.1 数据结构支持 copy_count 或等价能力，但默认每张具体候选 1 份。

```text
当前不围绕重复候选做平衡。
后续可用 copy_count / candidate_family 表现反刍、执念、情绪占据。
```

### 4.4 验收标准

```text
grasp 后同一候选不会在当前 pressure accumulation 的后续 refresh 中再次出现。
discard working_memory 中的候选后，该候选可以再次进入 stock。
express 后候选进入 used，不会在当前 pressure accumulation 的 refresh 中再次出现。
同一 seed 下 refresh 结果稳定。
```

---

## 5. Step 2：基础操作规则修正

### 5.1 refresh

```text
refresh 消耗 focus。
refresh 增加 pressure。
refresh 从当前 stock 受控随机抽一批候选，写入 emergence_pool。
refresh 不从 working_memory / used 抽卡。
```

测试要求：

```text
必须支持固定 seed 或可注入 RNG。
GUT 不依赖不可控随机。
```

### 5.2 grasp

```text
grasp = 买入 / 抓住一个念头 / 暂存进工作记忆。
大多数普通卡 grasp 时不触发强数值效果。
少数特殊卡可保留即时影响，例如 emotion 污染。
```

### 5.3 discard

```text
discard 不消耗 focus。
discard 释放 working_memory 格。
discard 来源为 working_memory 时，该候选回 stock。
discard 不返还 focus。
```

### 5.4 keep

```text
keep 不消耗 focus。
keep 继续占用 working_memory。
keep 不触发额外收益。
keep 不使候选回 stock。
```

### 5.5 express

```text
express 消耗 focus。
express 应用候选主要效果。
express 后从 working_memory 移除。
express 后进入 used。
express 不在当前压力积攒环节回 stock。
```

### 5.6 quiet

```text
quiet 用于处理 emotion 污染。
quiet 不是免费删除坏牌。
quiet 可以降低后续自动执行中的情绪干扰，或把情绪转化成可用信息。
```

v1.1 可先保留现有 quiet 效果，但需要在自动执行事件中体现其价值。

---

## 6. Step 3：压力积攒结束锁定输入

### 6.1 目标

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

### 6.2 验收标准

```text
进入 auto_execution 后，refresh / grasp / discard / keep / express 不再可用。
auto_execution 使用锁定快照，不被后续字段变化干扰。
```

---

## 7. Step 4：dominant_action 与 outcome_rate

### 7.1 dominant_action

压力积攒结束时，根据 action_tendency_tracks 决出 dominant_action。

v1.1 继续使用现有倾向轨：

```text
steady_response
forceful_response
freeze_response
```

### 7.2 outcome_rate

outcome_rate 只表示 dominant_action 达成主目标的概率。

它不表示：

```text
角色会选择哪个行动。
自动执行会触发哪些收益。
自动执行会付出哪些代价。
最终整体赚亏。
```

### 7.3 轻量计算建议

v1.1 不做复杂胜率模拟器。

可以先用规则表或简单公式估算：

```text
base_rate_by_action
+ dominant_action 轨道强度修正
+ triggered_cores 修正
+ ally_trust 修正
- pressure 修正
- unresolved emotion / panic_spiral 修正
```

示例：

```text
强硬干预成功率 62%
```

### 7.4 验收标准

```text
自动执行开始前可读到 dominant_action。
自动执行开始前可读到 outcome_rate。
outcome_rate 对应 dominant_action 主目标成功率，而不是多行动分布。
```

---

## 8. Step 5：auto_execution_events 最小事件流

### 8.1 目标

v1.1 只做 4 类基础事件，但事件数据结构必须可扩展。

四类基础事件：

```text
1. 主目标推进事件
2. 关系协同事件
3. 情绪干扰事件
4. 代价 / 下一轮铺垫事件
```

### 8.2 事件结构

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

预留字段：

```text
event_tags
trigger_reason
next_round_delta
priority
chain_key
```

### 8.3 事件类型 1：主目标推进

用途：让玩家看到 dominant_action 是否接近成功。

触发来源示例：

```text
dominant_action
outcome_rate
triggered_cores
pressure
```

示例文本：

```text
你提高声音，打断了佣兵的节奏。
对方的手指离扳机远了一点。
局势短暂稳定。
```

失败方向：

```text
你的话没有压住对方。
对方反而被刺激得更紧绷。
枪口重新抬起。
```

### 8.4 事件类型 2：关系协同

用途：让玩家看到前面积累的关系 / 信任是否在自动执行中触发。

触发来源示例：

```text
ally_trust
relationship card
used relationship candidates
kept relationship candidates
```

示例文本：

```text
Kim 看懂了你的眼神，提前移动到侧面。
你之前建立的信任让他没有质疑你的判断。
```

反向文本：

```text
Kim 慢了一拍。
他没有完全理解你的意图。
你的强硬行动变成了一个人孤立地向前压。
```

### 8.5 事件类型 3：情绪干扰

用途：让玩家看到未处理情绪或已处理情绪在关键时刻的影响。

触发来源示例：

```text
unquieted emotion
quieted emotion
panic_spiral
freeze_response
```

负向文本：

```text
你的手又开始发抖。
你原本要继续压上去，但声音断了一下。
这半秒迟疑让对方重新夺回节奏。
```

正向文本：

```text
恐惧再次浮上来。
但你已经认出它只是身体在报警。
你没有被它拖住，反而因此注意到对方的枪口偏移。
```

### 8.6 事件类型 4：代价 / 下一轮铺垫

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

成功但有代价：

```text
你成功压住第一波失控。
但你的方式太强硬，现场气氛变得更紧。
下一轮 pressure +1。
```

失败但有铺垫：

```text
你没能阻止枪声。
但你看清了真正先开火的人。
下一轮获得一个新的关键候选。
```

### 8.7 扩展要求

v1.1 只实现 4 类基础事件，但不得把事件写死成这 4 类。

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

## 9. Step 6：final_consequence / value_summary

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
```

---

## 10. Step 7：测试计划

### 10.1 候选库存测试

```text
refresh 从 stock 抽 emergence_pool。
grasp 后候选不再出现在 stock / 后续 refresh。
discard 后候选回 stock。
express 后候选进入 used，不回当前 stock。
同一 seed 下 refresh 结果稳定。
```

### 10.2 keep 测试

```text
keep 不消耗 focus。
keep 后候选继续占 working_memory。
下一压力积攒环节仍可见 kept card。
```

### 10.3 dominant_action / outcome_rate 测试

```text
压力积攒结束后可得到 dominant_action。
outcome_rate 绑定 dominant_action。
outcome_rate 不是多行动分布。
pressure / ally_trust / core_trigger 能影响 outcome_rate。
```

### 10.4 auto_execution_events 测试

```text
满足 ally_trust 条件时生成 relationship_synergy 事件。
存在 unquieted emotion 时生成 emotion_interference 事件。
存在 quieted emotion 时可以生成正向 emotion 事件或降低负向事件。
高 pressure 时生成 cost_or_setup 事件。
triggered observation_window 可以生成 objective_progress 事件。
事件包含 event_id / event_type / display_text / severity / value_delta / source_ids。
```

### 10.5 final_consequence / value_summary 测试

```text
自动执行结束后生成 final_consequence。
自动执行结束后生成 value_summary。
value_summary 汇总 auto_execution_events 中的 value_delta / next_round_delta。
```

---

## 11. 风险与控制

### 11.1 风险：v1.1 变成完整自动战斗模拟器

控制：

```text
只做 4 类基础事件。
不做复杂连锁。
不做站位、血量、完整伤害系统。
```

### 11.2 风险：事件只是漂亮文本

控制：

```text
每轮自动执行至少有若干事件进入 value_summary / final_consequence / next_round_delta。
过程表现事件可以存在，但不能全部都是表现文本。
```

### 11.3 风险：架构写死，后续难扩展

控制：

```text
使用 event_type / event_tags / source_ids / value_delta / next_round_delta。
不要把 4 类事件写成不可扩展固定分支。
```

### 11.4 风险：随机导致测试不稳定

控制：

```text
refresh 必须支持 seed 或 RNG 注入。
GUT 中使用固定 seed。
```

---

## 12. 完成定义

v1.1 完成时，应满足：

```text
1. 候选在 stock / emergence_pool / working_memory / used / discarded 之间移动。
2. refresh 是受控随机，不是简单重建列表。
3. keep 不消耗 focus。
4. express 后进入 used，不在当前压力积攒环节回 stock。
5. 压力积攒结束后生成 dominant_action。
6. 自动执行前展示 dominant_action 的 outcome_rate。
7. 自动执行生成至少 4 类基础事件中的若干条。
8. 自动执行结束生成 final_consequence 与 value_summary。
9. auto_execution_events 采用可扩展事件结构。
10. 新增/更新 GUT 覆盖关键路径。
11. 更新 status 文档。
```
