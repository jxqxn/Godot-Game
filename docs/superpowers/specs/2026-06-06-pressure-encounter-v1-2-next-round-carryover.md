# Pressure Encounter v1.2 下一压力节点回流规格草案

## 文档元信息

```text
文档类型：机制规格 / 问答式迭代草案
创建日期：2026-06-06
修订日期：2026-06-06
前置版本：Pressure Encounter v1.1 已合入 main
前置 PR：#3 feat: add pressure encounter v1.1 loop quality
目标版本：v1.2
最高优先级玩法参照：炉石传说酒馆战棋
参考架构：slay-the-model-main/player/card_manager.py；slay-the-model-main/cards/base.py；slay-the-model-main/utils/registry.py
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

### 3.2 v1.2 第一批回流通道

已确认：v1.2 第一批只做 2 类回流通道。

```text
1. 局势轨回流：pressure / ally_trust。
2. 候选池回流：向下一轮 stock 新增具体关键候选。
```

暂不做：

```text
行动倾向回流。
强制工作记忆回流。
candidate_family 权重池。
跨遭遇长期记忆。
复杂回流连锁。
```

玩家体验解释：

```text
上一轮压力团战结束后，
玩家首先应该感受到两件事：
1. 局势变了：压力更高或关系更稳。
2. 想法变了：下一轮脑子里多了一个具体的新判断。
```

### 3.3 候选池回流方式

已确认：v1.2 的候选池回流先做“新增具体关键候选”，不做“提高某类候选出现倾向”。

正确方向：

```text
上一轮失败但看清真正先开火的人
→ 下一轮 stock 新增【真正先开火的人】。
```

暂不实现：

```text
family_bias: { "emotion": 1 }
复杂权重池
同类候选出现概率调整
```

设计原因：

```text
新增具体关键候选最直观，玩家容易理解，也最适合 Codex 实现。
candidate_family / family_bias 更接近权重池系统，长期有价值，但 v1.2 只预留字段，不进入第一批实现。
```

### 3.4 stock_add 数据架构

已确认：参考 Python 项目，v1.2 采用“候选定义与位置流动分离”的数据架构。

```text
stock_add 不携带完整 candidate 数据。
stock_add 使用 stock_add_ids。
完整候选定义放在 encounter 级统一 candidate_definitions。
应用回流时，根据 candidate_id 查表、复制/实例化，再加入下一 pressure_node 的 stock。
```

玩家体验解释：

```text
事件告诉玩家：为什么这个新念头出现。
候选定义表告诉系统：这个新念头具体是什么。
库存系统告诉程序：它现在进入下一轮 stock。
```

设计原因：

```text
Python 项目里：
- Card 子类负责定义卡牌内容；
- registry 负责按 id / class name 找到定义并实例化；
- CardManager 统一管理 piles，只处理运行时位置流动。

Pressure Encounter v1.2 应对应为：
- candidate_definitions 负责定义候选内容；
- stock_add_ids / stock_ids 负责引用候选 id；
- candidate_piles / stock 负责运行时位置流动。
```

### 3.5 候选定义表位置

已确认：v1.2 不新增单独的 `carryover_candidate_definitions`，而是使用 encounter 级统一 `candidate_definitions`。

```text
不要：每个 pressure_node 内联完整 candidate 数据。
不要：专门为回流候选做 carryover_candidate_definitions。
要：encounter.candidate_definitions 统一定义所有候选。
```

设计原因：

```text
Python 项目中，Anger 这类具体卡牌是注册到统一 card registry 的 Card 子类，不是嵌在某个房间节点里的临时字典。
回流、初始牌堆、奖励、生成物都应该引用同一个候选定义来源。
```

### 3.6 pressure_node 数据迁移

已确认：v1.2 应在本版本内把 `pressure_nodes.cards` 迁移为 `pressure_nodes.stock_ids`，但必须保留旧 `cards` 兼容层。

```text
新结构：pressure_node.stock_ids。
旧结构：pressure_node.cards。
读取优先级：优先读取 stock_ids；如果不存在，则兼容读取旧 cards。
```

设计原因：

```text
如果回流候选用 stock_add_ids 查表，而初始节点仍内联完整 cards，系统会出现两种候选定义来源。
这会削弱 Python 参考项目中“定义集中、运行时位置流动”的架构优势。

但 v1.2 仍需要兼容 v1.1 调试数据，避免一次性破坏旧节点。
```

### 3.7 缺失 candidate_id 处理

已确认：v1.2 对缺失 `candidate_id` 采用“运行时安全降级 + 开发期严格暴露”的策略。

```text
运行时 / 调试场景：
- 缺失 candidate_id 不应导致整个遭遇崩溃。
- 跳过该候选。
- 写入 resolution_log。
- 记录到 missing_candidate_ids。

开发期 / 测试：
- 所有 stock_ids 必须能在 candidate_definitions 中找到。
- 所有 stock_add_ids 必须能在 candidate_definitions 中找到。
- missing_candidate_ids 必须为空。
- 如果不为空，GUT 应失败。
```

参考 Python 项目：

```text
registry.get_registered(...) 找不到时返回 None。
registry.get_registered_instance(...) 找不到时也返回 None。
底层查找不直接炸掉；调用方决定如何处理缺失。
```

玩家体验理由：

```text
玩家不应该因为一个数据 id 写错，整个压力遭遇卡死。
但开发者必须立刻知道是哪一个 id 没有定义。
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
candidate_family 出现倾向实现
完整 Tavern Tier / 稀有度系统
完整自动战斗连锁系统
类复仇 / 类亡语 / 成长流派完整实现
多轮跨遭遇剧情记忆
行动倾向回流
强制工作记忆回流
事件内联完整 candidate 数据
节点内联完整 candidate 数据作为新结构
单独 carryover_candidate_definitions
缺失 candidate_id 时硬崩溃
```

v1.2 只验证：

```text
上一轮 auto_execution_events / value_summary / next_round_delta
是否能通过 situation_delta 和 stock_add_ids
安全、可理解地影响下一 pressure_node 的初始化。
```

---

## 5. v1.2 第一批回流通道

### 5.1 局势轨回流

第一批只允许影响已有局势轨：

```text
pressure
ally_trust
```

玩家体验：

```text
上一轮赢得很粗暴，所以下一轮现场更紧。
上一轮 Kim 跟上了我，所以下一轮我更敢相信他。
```

规则方向：

```text
auto_execution_events 可以产生 situation_delta。
situation_delta 在下一 pressure_node 初始化时应用。
只作用于当前 Pressure Encounter 内的下一节点。
```

示例：

```gdscript
{
  "situation_delta": {
    "pressure": 1
  },
  "source_event_ids": ["cost_or_setup_pressure"]
}
```

### 5.2 候选池回流

第一批只做新增具体关键候选：

```text
stock_add_ids
```

玩家体验：

```text
上一轮失败让我看清真正问题，
所以下一轮脑子里会浮现一个新的关键判断。
```

规则方向：

```text
auto_execution_events 可以产生 stock_add_ids。
stock_add_ids 在下一 pressure_node 初始化时解析为候选定义。
完整候选数据从 encounter.candidate_definitions 查找。
查表成功后，复制/实例化候选并加入下一节点 stock。
新增候选只进入下一节点 stock，不直接进入 working_memory。
```

carryover 示例：

```gdscript
{
  "stock_add_ids": ["true_shooter_seen"],
  "source_event_ids": ["failed_but_saw_true_shooter"]
}
```

### 5.3 预留但不实现：候选家族倾向

v1.2 可以在 carryover 数据中预留 `family_bias` 字段，但第一批不应用。

```gdscript
{
  "family_bias": {}
}
```

说明：

```text
family_bias 未来用于反刍、情绪占据、同类念头反复浮现。
v1.2 不实现权重算法，也不影响 refresh。
```

---

## 6. 数据结构建议

### 6.1 encounter 级候选定义表

v1.2 必须把当前 pressure_node 内联的 `cards` 数据上提为 encounter 级统一 `candidate_definitions`。

```gdscript
{
  "candidate_definitions": {
    "observed_instability": {
      "id": "observed_instability",
      "name": "对方快失控了",
      "detail": "观察",
      "chain_tag": "observation"
    },
    "ally_waiting": {
      "id": "ally_waiting",
      "name": "同伴在等你的判断",
      "detail": "关系",
      "chain_tag": "relationship"
    },
    "true_shooter_seen": {
      "id": "true_shooter_seen",
      "name": "真正先开火的人",
      "detail": "你没能阻止枪声，但你看清了第一个扣下扳机的人。",
      "chain_tag": "evidence"
    }
  }
}
```

### 6.2 pressure_node 改为引用 id

v1.2 必须将 pressure_node 从内联 `cards` 迁移为 `stock_ids`，同时保留旧 `cards` 兼容读取。

```gdscript
{
  "title": "看清局面",
  "stock_ids": [
    "observed_instability",
    "ally_waiting",
    "hands_shaking",
    "basic_procedure"
  ]
}
```

应用时：

```text
读取 pressure_node.stock_ids
→ 从 encounter.candidate_definitions 查完整定义
→ 复制/实例化为 candidate_stock
```

兼容逻辑：

```text
1. 如果 pressure_node 有 stock_ids，使用 stock_ids。
2. 如果 pressure_node 没有 stock_ids 但有旧 cards，则从 cards 读取 id，并把旧 cards 临时作为定义来源。
3. 新增/更新测试覆盖 stock_ids 新路径与 cards 旧路径。
```

### 6.3 carryover_delta

v1.2 第一批实际使用字段：

```gdscript
{
  "target_node_offset": 1,
  "situation_delta": {
    "pressure": 1,
    "ally_trust": 1
  },
  "stock_add_ids": ["true_shooter_seen"],
  "source_event_ids": ["cost_or_setup_pressure"]
}
```

应用流程：

```text
1. 读取 next_round_delta / carryover_delta。
2. 应用 situation_delta 到下一 pressure_node 初始化状态。
3. 读取当前 pressure_node.stock_ids。
4. 读取 carryover_delta.stock_add_ids。
5. 合并 stock_ids 与 stock_add_ids。
6. 从 encounter.candidate_definitions 查找完整候选定义。
7. 复制/实例化候选。
8. 将候选加入下一节点 stock。
9. 记录 source_event_ids，供调试、解释与测试使用。
```

### 6.4 缺失候选解析结果

建议解析函数返回结构化结果，而不是只返回候选字典。

```gdscript
{
  "ok": true,
  "candidate": {
    "id": "true_shooter_seen",
    "name": "真正先开火的人",
    "detail": "你没能阻止枪声，但你看清了第一个扣下扳机的人。",
    "chain_tag": "evidence"
  }
}
```

缺失时：

```gdscript
{
  "ok": false,
  "candidate": {},
  "missing_id": "true_shooter_seen"
}
```

缺失时必须：

```text
写入 resolution_log：MISSING_CANDIDATE_DEFINITION:<id>
写入 missing_candidate_ids。
跳过该候选。
不中断整个 encounter。
```

v1.2 预留但不应用字段：

```gdscript
{
  "stock_remove_ids": [],
  "family_bias": {},
  "working_memory_add_ids": [],
  "tendency_delta": {}
}
```

规格要求：

```text
回流需要可追溯来源。
回流需要能解释给玩家。
回流不能直接污染全局系统。
回流只影响下一 pressure_node。
新增候选只进入下一轮 stock，不直接进入 working_memory。
事件/回流只引用 candidate_id，不内联完整 candidate 数据。
节点新结构只引用 candidate_id，不内联完整 candidate 数据。
旧 cards 只作为兼容输入，不作为新数据结构。
候选定义表负责定义候选内容。
stock / candidate_piles 负责位置流动。
缺失 candidate_id 运行时不崩溃，但必须记录。
GUT 必须覆盖 missing_candidate_ids 为空的正常路径。
GUT 必须覆盖缺失 id 时会记录 MISSING_CANDIDATE_DEFINITION。
```

---

## 7. 极乐迪斯科枪战类比

v1.2 的目标不是让枪战变成长期数值养成，而是让压力释放后的下一轮思考发生变化。

例子：

```text
上一轮：你强硬干预，成功压住第一波。
过程代价：现场气氛更紧。
下一轮回流：pressure +1。
```

玩家体验：

```text
我赢了，但这不是干净的胜利。
下一轮现场更紧，我要在更差的压力下继续思考。
```

另一个例子：

```text
上一轮：你没能阻止枪声。
过程收益：你看清真正先开火的人。
下一轮回流：stock_add_ids = ["true_shooter_seen"]。
下一轮 stock 新增【真正先开火的人】。
```

玩家体验：

```text
我失败了，但不是白失败。
下一轮我的脑子里多了一个新的关键判断。
```

---

## 8. 下一步问答入口

下一个需要确认的问题：

```text
v1.2 的 carryover_delta 应该什么时候应用？
```

候选方案：

```text
方案 A：自动执行结束时立刻修改下一 pressure_node 数据。
方案 B：自动执行结束时只记录 pending_carryover；进入下一 pressure_node 初始化时再应用。
```

建议倾向：方案 B。

理由：

```text
自动执行阶段只负责产出结果。
下一节点初始化阶段负责读取 pending_carryover 并生成下一轮 stock / situation_tracks。
这更符合 Python 项目中 action 产出意图、管理器处理位置流动的分层，也避免提前污染尚未进入的节点。
```
