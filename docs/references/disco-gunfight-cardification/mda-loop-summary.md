# 枪战卡牌化改造：MDA 机制与循环总结（Codex 参考）

## 文档元信息

```text
文档类型：MDA 机制总结 / 外部案例拆解
整理日期：2026-06-04
仓库位置：docs/references/disco-gunfight-cardification/mda-loop-summary.md
配套文档：minimal-cardification-spec.md、machine-readable-spec.json
原始附件：originals/mda-loop-summary.docx
```

使用边界：

```text
1. 本文不是当前 Godot 项目的正式规格，不可直接按全文实现。
2. 本文中的具体题材、人物、地点、事件只作为机制案例材料。
3. 后续若要转入当前游戏，应先抽象机制，再另写 docs/superpowers/specs/ 下的新规格。
4. 当前项目 AGENTS.md 中的架构边界与开发红线优先级高于本文。
```

---

## 0. 文档定位

本文用于给实现智能体 / Codex 参考，目标是总结“《极乐迪斯科》临近结尾枪战遭遇的卡牌化最小改动版”的 MDA 结构。

它不是完整游戏规格，不定义最终 UI、完整卡库、剧情文案或数值平衡。它只描述一个可实现的遭遇循环：把原本的对话选项、技能发声、调查信息、装备和关系变量，转化为“浮现牌 → 工作记忆 → 意愿轨 → 自动结算”的卡牌式中间层。

核心原则：行动不由玩家直接按钮选择，而是由玩家在有限心力下处理意识牌，改变角色的行动意愿；局势到达临界点后，最高意愿自动生成行动。

---

## 1. MDA 总览

| 层级 | 改造后内容 | 设计目的 |
|---|---|---|
| Mechanics | 浮现牌、工作记忆、心力、意愿轨、局势轨、自动结算 | 把对话选项转化为卡牌式中间层 |
| Dynamics | 玩家在每个压力节点抓牌、压牌、保留、说出，推动意愿竞争 | 让行动从心理结构中生成，而不是由玩家直接点击 |
| Aesthetics | 半受控、压力思考、有限能动性、构筑反馈、悲剧感、回溯理解 | 让玩家觉得“这是我塑造出的角色在行动” |

---

## 2. Mechanics：机制层

### 2.1 原对话选项被替换为“浮现牌”

原版流程：

```text
阅读对话 → 技能发声 → 选择一句话 → 检定或分支
```

改造后流程：

```text
进入对话压力节点 → 系统浮现若干意识牌 → 玩家用心力处理这些牌 → 牌改变局势变量与意愿值
```

意识牌不是普通技能牌，而是哈里此刻能抓住的心理材料。

| 牌 | 类型 | 来源 |
|---|---|---|
| 他们喝醉了 | 观察牌 | 当前局势 |
| 死者不是哈迪兄弟杀的 | 证据牌 | 前期调查 |
| Authority：让他们听见你 | 技能声牌 | 技能等级 |
| Kim 在等你的判断 | 关系牌 | 前期关系 |
| 手在发抖 | 情绪 / 干扰牌 | 当前压力 |
| 护甲有弱点 | 调查 / 观察牌 | 前期观察与技能 |

关键实现原则：证据不是现场购买的；如果前期没有调查到，对应证据牌就不应出现。技能声不是商品；它们根据技能等级和情境自动浮现，玩家只能抓住、压下、顺着它说，或让它参与结算。

### 2.2 三个区域

#### A. 浮现区

类似酒馆战棋的酒馆区域，但不是商店。它表示当前对峙节点中，角色脑内浮现出的可用念头。

生成来源：

- 当前局势；
- 前期调查；
- 技能等级；
- 人格痕迹；
- 装备状态；
- 关系变量；
- 当前压力和身体状态。

#### B. 工作记忆区

类似手牌区域。玩家抓住的牌进入工作记忆。工作记忆有上限，例如 3 或 4 格。

它制造的核心压力是：玩家想保留重要证据、关系回声或技能声音，但恐惧、羞耻、手抖等干扰牌也可能占据格子。

#### C. 意愿轨 / 局势轨

类似战场区域，但不是单位站位。它记录当前哪些行动倾向正在变强，以及局势如何接近爆发。

行动意愿示例：

- 继续说服；
- 开枪干预；
- 投掷烈酒炸弹；
- 僵住；
- 后退自保；
- 警告 Kim。

局势变量示例：

- 雇佣兵失控程度；
- Titus 暴露度；
- Elizabeth 介入度；
- Kim 信任 / 警觉；
- Harry 身体稳定。

每张牌不直接造成结果，而是修改这些轨道。

示例：

```text
【他们喝醉了】
开枪干预 +1
继续说服难度 +1
雇佣兵失控程度 +1

【Kim 在等你的判断】
警告 Kim +1
Kim 信任结算 +1

【手在发抖】
僵住 +2
开枪干预 -1
占用 1 个工作记忆格
```

### 2.3 心力

心力是这场遭遇中的认知预算，类似金币，但语义不是购买力。

可用操作：

| 操作 | 意义 |
|---|---|
| 抓住一张牌 | 把浮现念头放进工作记忆 |
| 说出口 / 顺着它行动 | 让一张工作记忆牌影响当前局势 |
| 压下干扰牌 | 暂时压制恐惧、羞耻、手抖等 |
| 保留到下一节点 | 类似冻结，抓住暂时不能用但重要的念头 |
| 重新浮现 | 类似刷新，但会让局势更危险 |

刷新必须有代价。例如：

```text
重新浮现 3 张牌；
雇佣兵失控程度 +1，或 Titus 暴露度 +1。
```

设计含义：玩家可以继续想，但世界不会等他。

### 2.4 自动执行

玩家不能直接选择“开枪 / 投掷 / 逃跑 / 僵住 / 警告 Kim”。玩家只能通过牌影响这些意愿值。

当局势到达临界点时，系统比较意愿值：

```text
开枪干预：6
继续说服：3
僵住：2
后退自保：1
警告 Kim：2
```

最高意愿自动获得执行权。结果不是“玩家点击开枪”，而是“玩家让角色在这个瞬间变成了更可能开枪的人”。

---

## 3. Dynamics：流程动态

### 节点 1：进入对峙，看清局面

```text
雇佣兵与哈迪兄弟对峙
↓
系统根据当前局势浮现观察牌、干扰牌、关系牌
↓
玩家用心力抓住或压下
```

示例浮现区：

```text
【他们喝醉了】
【Titus 快要顶嘴】
【Kim 在等你的判断】
【手在发抖】
```

玩家可能选择抓住“他们喝醉了”和“Kim 在等你的判断”，并压下“手在发抖”。这一步不是行动选择，而是决定角色第一眼看见了什么。

### 节点 2：瓦解雇佣兵的复仇叙事

```text
前期调查牌开始浮现
↓
玩家决定哪些证据要说出口
↓
证据改变局势，但也制造暴露风险
```

示例：说出“死者不是哈迪兄弟杀的”。可能结果：

```text
雇佣兵复仇叙事 -2
继续说服 +1
Kortenaer 情绪波动 +1
Elizabeth 介入度 +1
```

设计重点：真相不是免费资源。说出真相可能救人，也可能把别人推到枪口前。

### 节点 3：局势恶化，情绪与技能开始抢占意识

```text
局势更危险
↓
技能声牌、情绪牌、身体反应牌增多
↓
玩家必须在理性信息和身体恐惧之间取舍
```

示例浮现区：

```text
【护甲有弱点】
【Reaction Speed：现在！】
【现在逃走还来得及】
【Titus 会死】
```

玩家抓住“护甲有弱点”和“Titus 会死”，放弃“现在逃走还来得及”。于是“开枪干预”意愿上升，“后退自保”没有继续上升。

### 节点 4：局势临界，意愿竞争

```text
雇佣兵失控程度达到临界
↓
不再允许无限思考
↓
系统统计所有意愿值
↓
最高意愿获得执行权
```

示例结果：

```text
开枪干预：6
继续说服：3
僵住：2
后退自保：1
警告 Kim：2
→ 哈里开枪干预
```

如果玩家前面没有压下干扰牌，可能会变成：

```text
僵住：6
开枪干预：3
后退自保：3
继续说服：2
→ 哈里僵住
```

### 节点 5：枪战自动结算

行动确定后，系统按接近原版的顺序清算：

```text
Shanky 是否逃走
↓
Elizabeth 是否被卷入
↓
Titus 是否成为目标
↓
Harry 执行最高意愿
↓
Kortenaer 是否被击倒 / 失稳
↓
Ruud 开枪
↓
Reaction Speed / T-500 胸甲结算
↓
Kim 反击
↓
De Paule 误伤
↓
Harry 中弹倒下
```

玩家前面构筑的不是阵容，而是信息结构、心理结构、关系结构、装备条件和行动倾向。Harry 中弹倒下仍应接近必然，玩家能改变的是局部伤亡，而不是彻底赢下枪战。

### 节点 6：最后警告 Kim

Harry 倒下后，进入最后一个极短的意识窗口。

可能浮现：

```text
【Kim 在等你的判断】
【Authority：让他们听见你】
【血堵住了喉咙】
```

系统检查 Kim 信任、Authority、前面是否保留过相关关系牌、Harry 身体状态和干扰牌数量。然后结算警告 Kim 成功或失败。

设计重点：Kim 能否听见 Harry，不是最后一秒选对了选项，而是整段旅程里他是否真的相信这个 Harry。

---

## 4. Aesthetics：玩家体验

### 4.1 半受控感

玩家会感觉自己不能直接控制角色，但能影响角色抓住什么、压下什么、相信什么。最后行动虽然不是玩家点出来的，却和玩家的干预有关。

### 4.2 压力下思考的真实感

有限工作记忆、有限心力、刷新代价共同模拟突发情况下的认知压力：

```text
我知道有更好的说法，但我现在想不起来。
我想继续思考，但局势不会等我。
我想压住恐惧，但恐惧本身也是信息。
我想救所有人，但一句话可能让另一个人暴露。
```

### 4.3 自走棋式构筑反馈

玩家会体验到：“我没有直接控制枪战，但它是我的构筑打出来的。”只是这里构筑的不是阵容，而是一个人在暴力现场能否理解、行动、喊出警告的心理结构。

### 4.4 悲剧中的有限能动性

目标不是赢下枪战，而是在不可阻止的暴力中改变一点点结果：谁逃走、谁被卷入、Kim 是否相信、Titus 是否活下来。

### 4.5 回溯性理解

结算后，玩家会重新理解前面的选择：调查不是支线内容，Kim 的信任不是好感度，压下“手在发抖”不是单纯去除 debuff，而是在塑造角色面对枪声的方式。

---

## 5. 实现导向的循环伪代码

```text
initialize encounter_state from campaign_state
initialize will_values
initialize situation_tracks

for node in confrontation_nodes:
    floating_cards = generate_floating_cards(
        node,
        campaign_state,
        character_state,
        skill_profile,
        relationship_state,
        equipment_state,
        situation_tracks
    )

    player_mind_points = get_node_mind_points(node, character_state)

    while player_mind_points > 0 and player_has_actions:
        action = player_choose_operation()

        if action.type == "grasp":
            move_card_to_working_memory(action.card)
            player_mind_points -= action.cost

        if action.type == "speak_or_follow":
            apply_card_effect_to_tracks(action.card, will_values, situation_tracks)
            mark_card_as_committed(action.card)
            player_mind_points -= action.cost

        if action.type == "suppress":
            suppress_card(action.card)
            apply_suppression_aftereffect(action.card, character_state)
            player_mind_points -= action.cost

        if action.type == "hold":
            keep_card_for_next_node(action.card)
            player_mind_points -= action.cost

        if action.type == "refresh":
            floating_cards = regenerate_floating_cards()
            increase_pressure(situation_tracks)
            player_mind_points -= action.cost

    update_pressure_after_node(node, situation_tracks)

    if is_crisis_threshold_reached(situation_tracks):
        break

winning_will = get_highest_will(will_values)
resolved_action = execute_will(winning_will)

gunfight_result = resolve_automatic_gunfight(
    resolved_action,
    campaign_state,
    character_state,
    relationship_state,
    equipment_state,
    situation_tracks,
    committed_cards
)

kim_result = resolve_final_kim_warning(
    relationship_state,
    skill_profile,
    character_state,
    committed_cards,
    working_memory
)

write_back_results(gunfight_result, kim_result, character_state, narrative_state)
```

---

## 6. 实现注意点

1. 行动不要直接做成玩家按钮。不要让玩家点击“开枪”。应让玩家通过牌推高“开枪干预”意愿，最后由系统自动选择最高意愿。
2. 证据牌由前期调查决定是否可浮现。不要在现场随机生成玩家未获得的信息。
3. 技能声牌应自动浮现，不应像普通商品一样购买。
4. 干扰牌不是垃圾牌。恐惧、自保、羞耻、手抖都是真实心理材料，可能保护角色，也可能阻碍行动。
5. 刷新必须有代价。每次重新浮现都应推进压力，让玩家意识到“世界不会等我”。
6. 自动枪战应保留不可避免性。Harry 倒下最好接近必然；玩家改变的是局部伤亡，不是获得英雄式胜利。
7. 关系变量要在关键时刻结算。Kim 信任不只是好感度，而是最后一秒他是否相信 Harry 的声音。

---

## 7. 成功标准

这套机制成功时，玩家应说：

- “我没有直接选择开枪，但我理解为什么这个角色最后会开枪。”
- “我一直在找的不是正确选项，而是能让角色在这一秒行动起来的念头。”
- “Kim 能不能听见我，不只是一个判定，而是之前关系的结算。”
- “这不是赢下战斗，而是在灾难中改变了一点点结果。”

失败信号：

- 玩家觉得自己只是在抽“开枪牌”。
- 玩家觉得系统替自己乱行动。
- 玩家觉得刷新只是找正确答案。
- 玩家觉得证据、技能、关系只是普通数值加成，没有叙事重量。
