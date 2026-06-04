# 《极乐迪斯科》枪战卡牌化最小改动方案：Codex 参考规格

## 文档元信息

```text
文档类型：机制设计参考 / 外部案例拆解
整理日期：2026-06-04
仓库位置：docs/references/disco-gunfight-cardification/minimal-cardification-spec.md
配套文档：mda-loop-summary.md、machine-readable-spec.json
原始附件：originals/minimal-cardification-spec.docx
```

使用边界：

```text
1. 本文不是当前 Godot 项目的正式规格，不可直接按全文实现。
2. 本文中的具体题材、人物、地点、事件只作为机制案例材料。
3. 后续若要转入当前游戏，应先抽象机制，再另写 docs/superpowers/specs/ 下的新规格。
4. 当前项目 AGENTS.md 中的架构边界与开发红线优先级高于本文。
```

---

> 目的：把原本偏设计阐述的“枪战卡牌化最小改动方案”改写成适合实现智能体 / Codex 读取的规格文档。
> 核心原则：不重做枪战，不做普通战斗系统；只把原本的对话选项、技能发声、调查信息、装备触发和关系变量，转化为“浮现牌—工作记忆—意愿轨—自动结算”的轻量机制。

---

## 0. 实现目标

实现一个单场遭遇原型：临近结尾处的枪战对峙。

该原型要验证：

- 玩家不是直接选择“开枪 / 投掷 / 逃跑 / 什么也不做”。
- 玩家在一系列压力节点中处理浮现的念头、证据、技能声音、情绪和关系回声。
- 这些牌修改行动意愿值与局势变量。
- 当局势到达临界点时，由最高意愿自动生成哈里的行动。
- 枪战按固定顺序自动结算，部分结果由前期变量与当前牌面修正。
- Harry 中弹倒下应近似保留为必然或高确定性结果。

一句话：**玩家不是点击“开枪”按钮，而是通过临场处理意识材料，让“哈里会开枪”这件事变得更可能。**

---

## 1. 非目标 / 禁止事项

Codex 实现时请避免以下方向：

1. 不要把敌人做成 HP 血条单位。
2. 不要实现传统回合制战斗。
3. 不要让玩家逐回合控制开枪、移动、普攻。
4. 不要把证据做成现场随机购买的商品；证据必须来自前期调查状态。
5. 不要把技能声音做成商店商品；技能声音应根据技能等级和场景压力自动浮现。
6. 不要把“开枪”做成玩家直接点击的按钮；它应是意愿竞争的结果。
7. 不要让刷新变成无代价抽牌；刷新代表多想了一秒，局势应更危险。
8. 不要让枪战变成可完全胜利的英雄战斗；玩家只能改变局部伤亡。

---

## 2. 核心概念

| 概念 | 说明 | 对应自走棋结构 |
|---|---|---|
| 浮现区 `emergence_pool` | 当前节点浮现的意识牌，来自调查、技能、关系、情绪和场景压力 | 酒馆区域 |
| 工作记忆 `working_memory` | 玩家抓住的牌，容量有限 | 手牌区域 |
| 意愿轨 `intention_tracks` | 哈里当前可能行动的意愿值 | 战场结算结构 |
| 局势轨 `situation_tracks` | 枪战场面的风险、暴露、失控等变量 | 战场状态 |
| 心力 `willpower` | 每个节点的临场认知预算 | 金币 |
| 节点 `pressure_node` | 原版对话流程中的压力推进点 | 招募阶段 / 决策窗口 |
| 自动结算 `auto_resolution` | 局势临界后按固定顺序清算枪战 | 自动战斗 |

---

## 3. 数据模型建议

### 3.1 EncounterState

```ts
interface EncounterState {
  nodeIndex: number;
  phase: 'pressure_node' | 'intention_resolution' | 'gunfight_auto_resolution' | 'kim_warning' | 'complete';

  willpower: number;
  maxWillpowerPerNode: number;

  emergencePool: Card[];
  workingMemory: Card[];
  workingMemoryLimit: number;

  intentionTracks: IntentionTracks;
  situationTracks: SituationTracks;

  priorFlags: PriorFlags;
  equipment: EquipmentState;
  skills: SkillState;
  relationship: RelationshipState;

  log: ResolutionLogEntry[];
}
```

### 3.2 IntentionTracks

```ts
interface IntentionTracks {
  continuePersuasion: number;   // 继续说服
  shootIntervention: number;    // 开枪干预
  throwMolotov: number;         // 投掷烈酒炸弹
  freeze: number;               // 僵住
  retreatSelfPreservation: number; // 后退自保
  warnKim: number;              // 警告 Kim，主要在最后节点使用
}
```

### 3.3 SituationTracks

```ts
interface SituationTracks {
  mercenaryInstability: number;     // 雇佣兵失控程度
  revengeNarrative: number;         // 雇佣兵复仇叙事强度
  titusExposure: number;            // Titus 暴露度
  elizabethInvolvement: number;     // Elizabeth 介入度
  kimTrust: number;                 // Kim 信任 / 是否会相信你的警告
  kimAlertness: number;             // Kim 警觉
  harryBodyStability: number;       // Harry 身体稳定
  pressure: number;                 // 全局压力 / 局势临界值
  pressureLimit: number;
}
```

### 3.4 Card

```ts
interface Card {
  id: string;
  title: string;
  type: 'evidence' | 'skill_voice' | 'emotion' | 'equipment' | 'relationship' | 'observation';
  source: 'prior_investigation' | 'skill' | 'relationship' | 'equipment' | 'scene_pressure';

  // 是否能进入浮现区；例如证据牌必须检查 priorFlags。
  availability: AvailabilityRule[];

  // 玩家操作允许项。
  actions: CardActionType[]; // ['grasp', 'speak', 'suppress', 'keep', 'discard']

  // 被抓住、说出、压下、保留时分别应用的效果。
  effects: Partial<Record<CardActionType, Effect[]>>;

  // 风味文本只用于 UI，不参与结算。
  flavor?: string;
}
```

### 3.5 Effect

```ts
interface Effect {
  target: 'intention' | 'situation' | 'willpower' | 'memory' | 'log';
  key: string;
  op: 'add' | 'set' | 'multiply' | 'flag';
  value: number | string | boolean;
  note?: string;
}
```

---

## 4. 玩家操作

每个压力节点只提供少量操作，避免变成复杂卡牌游戏。

| 操作 | 输入 | 成本 | 效果 |
|---|---|---:|---|
| `grasp(card)` 抓住 | 浮现区一张牌 | 1 心力 | 移入工作记忆 |
| `speak(card)` 说出口 / 顺着它行动 | 工作记忆一张可说出的牌 | 1 心力 | 应用该牌的局势 / 意愿效果 |
| `suppress(card)` 压下 | 工作记忆或浮现区的一张情绪 / 干扰牌 | 1-2 心力 | 暂时移除或降低负面影响，但可加入后续反弹 |
| `keep(card)` 保留 | 工作记忆一张牌 | 1 心力 | 下个节点仍保留，类似冻结 |
| `discard(card)` 放弃 | 工作记忆一张牌 | 0 | 清空记忆格 |
| `refresh()` 重新浮现 | 当前浮现区 | 1 心力 + 局势恶化 | 重新生成浮现区，`pressure + 1` 或暴露度上升 |

---

## 5. 流程总览

```text
start encounter
↓
initialize EncounterState from priorFlags / equipment / skills / relationship
↓
for each pressure node:
  generate emergencePool
  grant willpower
  player performs limited card operations
  apply card effects to intentionTracks and situationTracks
  increase pressure
  if pressure >= pressureLimit:
      break
↓
resolve highest intention
↓
auto-resolve gunfight sequence
↓
resolve final Kim warning
↓
write result log
```

---

## 6. 压力节点设计

### Node 1: 进入对峙，看清局面

目标：让玩家处理观察牌、关系牌和初始干扰牌。

可能浮现：

- `observed_drunk_mercs`：他们喝醉了
- `titus_about_to_talk`：Titus 快要顶嘴
- `kim_waiting_for_judgement`：Kim 在等你的判断
- `hands_are_shaking`：手在发抖

典型效果：

```text
他们喝醉了：shootIntervention +1, mercenaryInstability +1
Kim 在等你的判断：warnKim +1, kimTrust +1
手在发抖：freeze +2, shootIntervention -1，占用工作记忆
```

### Node 2: 瓦解复仇叙事

目标：让前期调查牌进入场景，但说出真相要带来风险。

可能浮现：

- `evidence_hardie_not_killer`：死者不是哈迪兄弟杀的
- `wild_pines_is_watching`：Wild Pines 在看着
- `elizabeth_wants_to_speak`：Elizabeth 想要开口
- `failed_cop_shame`：我是个失败警探

典型效果：

```text
死者不是哈迪兄弟杀的：revengeNarrative -2, continuePersuasion +1, elizabethInvolvement +1
Wild Pines 在看着：Shanky 逃跑机会 +1, pressure +1
我是个失败警探：freeze +1, Authority 类效果 -1
```

### Node 3: 局势失控，寻找可行动条件

目标：把技能声、身体反应和行动前置条件推到前台。

可能浮现：

- `armor_has_weak_point`：护甲有弱点
- `reaction_speed_now`：Reaction Speed：现在！
- `retreat_is_possible`：现在逃走还来得及
- `titus_will_die`：Titus 会死

典型效果：

```text
护甲有弱点：shootIntervention +1；若进入射击结算，命中修正 +1
Reaction Speed：现在！：shootIntervention +1；自动结算中闪避修正 +1
现在逃走还来得及：retreatSelfPreservation +2, shootIntervention -1
Titus 会死：shootIntervention +2, continuePersuasion -1
```

### Node 4: 临界点

当 `pressure >= pressureLimit`，停止玩家输入，进入意愿结算。

---

## 7. 意愿结算规则

基本规则：选择数值最高的意愿作为哈里行动。

```ts
function resolveDominantIntention(tracks: IntentionTracks): keyof IntentionTracks {
  return argMax(tracks);
}
```

建议平局优先级：

```text
freeze > retreatSelfPreservation > shootIntervention > throwMolotov > continuePersuasion > warnKim
```

理由：在高压崩坏场景里，恐惧和僵住的惯性应更强；玩家需要主动构筑，才能让干预行为压过它们。

特殊约束：

- 若没有枪，`shootIntervention` 不能执行，可降级为 `freeze` 或 `continuePersuasion`。
- 若没有烈酒炸弹，`throwMolotov` 不能执行。
- 若 `harryBodyStability <= 0`，`freeze` 权重上升。
- 若工作记忆中仍有强干扰牌，`freeze` 获得额外修正。

---

## 8. 自动枪战结算顺序

自动结算必须尽量接近原作的灾难顺序。不要把它做成自由战斗。

```text
1. Shanky 是否逃走
2. Elizabeth 是否被卷入
3. Titus 是否成为主要目标
4. Harry 执行最高意愿
   - shootIntervention
   - throwMolotov
   - freeze
   - retreatSelfPreservation
   - continuePersuasion
5. Kortenaer 是否被击倒 / 失稳
6. Ruud 开枪
7. Reaction Speed / T-500 胸甲结算
8. Kim 反击
9. De Paule 开火并造成误伤
10. Harry 中弹倒下
11. 进入最后警告 Kim 窗口
```

保留原则：

- Harry 倒下应保留为近似必然或强制节点。
- 玩家影响的是伤亡结构、Kim 是否受伤、Titus / Elizabeth / Shanky 等局部命运。
- 结果应写入日志，让玩家看懂“为什么发生”。

---

## 9. 最后警告 Kim

Harry 倒下后进入极短的最后节点。

浮现区可出现：

- `kim_waiting_for_judgement`
- `authority_make_them_hear_you`
- `blood_in_throat`

结算建议：

```ts
kimWarningScore = base
  + situationTracks.kimTrust
  + situationTracks.kimAlertness
  + skillModifier.Authority
  + cardModifier('kim_waiting_for_judgement')
  - cardModifier('blood_in_throat')
  - bodyPenalty(harryBodyStability)

kimSaved = kimWarningScore >= threshold
```

设计意图：Kim 是否听见哈里的警告，不是最后一秒的单独选择，而是前期关系、临场保留牌、Authority 和身体状态共同结算。

---

## 10. 示例卡牌数据

```json
[
  {
    "id": "observed_drunk_mercs",
    "title": "他们喝醉了",
    "type": "observation",
    "source": "scene_pressure",
    "availability": [],
    "actions": ["grasp", "speak", "discard"],
    "effects": {
      "grasp": [
        {"target":"intention", "key":"shootIntervention", "op":"add", "value":1}
      ],
      "speak": [
        {"target":"situation", "key":"mercenaryInstability", "op":"add", "value":1},
        {"target":"situation", "key":"pressure", "op":"add", "value":1}
      ]
    },
    "flavor": "你闻到了酒精，也看见了他们快要散架的纪律。"
  },
  {
    "id": "evidence_hardie_not_killer",
    "title": "死者不是哈迪兄弟杀的",
    "type": "evidence",
    "source": "prior_investigation",
    "availability": [
      {"flag":"found_real_murder_clue", "equals":true}
    ],
    "actions": ["grasp", "speak", "keep", "discard"],
    "effects": {
      "speak": [
        {"target":"situation", "key":"revengeNarrative", "op":"add", "value":-2},
        {"target":"intention", "key":"continuePersuasion", "op":"add", "value":1},
        {"target":"situation", "key":"elizabethInvolvement", "op":"add", "value":1}
      ]
    },
    "flavor": "真相可以削弱复仇，也可能把另一个人推到枪口前。"
  },
  {
    "id": "hands_are_shaking",
    "title": "手在发抖",
    "type": "emotion",
    "source": "scene_pressure",
    "availability": [],
    "actions": ["suppress", "discard"],
    "effects": {
      "grasp": [
        {"target":"intention", "key":"freeze", "op":"add", "value":2},
        {"target":"intention", "key":"shootIntervention", "op":"add", "value":-1}
      ],
      "suppress": [
        {"target":"intention", "key":"freeze", "op":"add", "value":-1},
        {"target":"log", "key":"suppressed_emotion", "op":"flag", "value":true}
      ]
    },
    "flavor": "这不是错误念头，这是身体不想死。"
  }
]
```

---

## 11. 伪代码

```ts
function runPressureNode(state: EncounterState, node: PressureNode): EncounterState {
  state.willpower = state.maxWillpowerPerNode;
  state.emergencePool = generateEmergencePool(state, node);

  while (state.willpower > 0 && !nodeShouldEnd(state, node)) {
    const action = getPlayerAction(state);
    state = applyPlayerAction(state, action);
  }

  state.situationTracks.pressure += node.basePressureGain;
  return state;
}

function applyPlayerAction(state: EncounterState, action: PlayerAction): EncounterState {
  switch (action.type) {
    case 'grasp':
      spendWillpower(state, 1);
      moveCard(state.emergencePool, state.workingMemory, action.cardId);
      applyEffects(state, action.card.effects.grasp ?? []);
      break;
    case 'speak':
      spendWillpower(state, 1);
      applyEffects(state, action.card.effects.speak ?? []);
      markCardUsed(state, action.cardId);
      break;
    case 'suppress':
      spendWillpower(state, action.cost ?? 1);
      applyEffects(state, action.card.effects.suppress ?? []);
      removeOrMuteCard(state, action.cardId);
      break;
    case 'keep':
      spendWillpower(state, 1);
      markCardKept(state, action.cardId);
      break;
    case 'discard':
      discardCard(state, action.cardId);
      break;
    case 'refresh':
      spendWillpower(state, 1);
      state.situationTracks.pressure += 1;
      state.emergencePool = generateEmergencePool(state, currentNode(state));
      break;
  }
  return state;
}

function resolveEncounter(state: EncounterState): EncounterResult {
  const dominant = resolveDominantIntention(state.intentionTracks);
  const gunfight = resolveGunfightSequence(state, dominant);
  const kim = resolveKimWarning(state, gunfight);
  return buildEncounterResult(state, gunfight, kim);
}
```

---

## 12. 最小可实现版本 MVP

### 必需内容

- 4 个压力节点。
- 约 18-24 张牌。
- 6 条意愿轨。
- 8 条局势轨。
- 心力系统。
- 工作记忆上限。
- 刷新代价。
- 最高意愿自动执行。
- 固定枪战结算顺序。
- 最后 Kim 警告结算。
- 可解释日志。

### 可以暂缓

- 美术表现。
- 完整 UI 动画。
- 大量分支剧情文本。
- 完整前期调查系统。
- 完整技能树。
- 完整装备系统。

### 可以用布尔 flag 模拟的前期变量

```ts
interface PriorFlags {
  foundRealMurderClue: boolean;
  inspectedArmorWeakness: boolean;
  learnedMercenaryBackground: boolean;
  builtTrustWithKim: boolean;
  madeMolotov: boolean;
  recoveredGun: boolean;
  hasSecondBullet: boolean;
  wearingT500Chestplate: boolean;
}
```

---

## 13. 可解释日志要求

每次结算后，系统必须解释关键结果来源。日志格式建议：

```text
结果：Harry 执行了【开枪干预】。
原因：
- 【他们喝醉了】使开枪干预 +1。
- 【护甲有弱点】使开枪干预 +1，并提供命中修正。
- 【Titus 会死】使开枪干预 +2。
- 【手在发抖】已被压下，未提供僵住修正。
最终意愿值：
- 开枪干预 6
- 继续说服 3
- 僵住 2
- 后退自保 1
```

这条日志是核心功能，不是调试附属品。玩家必须理解自动行动不是系统乱选。

---

## 14. 验收标准

原型成功时，测试者应能说出：

1. “我没有直接点开枪，但我理解为什么 Harry 最后开枪。”
2. “我前面抓住的证据和关系牌进入了结算。”
3. “Kim 的命运不是最后一秒随机，而是前期信任和最后警告共同决定的。”
4. “刷新有代价，所以我不是在无脑抽正确答案。”
5. “Harry 倒下不是失败，而是这场暴力的结构性结果。”

原型失败信号：

1. 玩家觉得自己只是在抽“开枪牌”。
2. 玩家觉得系统替自己乱行动。
3. 玩家觉得证据和关系只是数值 buff。
4. 玩家觉得能完全赢下枪战，原作无力感消失。
5. 玩家无法复盘为什么某个意愿成为最高。

---

## 15. 推荐实现顺序

1. 实现 `EncounterState` 与基础轨道。
2. 写死 4 个压力节点。
3. 实现 18-24 张静态卡牌 JSON。
4. 实现 `generateEmergencePool()`，先用规则筛选，后续再加权随机。
5. 实现工作记忆与心力操作。
6. 实现牌效果系统 `applyEffects()`。
7. 实现意愿结算 `resolveDominantIntention()`。
8. 实现固定枪战结算序列。
9. 实现 Kim 最后警告。
10. 实现可解释日志。
11. 最后再考虑 UI、美术、动画。

---

## 16. 设计守则摘要

```text
对话选项 → 浮现牌
技能发声 → 自动浮现的技能声牌
调查信息 → 前期 flag 解锁的证据牌
装备 → 自动结算条件
关系 → 关键节点修正与浮现牌
行动选择 → 意愿竞争结果
战斗 → 固定顺序自动结算
胜利 → 局部伤亡偏移，不是彻底征服暴力
```

最终目标：**用最小系统改动，把原作对话式枪战转化为“压力下意识处理 → 意愿竞争 → 自动灾难结算”的卡牌式中间层。**
