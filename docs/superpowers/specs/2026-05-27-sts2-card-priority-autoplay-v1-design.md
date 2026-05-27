# STS2 手牌优先级排序与自动出牌 v1 设计

## 当前定位

本规格定义一个 STS2 复刻主干扩展：

```text
手牌中的卡牌拥有可解释的出牌优先级
→ 手牌 UI 按优先级排序
→ 玩家点击统一行动按钮
→ 系统自动打出当前最高优先级且可打出的牌
→ 打牌仍然复用现有 STS2 主干流程
```

本功能是 STS2 复刻项目的玩法拓展，不是新的 `will/`、`mind/`、`意愿牌` 或 `思维牌桌` 系统。

当前项目已回退到 5 月 26 日地图 / 房间 / GameFlow 稳定状态。本规格从这个干净主干出发重新设计，不沿用已放弃的意愿牌原型。

## 目标

### 玩法目标

让玩家看到：

```text
当前手牌并不是无序排列，而是按照“此刻最想被打出 / 最适合被打出”的优先级排列。
```

第一版不处理复杂心理机制，只实现一个最小闭环：

```text
排序展示
自动选择
复用现有打牌流程
测试验证
```

### 工程目标

该功能必须接入现有 STS2 主干：

- `StmCard`
- `StmCardManager`
- `StmCombat`
- `StmGameState`
- `StmActionQueue`
- `StmCombatActions.PlayCardAction`
- 现有 GUT 测试体系

不得另建平行手牌系统、平行行动队列或平行战斗规则。

## 非目标

本阶段明确不做：

```text
WillDecisionWindow
StmWillCard
StmWillTrace
StmMindCard
StmMindTable
本能牌
人格痕迹
扶植 / 压制
思维牌桌 UI
新的独立 will_debug_scene
新的独立运行时
```

这些名字和旧原型实现不应出现在本阶段新增代码中。

## 核心概念

### 出牌优先级

每张 `StmCard` 可以拥有一个整数优先级：

```text
play_priority: int
```

语义：

```text
数值越高，越靠右，越优先被自动打出。
```

第一版可使用静态优先级，不要求复杂计算。

示例：

```text
Strike    play_priority = 10
Defend    play_priority = 5
Bash      play_priority = 20
Inflame   play_priority = 30
Shrug It Off play_priority = 15
```

具体数值可以在实现计划中根据当前卡牌库实际情况确定。

### 当前最高优先级可打出牌

自动出牌不应盲目打出最右侧牌，而应选择：

```text
排序后从右往左查找第一张 can_play(player) 为 true 的牌
```

理由：

- 高优先级牌可能费用不足。
- 不可打出的牌可以仍然显示在排序位置，但不能被自动按钮强行打出。
- 自动出牌应复用现有 `can_play()` 约束。

### 排序展示

手牌展示顺序：

```text
左侧 = 低优先级
右侧 = 高优先级
```

如果优先级相同，应保持当前手牌中的相对顺序，避免 UI 抖动。

## 规则设计

### 1. 卡牌字段

在 `StmCard` 中增加：

```gdscript
var play_priority: int = 0
```

或等价命名。

命名要求：

- 优先使用 `play_priority`。
- 不使用 `will`、`mind`、`instinct` 等旧意愿牌原型术语。

### 2. 手牌排序读取

增加一个规则层方法，用于读取排序后的手牌。

候选位置：

```text
StmCardManager.get_hand_sorted_by_priority()
```

或：

```text
StmCombat.get_hand_sorted_by_priority()
```

优先考虑放在 `StmCardManager`，因为排序对象是手牌。

该方法只返回排序视图，不应直接改变 `hand` 原始数组，除非后续明确设计为“真实手牌顺序也要变更”。

v1 建议：

```text
只返回排序副本，不修改原手牌。
```

### 3. 自动选择

新增方法：

```text
find_highest_priority_playable_card(player)
```

候选位置：

```text
StmCardManager.find_highest_priority_playable_card(player)
```

语义：

```text
获取排序后的手牌
从右往左遍历
返回第一张 can_play(player) 为 true 的牌
如果没有可打出牌，返回 null
```

### 4. 自动打牌

自动打牌必须复用现有战斗打牌入口。

优先路径：

```text
StmCombat.play_card(card, target)
```

或当前项目已有的等价入口。

不得新增一套绕过 `PlayCardAction` 的直接结算逻辑。

### 5. 目标选择

v1 只处理现有测试场景中可确定目标的情况。

建议规则：

- 敌方目标牌：使用当前敌人或第一个存活敌人。
- 自身目标牌：目标为玩家自身。
- 无目标牌：目标为空或按现有 `play_card` 规则处理。

如果当前 `play_card` 已经要求显式 target，则自动出牌入口必须复用同一规则，不在 UI 层私自结算效果。

### 6. UI 行为

本阶段不新增独立意愿牌 UI。

只允许在现有战斗调试界面中加入或调整：

```text
手牌显示按 play_priority 排序
右下/底部增加“自动出牌”按钮，或复用现有按钮区域
显示当前自动选择结果
```

UI 只能：

```text
显示排序后的 hand
发起自动出牌请求
显示结果
```

UI 不应：

```text
自己计算卡牌效果
自己修改玩家/敌人状态
自己维护第二套手牌
自己绕过 ActionQueue
```

## 数据与测试用卡

v1 可以先只给测试卡设置优先级。

候选卡：

```text
Strike
Defend
Bash
Inflame
Shrug It Off
```

若当前主干只稳定包含部分卡牌，则以当前实际存在的测试卡为准。

不要求一次补全正式卡牌库。

## 验收标准

### 规则验收

1. `StmCard` 有默认 `play_priority`，默认值不破坏既有卡牌。
2. 手牌排序方法返回低优先级到高优先级的副本。
3. 相同优先级保持原始手牌相对顺序。
4. 自动选择方法返回最高优先级且 `can_play()` 为 true 的牌。
5. 当最高优先级牌费用不足时，会跳过它选择下一张可打牌。
6. 没有可打牌时返回 null，不报错。
7. 自动打牌复用现有 `play_card` / `PlayCardAction` / `ActionQueue` 流程。

### UI 验收

1. 战斗调试界面显示的手牌按优先级从左到右排列。
2. 自动出牌按钮点击后打出当前最高优先级可打出的牌。
3. 打牌后手牌、弃牌堆、能量、敌人血量或玩家格挡等状态按现有规则更新。
4. UI 不出现 `意愿牌`、`本能牌`、`思维牌桌`、`扶植`、`压制`、`人格痕迹` 等旧原型术语。

### 回归验收

现有主干测试必须继续通过：

```text
core_skeleton_test.gd
test_battle_debug_scene.gd
test_fixed_battle_fixture.gd
test_powers_v1.gd
test_map.gd
test_rooms.gd
test_game_flow.gd
```

## 安全 / 边界 / 依赖自检

### 安全自检

- 不修改 `project.godot`。
- 不新增 autoload。
- 不新增插件。
- 不引入网络、文件 IO、外部资源下载或第三方依赖。
- 不修改 `slay-the-model-main/`。
- 不恢复已放弃的 `scripts/stm/will/` 或 `scripts/stm/mind/` 体系。
- 测试必须 deterministic，不依赖随机数、时间或人工点击。

结论：通过。该规格只涉及 Godot 主干 STS2 规则层、战斗调试 UI 和 GUT 测试。

### 边界自检

本阶段只做：

```text
卡牌 play_priority
手牌排序视图
最高优先级可打牌选择
复用现有打牌流程
现有战斗调试界面展示
```

本阶段不做：

```text
新意愿牌系统
新思维牌桌系统
人格痕迹
扶植 / 压制
本能牌
独立 will debug scene
地图 / 房间 / GameFlow 规则改动
```

结论：通过。功能边界清晰，是 STS2 复刻主干上的小型玩法扩展。

### 依赖自检

必须复用：

- `StmCard.can_play()`
- `StmCardManager.hand`
- `StmCombat.play_card()` 或当前等价入口
- `StmCombatActions.PlayCardAction`
- `StmGameState.add_action()` / `drive_actions()`
- 现有 GUT 测试配置

不得新增平行实现：

- 第二套手牌数组
- 第二套行动队列
- 第二套卡牌效果结算
- 第二套战斗状态

结论：通过。后续计划文档必须逐步核对每个步骤是否满足这些依赖约束。

## 下一步

规格确认后，再写实施计划文档。

计划文档必须对每一步做“代理视角歧义检查”，确保每一步都写清：

- 修改哪个文件。
- 新增哪个字段或方法。
- 是否允许改现有行为。
- 对应测试是什么。
- 不允许碰哪些旧原型内容。
