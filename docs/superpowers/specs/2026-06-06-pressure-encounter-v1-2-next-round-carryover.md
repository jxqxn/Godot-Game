# Pressure Encounter v1.2 下一压力节点回流规格草案

## 文档元信息

```text
文档类型：机制规格 / 问答式迭代草案
创建日期：2026-06-06
前置版本：Pressure Encounter v1.1 已合入 main
前置 PR：#3 feat: add pressure encounter v1.1 loop quality
目标版本：v1.2
最高优先级玩法参照：炉石传说酒馆战棋
```

---

## 1. v1.1 已完成基础

v1.1 已经完成最小压力团战循环：

```text
压力积攒环节
→ 自动执行环节
→ dominant_action
→ outcome_rate
→ auto_execution_events
→ final_consequence
→ value_summary
→ next_round_delta 记录
```

v1.1 验证的是：

```text
玩家带着主行动成功率观看自动执行事件流，
并看到前面操作过的念头、关系、情绪、压力在过程中产生收益和损失。
```

---

## 2. v1.2 核心问题

v1.2 要回答的问题是：

```text
自动执行中产生的收益、损失、压力残留、关系变化和新信息，
应该如何回流到下一轮压力积攒？
```

玩家体验上，这对应酒馆战棋：

```text
自动团战不是看完就结束。
团战结果会改变下一回合：
- 掉了多少血；
- 有没有成长；
- 核心有没有保住；
- 对面有没有赚到；
- 下一回合的经济、战力、流派方向是否改变。
```

Pressure Encounter 中对应：

```text
这次强硬干预成功了，但下一轮 pressure 是否更高？
Kim 跟上了我，下一轮 ally_trust 是否提高？
我失败但看清真正先开火的人，下一轮 stock 是否加入关键候选？
我没处理好恐惧，下一轮 emotion 候选是否更容易浮现？
```

---

## 3. 已确认边界

### 3.1 v1.2 回流范围

已确认：v1.2 的结果回流先只影响下一压力节点。

```text
影响范围：当前 Pressure Encounter 内的下一 pressure_node。
不影响：跨遭遇、跨地图、跨整局长期记忆。
```

玩家体验解释：

```text
我刚才那场压力团战的结果，
会改变下一轮我脑子里浮现什么、压力有多大、同伴是否更信任我、我是否更容易僵住。
但它暂时不会变成整个游戏的永久性全局记忆。
```

设计原因：

```text
先把“上一轮自动执行 → 下一轮压力积攒”的短循环做稳。
不要立刻扩大到全局系统，避免影响地图、事件、战斗和长期存档结构。
```

---

## 4. v1.2 非目标

v1.2 暂不做：

```text
跨遭遇长期记忆
跨地图状态回流
全局心理状态系统
完整角色创伤系统
默认地图接入
正式 UI 面板
复杂权重池
完整 Tavern Tier / 稀有度系统
完整自动战斗连锁系统
类复仇 / 类亡语 / 成长流派完整实现
多轮跨遭遇剧情记忆
```

v1.2 只验证：

```text
上一轮 auto_execution_events / value_summary / next_round_delta
是否能安全、可理解地影响下一 pressure_node 的初始化。
```

---

## 5. 建议的最小回流通道

v1.2 可以先讨论并选择以下 4 类回流通道。

### 5.1 局势轨回流

```text
pressure
ally_trust
其他已有 situation_tracks
```

玩家体验：

```text
上一轮赢得很粗暴，所以下一轮现场更紧。
上一轮 Kim 跟上了我，所以下一轮我更敢相信他。
```

### 5.2 候选池回流

```text
向下一轮 stock 加入关键候选。
从下一轮 stock 移除某些候选。
提高某类 candidate_family 的出现倾向。
```

玩家体验：

```text
上一轮失败让我看清真正问题，
所以下一轮脑子里会浮现一个新的关键判断。
```

### 5.3 工作记忆回流

```text
kept_cards 继续占用 working_memory。
某些代价可能强制留下负面念头。
某些收益可能保留关键判断。
```

玩家体验：

```text
我不是重新开一局。
上一轮我执意保留的念头，还在占着我的脑子。
上一轮留下的恐惧，也可能继续挤占空间。
```

### 5.4 行动倾向回流

```text
下一轮 steady_response / forceful_response / freeze_response 初始值受到上一轮影响。
```

玩家体验：

```text
上一轮我靠强硬压住了局面，
下一轮我可能更自然地继续强硬。
上一轮我被恐惧拖住，
下一轮我更容易先僵住。
```

---

## 6. 架构原则

v1.2 不应该把回流写成零散硬编码文本。

建议把 v1.1 的 `next_round_delta` 发展成可解释的 carryover 数据：

```gdscript
{
  "target_node_offset": 1,
  "situation_delta": {
    "pressure": 1,
    "ally_trust": 1
  },
  "stock_add": ["true_shooter_seen"],
  "stock_remove": [],
  "family_bias": {
    "emotion": 1
  },
  "working_memory_add": [],
  "tendency_delta": {
    "freeze_response": 1
  },
  "source_event_ids": ["cost_or_setup_pressure"]
}
```

v1.2 不一定一次实现所有字段，但规格上应明确：

```text
回流需要可追溯来源。
回流需要能解释给玩家。
回流不能直接污染全局系统。
```

---

## 7. 下一步问答入口

下一个需要确认的问题：

```text
从玩家体验看，v1.2 的第一批回流通道应该先做哪几个？
```

建议倾向：先做 2 个。

```text
1. 局势轨回流：pressure / ally_trust。
2. 候选池回流：下一轮新增关键候选或提高某类候选出现倾向。
```

理由：

```text
局势轨回流最容易让玩家感到上一轮赚亏有后果。
候选池回流最接近酒馆战棋“团战后影响下一回合选择空间”的体验。
工作记忆回流已有 kept_cards 基础，可以稍后扩展。
行动倾向回流容易造成滚雪球，需要谨慎。
```
