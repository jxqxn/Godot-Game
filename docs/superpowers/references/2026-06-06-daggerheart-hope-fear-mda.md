# Daggerheart 希望 / 恐惧四象限结果的 MDA 参考

## 文档元信息

```text
文档类型：外部机制参考 / MDA 研究
创建日期：2026-06-06
参考对象：Daggerheart Duality Dice / Hope & Fear
用途：为 Pressure Encounter v1.1 的自动执行成果层提供设计参考
```

---

## 1. 资料摘要

Daggerheart 的行动检定使用两颗不同颜色的 d12，分别代表 Hope 与 Fear。

规则上，它不是只判断“成功 / 失败”，而是同时判断两条轴：

```text
1. 总点数是否达到难度：决定成功 / 失败。
2. Hope die 与 Fear die 谁更高：决定结果带 Hope 还是带 Fear。
```

因此形成四种基本结果：

```text
Success with Hope
Success with Fear
Failure with Hope
Failure with Fear
```

官方 SRD 对四种结果的简写近似为：

```text
Success with Hope = Yes, and...
Success with Fear = Yes, but...
Failure with Hope = No, but...
Failure with Fear = No, and...
```

Daggerheart 还强调 fail forward：每次掷骰都会让场景发生变化，不存在“什么都没发生”的无效检定。

---

## 2. MDA 拆解

### 2.1 Mechanics：机制层

Daggerheart 的关键机制不是“多一颗骰子”，而是把一次行动结果拆成两个互相独立但同时结算的维度：

```text
行动维度：成功 / 失败
气质维度：Hope / Fear
```

这让系统天然支持四象限结果：

| 行动维度 | 气质维度 | 结果含义 |
|---|---|---|
| 成功 | Hope | 做成了，并且局势向玩家有利方向打开 |
| 成功 | Fear | 做成了，但留下代价、并发症或未来威胁 |
| 失败 | Hope | 没做成，但玩家仍得到资源、信息或缓冲 |
| 失败 | Fear | 没做成，并且局势明显恶化 |

它的重点不是概率本身，而是避免“成功 = 全好 / 失败 = 全坏”的单轴判断。

### 2.2 Dynamics：动态层

四象限结果带来的动态是：

```text
1. 成功不再总是安全。
2. 失败不再总是无价值。
3. 每次行动都会推动局势。
4. 玩家会在“我能不能成”和“成了之后会付出什么”之间产生双重期待。
```

玩家不会只问：

```text
我成功了吗？
```

而会同时问：

```text
我成功了吗？
这次成功让我更有余裕，还是让我背上了新的恐惧？
```

这使行动结果更适合叙事型游戏，因为它能产生“苦涩胜利”和“有希望的失败”。

### 2.3 Aesthetics：体验层

该机制产生的审美体验包括：

```text
紧张：成功也可能带代价。
希望：失败也可能留下转机。
叙事推进：没有空转结果。
命运感：同一个行动同时带来显性结果和情绪余波。
复盘感：玩家会回看这次结果为什么既成了又留下隐患，或为什么失败但保住了希望。
```

它最值得借鉴的不是投骰，而是：

```text
结果不应该只有“能不能成”，还应该有“这件事以什么气质发生”。
```

---

## 3. 对 Pressure Encounter 的启发

### 3.1 不照搬投骰子

Pressure Encounter 不应该直接学习 Daggerheart 的投骰流程。

本项目已有自己的核心结构：

```text
压力积攒环节
→ dominant_action 已经由行动倾向竞争决出
→ outcome_rate 显示该行动的成功率
→ 自动执行环节展示事情如何不可避免地发生
```

因此 Daggerheart 的参考点不是“掷 Hope / Fear 骰”，而是四象限结果结构。

### 3.2 在本项目中拆成两条轴

Pressure Encounter 的自动执行结果可以拆成两条轴：

```text
1. dominant_action 是否成功达成目标。
2. 自动执行后，局势余波偏 Hope 还是 Fear。
```

因此可得到四种结果：

| 本项目结果 | 玩家体验 |
|---|---|
| 希望成功 | 行动成功，而且局势留下余裕、信任、信息或下一轮优势。 |
| 恐惧成功 | 行动成功，但付出代价、增加污染、损伤关系或留下隐患。 |
| 希望失败 | 行动失败，但保住关键关系、得到信息、降低未来风险或打开新机会。 |
| 恐惧失败 | 行动失败，并且压力、污染、关系损伤或局势危险进一步升级。 |

### 3.3 与 outcome_rate 的关系

outcome_rate 只回答一个问题：

```text
dominant_action 成功达成目标的概率是多少？
```

它不应该回答：

```text
这次结果的余波是希望还是恐惧？
```

也就是说：

```text
outcome_rate = 成功轴
hope_fear_tone = 余波轴
```

玩家进入自动执行时可以看到：

```text
行动：强硬干预
成功率：62%
当前余波倾向：恐惧偏高
主要风险：压力过高、情绪污染未处理、同伴信任不足
```

这会带来更复杂的观看快感：

```text
我知道角色会强硬干预。
我知道这次干预有 62% 成功率。
但我也知道，即使成功，也可能是恐惧成功。
```

---

## 4. 映射到自动执行阶段

自动执行阶段可以从：

```text
1. 进入不可干预状态。
2. 确定 dominant_action。
3. 显示 outcome_rate。
4. 展示自动执行过程。
5. 展示最终后果。
6. 简短原因摘要。
```

扩展为：

```text
1. LOCK_IN：进入不可干预状态。
2. CHOOSE_DOMINANT_ACTION：行动倾向竞争决出 dominant_action。
3. SHOW_OUTCOME_RATE：显示该行动成功率。
4. SHOW_HOPE_FEAR_TONE：显示当前余波倾向，例如“希望偏高 / 恐惧偏高”。
5. EXECUTE_SEQUENCE：展示自动执行过程。
6. RESOLVE_QUADRANT：落入四象限结果之一。
7. FINAL_CONSEQUENCE：展示最终后果。
8. CAUSE_SUMMARY：简短说明成功轴和余波轴分别受哪些积累影响。
```

---

## 5. 为什么适合本项目

Pressure Encounter 的目标是模拟人在压力中的决策，而真实决策并不是简单的成功失败。

一个人可能：

```text
做对了事，但方式太激烈，关系破裂。
没做到目标，但保住了信任或留下了线索。
成功压住局势，但内心恐惧加深。
失败了，但终于意识到真正的问题。
```

这正是 Hope / Fear 四象限能表达的东西。

因此，本项目可借鉴的核心不是骰子，而是：

```text
dominant_action 的执行结果 = 成功轴 + 余波轴。
```

这样自动执行阶段就不只是“看成功率开奖”，而是：

```text
看一个已经确定的行动，在成功率和余波倾向共同作用下，如何不可逆地发生。
```

---

## 6. 对 v1.1 的建议

v1.1 不需要做复杂 Hope / Fear 资源系统。

建议只增加轻量概念：

```text
outcome_rate：dominant_action 的成功率。
aftertone：自动执行余波倾向，取 hope / fear。
resolution_quadrant：hope_success / fear_success / hope_failure / fear_failure。
```

v1.1 可以先用已有结构粗略决定 aftertone：

```text
Hope 来源：ally_trust、quieted emotion、steady_response、relationship card、evidence anchor。
Fear 来源：pressure、panic_spiral、unquieted emotion、freeze_response、forceful overcommit。
```

最终结果可表达为：

```text
hope_success：你成功稳住局面，并且同伴开始信任你的判断。
fear_success：你成功压住对方，但所有人都被你的强硬吓到了。
hope_failure：你没能阻止失控，但你抓住了真正的矛盾，下一轮有新机会。
fear_failure：你僵住了，枪声响起，局势彻底失控。
```

---

## 7. 暂不做内容

v1.1 暂不做：

```text
Hope / Fear 代币系统。
GM Fear 资源。
完整骰子模拟。
复杂四象限概率预测。
多行动分布预测。
```

只做：

```text
把自动执行结果从“成功 / 失败”升级为“四象限结果”。
```
