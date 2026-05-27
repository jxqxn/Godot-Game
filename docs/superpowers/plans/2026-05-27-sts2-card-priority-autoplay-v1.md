# STS2 手牌优先级排序与自动出牌 v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-27-sts2-card-priority-autoplay-v1-design.md
```

本计划只实现规格中的 v1 范围：

```text
StmCard.play_priority
StmCardManager 排序视图与最高可打牌选择
战斗调试界面显示排序后的手牌
战斗调试界面通过现有打牌流程自动打出最高优先级可打牌
GUT 测试覆盖
```

不恢复 `will/`、`mind/`、`意愿牌`、`本能牌`、`人格痕迹`、`扶植/压制`、`思维牌桌` 等已放弃原型。

## 实施前提

当前 `main` 已回退到 5 月 26 日地图 / 房间 / GameFlow 稳定状态。

现有主干可复用点：

- `scripts/stm/cards/card.gd`
  - `StmCard.can_play(game_state)` 已按玩家能量判断是否可打出。
  - `StmCard.play(game_state, combat, targets)` 已返回行动数组。
- `scripts/stm/player/card_manager.gd`
  - `StmCardManager.hand` 是当前手牌来源。
  - `get_pile("hand")` 返回当前手牌。
- `scripts/stm/engine/combat.gd`
  - `StmCombat.play_card(game_state, card, targets)` 已通过 `StmCombatActions.PlayCardAction` 和 `ActionQueue` 结算。
- `scripts/stm/debug/battle_debug_scene.gd`
  - `_refresh_hand_buttons(player)` 当前直接按 `hand` 原始顺序创建手牌按钮。
  - `_play_card_from_hand(card)` 当前已有目标选择、`can_play` 检查、日志、胜利处理和 UI 刷新。

## 实施步骤

### 步骤 1：为 StmCard 增加默认出牌优先级字段

修改文件：

```text
scripts/stm/cards/card.gd
```

具体修改：

1. 在基础字段区增加：

```gdscript
var play_priority: int = 0
```

2. 在 `copy()` 中复制：

```gdscript
card.play_priority = play_priority
```

不得修改：

- `can_play()` 的语义。
- `on_play()` 的行动生成逻辑。
- `play()` 的返回结构。

对应测试：

在主干规则测试中验证：

- 新卡默认 `play_priority == 0`。
- `copy()` 后优先级保持一致。

---

### 步骤 2：给当前测试卡设置固定 play_priority

修改文件按当前实际存在卡牌为准，优先检查并修改：

```text
scripts/stm/cards/test/strike.gd
scripts/stm/cards/test/defend.gd
scripts/stm/cards/test/bash.gd
scripts/stm/cards/test/inflame.gd
scripts/stm/cards/test/shrug_it_off.gd
```

具体规则：

- 只在卡牌 `_init()` 或初始化字段中设置 `play_priority`。
- 不修改卡牌伤害、格挡、费用、抽牌、Power 效果。

建议初始数值：

```text
Defend        5
Strike        10
Shrug It Off  15
Bash          20
Inflame       30
```

这些数值仅用于 v1 验证排序和自动选择，不代表最终平衡。

对应测试：

新增或更新测试，验证这些测试卡的优先级值存在且可排序。

---

### 步骤 3：在 StmCardManager 增加排序视图方法

修改文件：

```text
scripts/stm/player/card_manager.gd
```

新增方法：

```gdscript
func get_hand_sorted_by_priority() -> Array:
```

语义：

1. 读取 `hand`。
2. 返回 `hand.duplicate()` 的排序副本。
3. 按 `card.play_priority` 从低到高排序。
4. 如果优先级相同，保持原 `hand` 中的相对顺序。
5. 不修改 `hand` 本身。

实现约束：

- 不直接调用 `hand.sort_custom()`，避免改变原始手牌。
- 对没有 `play_priority` 字段的对象使用默认值 `0`。
- 排序稳定性要通过原始索引保证。

对应测试：

新增测试验证：

- 返回值是排序副本。
- 原 `hand` 顺序不变。
- 低优先级在左，高优先级在右。
- 相同优先级保持原始相对顺序。

---

### 步骤 4：在 StmCardManager 增加最高优先级可打牌选择方法

修改文件：

```text
scripts/stm/player/card_manager.gd
```

新增方法：

```gdscript
func find_highest_priority_playable_card(game_state):
```

语义：

1. 调用 `get_hand_sorted_by_priority()`。
2. 从排序结果最后一张开始向前遍历。
3. 对每张牌调用 `card.can_play(game_state)`。
4. 返回第一张可打出的牌。
5. 如果没有可打出的牌，返回 `null`。

实现约束：

- 不考虑目标选择，目标选择仍由战斗 UI 或 Combat 层处理。
- 不修改玩家能量。
- 不移动手牌。
- 不调用 `combat.play_card()`。

对应测试：

新增测试验证：

- 最高优先级且费用足够的牌被选中。
- 最高优先级但费用不足时会跳过，选择下一张可打牌。
- 全部费用不足时返回 `null`。

---

### 步骤 5：新增或扩展 CardManager 规则测试

优先新增文件：

```text
scripts/stm/tests/test_card_priority_autoplay_v1.gd
```

测试内容：

1. `StmCard.play_priority` 默认值和 copy 行为。
2. `get_hand_sorted_by_priority()` 排序副本行为。
3. 同优先级稳定排序行为。
4. `find_highest_priority_playable_card(game_state)` 的正常选择、费用不足跳过、无可打牌返回 null。

测试约束：

- 使用 `StmCard` 或现有测试卡构造最小数据。
- 可以创建最小 `StmGameState` + `StmPlayer`，但不启动完整战斗。
- 不依赖 UI。
- 不依赖随机抽牌。

---

### 步骤 6：让战斗调试界面的手牌按钮按优先级显示

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

修改方法：

```gdscript
func _refresh_hand_buttons(player = null) -> void:
```

当前逻辑：

```gdscript
var hand: Array = player.card_manager.get_pile("hand")
```

改为：

```gdscript
var hand: Array = player.card_manager.get_hand_sorted_by_priority()
```

实现约束：

- 按钮仍绑定原始 card 对象。
- 不改变 `card_manager.hand` 原始顺序。
- 不修改 `_play_card_from_hand(card)`。
- 不修改现有手动点击手牌的行为。

对应测试：

在 `test_battle_debug_scene.gd` 中新增测试：

- 构造一组手牌，优先级乱序。
- 调用 `_refresh_display()`。
- 读取 `HandButtons` 中按钮文本。
- 断言按钮从左到右按优先级升序排列。

---

### 步骤 7：在战斗调试界面增加“自动出牌”按钮

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

具体修改：

1. 新增成员变量：

```gdscript
var auto_play_button: Button
```

2. 在 `_build_ui()` 的 `Buttons` 容器中，在 `EndTurnButton` 附近新增按钮：

```text
自动出牌
```

节点名：

```text
AutoPlayButton
```

3. 连接信号：

```gdscript
auto_play_button.pressed.connect(_on_auto_play_pressed)
```

4. 在 `_refresh_display()` 中设置禁用状态：

```gdscript
auto_play_button.disabled = combat == null or game_state == null or game_state.player == null
```

5. 在无战斗显示和清理战斗视图时，按钮也应被禁用。

对应测试：

在 `test_battle_debug_scene.gd` 中新增测试：

- 进入战斗前按钮不可用或点击后不改变状态。
- 进入战斗后按钮存在且可用。

---

### 步骤 8：实现自动出牌按钮逻辑，复用现有打牌流程

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

新增方法：

```gdscript
func _on_auto_play_pressed() -> void:
```

实现逻辑：

1. 检查 `game_state`、`combat`、`game_state.player`、`card_manager` 是否存在。
2. 调用：

```gdscript
var card = game_state.player.card_manager.find_highest_priority_playable_card(game_state)
```

3. 如果返回 `null`：

```text
status_message = "没有可自动打出的牌"
追加日志
刷新显示
return
```

4. 如果返回卡牌：

```gdscript
_play_card_from_hand(card)
```

实现约束：

- 不在 `_on_auto_play_pressed()` 中复制 `_play_card_from_hand()` 的目标选择或结算逻辑。
- 不直接扣能量。
- 不直接造成伤害或加格挡。
- 不绕过 `combat.play_card()`。

对应测试：

在 `test_battle_debug_scene.gd` 中新增测试：

- 手牌中有多张可打牌时，点击自动出牌按钮打出最高优先级牌。
- 最高优先级牌费用不足时，自动打出下一张可打牌。
- 没有可打牌时，显示“没有可自动打出的牌”，手牌和状态不应异常改变。

---

### 步骤 9：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

如果新增了：

```text
res://scripts/stm/tests/test_card_priority_autoplay_v1.gd
```

则把它加入 `tests` 列表。

实现约束：

- 不加入任何 `will`、`mind`、`意愿牌` 原型测试。
- 保留现有主干测试。

---

### 步骤 10：执行后自检与修复

实现完成后执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果失败：

1. 先记录第一条失败。
2. 判断是规格不清、计划实现错误、还是现有测试预期受影响。
3. 只修根因，不用补丁绕过。
4. 修复后重新运行测试。

不得因为新功能测试通过就忽略旧测试失败。

## 每个步骤是否有歧义：自检

### 步骤 1 自检

- 修改文件明确：`scripts/stm/cards/card.gd`。
- 字段名明确：`play_priority`。
- 默认值明确：`0`。
- copy 行为明确。
- 不允许修改 `can_play()` / `play()`。

结论：无歧义。

### 步骤 2 自检

- 修改文件范围明确为现有测试卡。
- 优先级数值明确。
- 明确不改卡牌效果和费用。
- 若某个候选卡不存在，则以当前实际存在文件为准。

结论：基本无歧义；唯一变量是候选卡文件是否存在，实现前需要按实际文件确认。

### 步骤 3 自检

- 修改文件明确：`scripts/stm/player/card_manager.gd`。
- 方法名明确：`get_hand_sorted_by_priority()`。
- 返回排序副本而非修改原手牌明确。
- 排序方向明确：低到高。
- 稳定排序要求明确。

结论：无歧义。

### 步骤 4 自检

- 修改文件明确：`scripts/stm/player/card_manager.gd`。
- 方法名明确：`find_highest_priority_playable_card(game_state)`。
- 遍历方向明确：排序后从右往左。
- 可打出判断明确：`card.can_play(game_state)`。
- 不处理目标、不结算效果明确。

结论：无歧义。

### 步骤 5 自检

- 新增测试文件路径明确。
- 测试目标明确。
- 不依赖 UI、不依赖随机抽牌明确。
- 允许使用最小 GameState/Player 明确。

结论：无歧义。

### 步骤 6 自检

- 修改方法明确：`_refresh_hand_buttons(player)`。
- 替换的数据来源明确。
- 按钮仍绑定原 card 对象明确。
- 不改变手动出牌逻辑明确。

结论：无歧义。

### 步骤 7 自检

- 新增按钮节点名明确：`AutoPlayButton`。
- 按钮文本明确：`自动出牌`。
- 添加位置明确：`Buttons` 容器中，`EndTurnButton` 附近。
- 禁用条件明确。

结论：无歧义。

### 步骤 8 自检

- 新增方法名明确：`_on_auto_play_pressed()`。
- 调用选择方法明确。
- 无可打牌提示文本明确。
- 复用 `_play_card_from_hand(card)` 明确。
- 禁止复制结算逻辑明确。

结论：无歧义。

### 步骤 9 自检

- 修改文件明确：`.gutconfig.json`。
- 新增测试路径明确。
- 不加入旧原型测试明确。

结论：无歧义。

### 步骤 10 自检

- 验证命令明确。
- 失败处理流程明确。
- 不允许忽略旧测试失败明确。

结论：无歧义。

## 风险提示

1. 当前 `BattleDebugScene` 的测试中有路径重定位辅助 `_relocated_debug_path()`，新增按钮时应放在既有 `Buttons` 容器中，避免测试路径混乱。
2. `StmCardManager.get_pile("hand")` 返回原数组；排序方法必须使用副本。
3. `find_highest_priority_playable_card()` 不检查敌人目标，因此 UI 自动打牌仍必须走 `_play_card_from_hand()`，由它处理敌人目标和日志。
4. 如果某些卡牌 `copy()` 后没有保留 `play_priority`，战斗抽牌后排序会失效，所以步骤 1 的 copy 测试必须先写。

## 等待执行命令

本计划完成后，下一步应等待确认。确认后再进入代码实现阶段。实现阶段应先写测试，再写代码，再运行 GUT。
