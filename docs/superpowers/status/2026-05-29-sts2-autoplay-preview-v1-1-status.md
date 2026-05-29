# STS2 自动出牌预览与不可打原因展示 v1.1 状态总结

## 阶段结论

`STS2 自动出牌预览与不可打原因展示 v1.1` 已完成。

本轮从 v1 的“按优先级自动出牌”继续小步扩展，补上了自动出牌前的解释能力：

```text
玩家能看到当前自动出牌将选择哪张牌
玩家能看到高优先级牌被跳过的原因
没有可自动打出的牌时，玩家能看到明确原因
点击自动出牌后，实际打出的牌与预览一致
```

本轮已完成完整 superpowers 流程：

```text
规格文档
→ 安全 / 边界 / 依赖自检
→ 实施计划
→ 计划歧义自检
→ BDD 测试
→ TDD 实现
→ 规格审查
→ 代码质量审查
→ 审查问题修复
→ 审查问题处理确认
→ 完整 GUT 验证
→ 功能手测确认
```

## 对应文档

规格文档：

```text
docs/superpowers/specs/2026-05-29-sts2-autoplay-preview-v1-1-design.md
```

实施计划：

```text
docs/superpowers/plans/2026-05-29-sts2-autoplay-preview-v1-1.md
```

状态总结：

```text
docs/superpowers/status/2026-05-29-sts2-autoplay-preview-v1-1-status.md
```

## 完成内容

### 1. 规则层只读自动出牌预览

修改文件：

```text
scripts/stm/engine/combat.gd
```

新增能力：

```gdscript
func get_auto_play_preview(game_state) -> Dictionary:
```

预览返回结构：

```text
ok: bool
selected_card: card 或 null
selected_reason: String
blocked_reason_code: String
blocked_reason_text: String
skipped: Array[Dictionary]
```

支持的原因 code：

```text
NO_COMBAT
NO_PLAYER
EMPTY_HAND
NOT_IN_HAND
NOT_ENOUGH_ENERGY
NO_LEGAL_TARGET
CAN_PLAY_REJECTED
UNKNOWN
```

预览逻辑：

```text
确认 game_state.current_combat == self
确认玩家和 card_manager 存在
读取 hand
调用 get_hand_sorted_by_priority()
从右往左检查最高优先级牌
逐张判断费用、can_play、目标合法性
找到第一张可打牌则返回 selected_card
被跳过的高优先级牌写入 skipped
没有可打牌时返回 blocked_reason_code / blocked_reason_text
```

规则层预览保持只读：

```text
不扣能量
不造成伤害
不加格挡
不移动手牌 / 弃牌 / 抽牌堆
不调用 card.play()
不调用 combat.play_card()
不调用 game_state.drive_actions()
```

### 2. 战斗调试 UI 自动出牌预览

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

新增节点 / 成员：

```text
AutoPlayPreviewLabel
auto_play_preview_label
```

新增 UI 行为：

```text
战斗前显示：自动出牌预览：战斗尚未开始
战斗中显示：自动出牌预览：将打出 <牌名>
跳过高优先级牌时显示：跳过：<牌名>（<原因>）
无可打牌时显示：没有可自动打出的牌（<原因>）
```

按钮行为调整：

```text
AutoPlayButton
→ combat.get_auto_play_preview(game_state)
→ preview.ok 时调用 _play_card_from_hand(preview.selected_card)
→ preview 失败时显示原因
```

仍然复用旧主干执行路径：

```text
_play_card_from_hand(card)
→ StmCombat.play_card(game_state, card, targets)
→ StmCombatActions.PlayCardAction
→ ActionQueue / drive_actions
```

UI 没有直接结算规则。

### 3. BDD / TDD 测试

新增规则测试文件：

```text
scripts/stm/tests/test_autoplay_preview_v1_1.gd
```

覆盖内容：

```text
战斗未开始返回 NO_COMBAT
非当前 combat 查询返回 NO_COMBAT
玩家不存在返回 NO_PLAYER
手牌为空返回 EMPTY_HAND
多张可打牌时选择最高优先级且目标合法的牌
高优先级牌费用不足时记录 NOT_ENOUGH_ENERGY
can_play() 拒绝时记录 CAN_PLAY_REJECTED
旧卡牌引用不在手牌中时记录 NOT_IN_HAND
敌方目标牌没有存活敌人时记录 NO_LEGAL_TARGET
预览无副作用：能量、手牌、弃牌堆、敌人血量、玩家格挡不变
```

新增 UI 测试文件：

```text
scripts/stm/tests/test_battle_debug_autoplay_preview_v1_1.gd
```

覆盖内容：

```text
AutoPlayPreviewLabel 存在
战斗前显示战斗尚未开始
进入战斗后显示将打出的牌
高优先级牌费用不足时显示跳过原因
没有可自动打出的牌时显示明确原因
点击自动出牌后实际打出的牌与预览一致
```

更新 GUT 配置：

```text
.gutconfig.json
```

新增：

```text
res://scripts/stm/tests/test_autoplay_preview_v1_1.gd
res://scripts/stm/tests/test_battle_debug_autoplay_preview_v1_1.gd
```

保留旧测试列表。

## 审查与修复记录

### 规格审查结论

实现满足 v1.1 规格：

```text
规则层提供只读预览查询
UI 只展示查询结果和发起现有自动出牌请求
自动出牌执行仍走主干 PlayCardAction / ActionQueue
没有恢复旧原型
没有新增第二套运行时
```

### 代码质量审查发现并修复的问题

必须修复项 1：

```text
get_auto_play_preview() 最初只检查 game_state.current_combat 是否存在，未校验 current_combat == self。
```

已修复：

```text
现在当 game_state.current_combat != self 时返回 NO_COMBAT。
```

必须修复项 2：

```text
缺少 NOT_IN_HAND 和 CAN_PLAY_REJECTED 的测试覆盖。
```

已修复：

```text
新增对应 BDD 测试。
```

建议增强项：

```text
DebugScene 与 Combat 内部都有目标类型解析逻辑，存在轻微重复。
```

处理状态：

```text
暂缓。当前不影响 v1.1 验收；后续如继续扩目标选择或正式 UI，再考虑收敛到共享 helper。
```

另一个建议增强项：

```text
失败文案在极端情况下可能出现轻微重复。
```

处理状态：

```text
暂缓。当前测试和手测场景符合预期，不作为 v1.1 阻塞项。
```

## 验证结果

用户本地执行完整 GUT 后确认：

```text
Scripts              12
Tests               122
Passing Tests       122
Asserts             394
Time              0.719s

---- All tests passed! ----
```

功能手测结论：

```text
符合预期
```

已手测确认的核心行为：

```text
战斗前显示战斗尚未开始
战斗中显示将自动打出的牌
高优先级牌不可打时显示跳过原因
没有可打牌时显示明确原因
点击自动出牌后实际打出的牌与预览一致
```

Godot / GUT 退出时存在提示：

```text
ObjectDB instances leaked at exit
16 resources still in use at exit
```

处理状态：

```text
未导致测试失败，不作为 v1.1 阻塞项。
如果后续要清理，应另开技术债任务，不混入本轮功能。
```

## 明确未做事项

本轮没有做：

```text
will / mind / 意愿牌 / 本能牌 / 思维牌桌
人格痕迹
扶植 / 压制
独立 will_debug_scene
复杂目标选择 UI
正式 UI 重做
正式美术动效
卡牌库扩展
卡牌平衡
新行动队列
新战斗运行时
完整 MessageBus
完整 InputRequest / InputSubmission 框架
修改 Python 参考项目
```

本轮没有修改：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) 的 bool 语义
Python / STS2 参考项目
```

## 当前项目状态

当前 Godot STS2 主干已经具备：

```text
固定测试地图
房间进入
战斗开始
抽牌
手牌优先级排序展示
自动出牌
自动出牌预览
不可打原因展示
ActionQueue 结算
敌人行动
胜负与房间完成
GUT 回归测试
```

v1.1 的意义：

```text
自动出牌不再是黑箱。
玩家能在点击前理解系统将做什么。
这为未来更复杂的意愿值、偏好、人格或叙事反馈提供了可解释基础。
```

## 后续建议

下一步可选方向有两类。

### 方向 A：继续战斗正反馈

优先级较高，因为玩家能直接看到和操作。

候选：

```text
伤害飘字 / 格挡飘字
出牌后轻量动画反馈
敌人受击反馈
手牌 hover / pressed 反馈
战斗胜利奖励三选一
```

推荐下一步：

```text
STS2 战斗反馈 v1：伤害 / 格挡 / 出牌结果文本反馈强化
```

原因：

```text
承接当前战斗调试 UI
正反馈强
范围小
不需要大重构
能继续强化“玩家操作后有反馈”
```

### 方向 B：奖励三选一

优先级也较高，但涉及房间完成后的奖励流程。

候选目标：

```text
战斗胜利后出现三张奖励卡
玩家选择一张加入 deck
跳过奖励
选择后回到地图
```

风险：

```text
会触及 GameFlow / Room 完成流程
需要更细规格
比战斗反馈 v1 更容易扩大范围
```

### 暂缓方向

继续暂缓：

```text
拟物跑团记录本 UI
2.5D 桌面沉浸态
正式 UI 框架
MessageBus
InputRequest / InputSubmission
will / mind / 意愿牌恢复
```

这些方向仍应保留在 brainstorming，不应直接进入实现。

## 建议的下一轮流程

如果选择继续推进，建议仍按 superpowers 流程：

```text
先选一个小目标
写规格文档
做安全 / 边界 / 依赖自检
写实施计划
做计划歧义自检
用户确认后再实现
BDD / TDD
审查
修复
验证
收尾
```
