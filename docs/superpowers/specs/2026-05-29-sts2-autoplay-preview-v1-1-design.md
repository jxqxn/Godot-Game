# STS2 自动出牌预览与不可打原因展示 v1.1 设计

## 当前定位

本规格是 `STS2 手牌优先级排序与自动出牌 v1` 的后续小步扩展。

v1 已经完成：

```text
手牌按 play_priority 排序展示
→ 自动选择最高优先级且 can_play 为 true 的牌
→ UI 点击“自动出牌”
→ 复用 _play_card_from_hand() / StmCombat.play_card() / PlayCardAction / ActionQueue 结算
```

v1.1 只补足“自动出牌之前的解释能力”：

```text
玩家能看到系统准备自动打出哪张牌
玩家能看到高优先级牌为什么被跳过
没有可自动打出的牌时，玩家能看到原因
```

本功能仍属于 Godot STS2 主干扩展，不恢复 `will/`、`mind/`、`意愿牌`、`思维牌桌` 或任何旧独立原型。

## 要解决的问题

当前 v1 的自动出牌能工作，但仍是轻度黑箱：

```text
玩家点击“自动出牌”前，不知道会打出哪张牌
高优先级牌费用不足或目标不合法时，UI 没有解释
没有可打牌时，只能看到笼统提示“没有可自动打出的牌”
```

这会影响后续玩法信任感。自动系统必须先可解释，未来才适合承接更复杂的意愿值、偏好、人格或叙事反馈。

## 目标

### 玩家目标

玩家在战斗调试界面中可以明确看到：

```text
当前自动出牌预览：将打出哪张牌
如果高优先级牌被跳过：跳过原因是什么
如果没有可自动打出的牌：主要原因是什么
```

### 工程目标

规则层提供只读预览查询，UI 只显示查询结果。

预览查询必须复用现有主干：

- `StmCard`
- `StmCardManager`
- `StmCombat`
- `StmGameState`
- `StmCombatActions.PlayCardAction`
- `ActionQueue / add_action / drive_actions`
- 现有 GUT 测试体系

自动出牌执行仍走现有路径：

```text
AutoPlayButton
→ 读取预览或重新查询当前可打牌
→ _play_card_from_hand(card)
→ StmCombat.play_card(game_state, card, targets)
→ PlayCardAction
→ ActionQueue
```

## 非目标

v1.1 明确不做：

```text
will / mind / 意愿牌 / 本能牌 / 思维牌桌
人格痕迹
扶植 / 压制
独立 will_debug_scene
复杂目标选择 UI
正式卡牌平衡
新卡牌系统
新行动队列
新战斗运行时
完整 MessageBus
完整 InputRequest / InputSubmission 框架
正式美术 UI 重做
```

本阶段也不修改 Python 参考项目，不从 `slay-the-model-main/` 复制运行时代码。

## 核心概念

### 自动出牌预览

自动出牌预览是一个只读查询结果，用于描述：

```text
如果此刻点击“自动出牌”，系统会尝试打出哪张牌，以及为什么。
```

它不应产生任何战斗副作用。

禁止在预览中：

```text
扣能量
造成伤害
加格挡
移动手牌 / 弃牌 / 抽牌堆
调用 card.play()
调用 combat.play_card()
调用 game_state.drive_actions()
```

### 不可打原因

v1.1 至少需要支持以下原因：

```text
NO_COMBAT：战斗尚未开始
NO_PLAYER：玩家不存在
EMPTY_HAND：没有手牌
NOT_IN_HAND：卡牌不在手牌中
NOT_ENOUGH_ENERGY：能量不足
NO_LEGAL_TARGET：没有合法目标
CAN_PLAY_REJECTED：卡牌自身 can_play() 拒绝
UNKNOWN：其他原因
```

这些原因可以先作为字符串 code 使用，不要求新增全局枚举，避免扩大 `StmTypes`。

UI 展示应使用中文文案，例如：

```text
战斗尚未开始
没有手牌
能量不足：需要 2，当前 1
没有可选敌人
卡牌规则限制，无法打出
```

## 规则设计

### 1. 预览查询输入

预览查询需要读取：

```text
当前 game_state
当前 combat
当前 player
player.card_manager.hand
hand 的 play_priority 排序视图
card.can_play(game_state)
card.cost
card.target_type
当前存活敌人
```

### 2. 预览查询输出

建议返回 Dictionary，结构语义如下：

```text
ok: bool
selected_card: card 或 null
selected_reason: String
blocked_reason_code: String
blocked_reason_text: String
skipped: Array[Dictionary]
```

当存在可自动打出的牌：

```text
ok = true
selected_card = 当前将打出的牌
selected_reason = “将自动打出：<卡名>”
blocked_reason_code = ""
blocked_reason_text = ""
skipped = 查询过程中被跳过的更高优先级牌及原因
```

当不存在可自动打出的牌：

```text
ok = false
selected_card = null
selected_reason = ""
blocked_reason_code = 主要失败原因 code
blocked_reason_text = 中文原因
skipped = 所有被检查过但不可打的牌及原因
```

### 3. 遍历规则

预览必须与 v1 自动选择保持一致：

```text
读取 StmCardManager.get_hand_sorted_by_priority()
从右往左检查
找到第一张“可打且目标合法”的牌作为 selected_card
如果没有找到，返回失败预览
```

如果优先级相同，仍沿用 v1 的稳定排序规则。

### 4. can_play 与原因查询

当前 `StmCard.can_play(game_state)` 是 bool 语义，v1.1 不应强制改成 tuple 或复杂结果对象。

建议采用旁路只读原因查询：

```text
card.can_play(game_state) 继续决定是否能打
预览 helper 负责解释常见失败原因
```

优先解释顺序建议：

```text
战斗上下文缺失
玩家缺失
卡牌不在手牌
能量不足
can_play() 返回 false
目标不合法
```

如果后续要让卡牌自定义不可打原因，应另开规格，不在 v1.1 中扩展。

### 5. 目标合法性

v1.1 只判断当前调试战斗中的最小目标合法性：

```text
敌方目标牌：至少存在一个存活敌人
自身目标牌：玩家存在
无目标牌：允许无目标
```

不新增复杂目标选择 UI。

自动出牌执行时仍由 `_play_card_from_hand(card)` 处理实际 target 选择。

## UI 行为

### 显示位置

只允许在现有战斗调试界面中增加轻量显示，不新建独立 UI。

候选位置：

```text
StatusLabel 附近
HandLabel 下方
AutoPlayButton 附近
```

建议新增一个轻量 Label：

```text
AutoPlayPreviewLabel
```

### 显示内容

有可自动打出的牌时：

```text
自动出牌预览：将打出 燃烧
```

存在跳过项时，可以追加简短说明：

```text
跳过：痛击（能量不足：需要 2，当前 1）
```

无可自动打出的牌时：

```text
自动出牌预览：没有可自动打出的牌（能量不足）
```

战斗尚未开始时：

```text
自动出牌预览：战斗尚未开始
```

### UI 约束

UI 只能：

```text
调用只读预览查询
展示 selected_card / reason / skipped
点击按钮时发起现有自动出牌请求
```

UI 不应：

```text
自己计算卡牌效果
自己扣能量
自己造成伤害
自己移动牌堆
自己维护第二套 hand
自己绕过 ActionQueue
```

## 验收标准

### 规则验收

1. 战斗未开始时，预览返回 `NO_COMBAT`，不报错。
2. 玩家不存在时，预览返回 `NO_PLAYER`，不报错。
3. 手牌为空时，预览返回 `EMPTY_HAND`。
4. 存在多张可打牌时，预览选择最高优先级且可打、目标合法的牌。
5. 最高优先级牌费用不足时，预览跳过它，并记录 `NOT_ENOUGH_ENERGY`。
6. 敌方目标牌没有存活敌人时，预览跳过它，并记录 `NO_LEGAL_TARGET`。
7. 预览不改变玩家能量、手牌、弃牌堆、敌人血量、玩家格挡。
8. 预览结果与点击“自动出牌”后的实际出牌目标一致。

### UI 验收

1. 战斗调试界面存在自动出牌预览文本。
2. 进入战斗前，预览显示战斗尚未开始或等价文案。
3. 进入战斗后，预览显示当前将自动打出的牌。
4. 当高优先级牌费用不足时，UI 显示跳过原因。
5. 当没有可自动打出的牌时，UI 显示明确原因。
6. UI 不出现 `意愿牌`、`本能牌`、`思维牌桌`、`扶植`、`压制`、`人格痕迹` 等旧原型术语。

### 回归验收

现有测试必须继续通过：

```text
core_skeleton_test.gd
test_battle_debug_scene.gd
test_fixed_battle_fixture.gd
test_powers_v1.gd
test_map.gd
test_rooms.gd
test_game_flow.gd
test_card_priority_autoplay_v1.gd
test_battle_debug_priority_autoplay_v1.gd
test_combat_can_play_guard.gd
```

v1.1 应新增规则测试和 UI 测试，具体测试文件在实施计划中确定。

## 安全 / 边界 / 依赖自检

### 安全自检

- 不修改 `project.godot`。
- 不新增 autoload。
- 不新增插件。
- 不引入网络、文件 IO、外部资源下载或第三方依赖。
- 不修改 `slay-the-model-main/`。
- 不恢复 `scripts/stm/will/` 或 `scripts/stm/mind/`。
- 不新增全局运行时系统。
- 测试必须 deterministic，不依赖随机数、时间或人工点击。

结论：通过。v1.1 只涉及 Godot 主干规则查询、战斗调试 UI 显示和 GUT 测试。

### 边界自检

本阶段只做：

```text
自动出牌只读预览
不可打原因说明
跳过高优先级牌的原因展示
战斗调试 UI 中的轻量文本反馈
对应 GUT 测试
```

本阶段不做：

```text
正式 UI 重做
美术动效
卡牌库扩展
复杂目标选择
意愿牌系统
思维牌桌系统
地图 / 房间 / GameFlow 改动
大重构
```

结论：通过。功能边界是 v1 自动出牌的解释层，不改变主干战斗结算。

### 依赖自检

必须复用：

- `StmCard.can_play(game_state)`
- `StmCardManager.get_hand_sorted_by_priority()`
- `StmCardManager.hand`
- `StmCombat` 当前战斗上下文
- `_play_card_from_hand(card)`
- `StmCombat.play_card()`
- `StmCombatActions.PlayCardAction`
- `StmGameState.add_action()` / `drive_actions()`
- 现有 GUT 测试配置

不得新增：

- 第二套手牌数组
- 第二套自动出牌执行器
- 第二套行动队列
- 第二套卡牌效果结算
- 第二套战斗状态

结论：通过。预览查询只读，执行路径仍保持 v1 主干。

## 风险提示

1. 不要把 `can_play()` 返回值从 bool 改成 tuple；这会影响现有 Godot 调用点。
2. 不要为了原因 code 扩大 `StmTypes.TerminalResult` 或新增无关全局枚举。
3. 目标合法性判断应保持最小，不要引入正式目标选择 UI。
4. UI 预览必须在每次刷新时重新查询，避免缓存旧 card 引用导致显示与实际不一致。
5. 预览查询必须无副作用，测试要覆盖能量、手牌、弃牌堆、敌人血量不变。

## 下一步

规格确认后，下一步再写实施计划文档：

```text
docs/superpowers/plans/2026-05-29-sts2-autoplay-preview-v1-1.md
```

计划文档必须逐步写清：

- 修改哪个文件。
- 新增哪个方法 / Label / 测试。
- 每一步不允许改什么。
- 对应测试是什么。
- 每一步是否存在执行歧义。

在计划被确认前，不进入代码实现。
