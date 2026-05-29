# STS2 自动出牌预览与不可打原因展示 v1.1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-29-sts2-autoplay-preview-v1-1-design.md
```

本计划只实现规格中的 v1.1 范围：

```text
自动出牌只读预览
不可打原因说明
跳过高优先级牌的原因展示
战斗调试 UI 中的轻量文本反馈
对应 GUT 测试
```

不恢复 `will/`、`mind/`、`意愿牌`、`本能牌`、`人格痕迹`、`扶植/压制`、`思维牌桌` 等已放弃原型。

## 实施前提

v1 已完成并接入主干：

- `scripts/stm/cards/card.gd`
  - `StmCard.play_priority` 已存在。
  - `StmCard.can_play(game_state)` 当前是 bool 返回值。
- `scripts/stm/player/card_manager.gd`
  - `get_hand_sorted_by_priority()` 已返回稳定排序副本。
  - `find_highest_priority_playable_card(game_state)` 已能按优先级选择可打牌，但不负责目标合法性解释。
- `scripts/stm/engine/combat.gd`
  - `StmCombat.play_card(game_state, card, targets)` 已通过 `StmCombatActions.PlayCardAction` 和 `ActionQueue` 结算。
  - `_execute_play_card()` 已有 `can_play()` 守卫。
- `scripts/stm/debug/battle_debug_scene.gd`
  - `_refresh_hand_buttons(player)` 已按优先级显示手牌。
  - `_on_auto_play_pressed()` 当前直接调用 `find_highest_priority_playable_card(game_state)` 后复用 `_play_card_from_hand(card)`。
  - `_play_card_from_hand(card)` 已处理目标选择、日志、胜负和 UI 刷新。

## 实施步骤

### 步骤 1：新增 v1.1 规则测试文件，先定义预览行为

新增文件：

```text
scripts/stm/tests/test_autoplay_preview_v1_1.gd
```

测试目标：

1. 战斗未开始时，预览返回 `NO_COMBAT`。
2. 玩家不存在时，预览返回 `NO_PLAYER`。
3. 手牌为空时，预览返回 `EMPTY_HAND`。
4. 多张牌可打时，预览选择最高优先级且目标合法的牌。
5. 最高优先级牌费用不足时，预览跳过它并记录 `NOT_ENOUGH_ENERGY`。
6. 敌方目标牌没有存活敌人时，预览跳过它并记录 `NO_LEGAL_TARGET`。
7. 调用预览不会改变玩家能量、手牌、弃牌堆、敌人血量或玩家格挡。

实现约束：

- 只写测试，不改实现代码。
- 使用现有 `StmGameState`、`StmPlayer`、`StmCombat`、测试卡或最小 `StmCard`。
- 不依赖随机抽牌。
- 不依赖人工点击。
- 不引入新测试框架。

完成标准：

- 测试文件路径明确。
- 预期结果与规格中的 reason code 一致。
- 这些测试在实现前允许失败。

---

### 步骤 2：在 StmCombat 增加只读自动出牌预览查询

修改文件：

```text
scripts/stm/engine/combat.gd
```

新增公开方法：

```gdscript
func get_auto_play_preview(game_state) -> Dictionary:
```

建议返回结构：

```text
ok: bool
selected_card: card 或 null
selected_reason: String
blocked_reason_code: String
blocked_reason_text: String
skipped: Array[Dictionary]
```

新增私有辅助方法，命名可按实现微调，但语义必须明确：

```gdscript
func _card_auto_play_block_reason(game_state, card) -> Dictionary:
func _auto_play_preview_success(card, skipped: Array) -> Dictionary:
func _auto_play_preview_failure(code: String, text: String, skipped: Array = []) -> Dictionary:
func _first_alive_enemy_for_preview() -> Variant:
func _card_targets_enemy_for_preview(card) -> bool:
func _card_targets_self_for_preview(card) -> bool:
func _card_target_kind_for_preview(card) -> String:
func _card_display_name_for_preview(card) -> String:
```

核心逻辑：

1. 如果 `game_state == null` 或 `game_state.current_combat == null`，返回 `NO_COMBAT`。
2. 如果 `game_state.player == null`，返回 `NO_PLAYER`。
3. 如果 `player.card_manager == null`，返回 `NO_PLAYER` 或 `UNKNOWN`，以实施时更准确的上下文为准，但测试应固定一种。
4. 如果 `hand` 为空，返回 `EMPTY_HAND`。
5. 调用 `player.card_manager.get_hand_sorted_by_priority()`。
6. 从右往左检查排序后的牌。
7. 对每张牌调用 `_card_auto_play_block_reason(game_state, card)`。
8. 第一张没有阻塞原因的牌就是 `selected_card`。
9. 被跳过的更高优先级牌写入 `skipped`，每项至少包含：

```text
card
card_name
reason_code
reason_text
```

阻塞原因判断顺序：

```text
card == null → UNKNOWN
卡牌不在 hand 中 → NOT_IN_HAND
能量不足 → NOT_ENOUGH_ENERGY
card.can_play(game_state) 返回 false → CAN_PLAY_REJECTED
敌方目标牌没有存活敌人 → NO_LEGAL_TARGET
自身目标牌但 player 不存在 → NO_PLAYER
否则可打
```

能量不足判断：

```text
cost = card.cost 或 card.get("cost")，默认 0
如果 player.energy < cost，则 NOT_ENOUGH_ENERGY
```

目标合法性判断：

```text
TargetType.ENEMY / ALL_ENEMIES：需要至少一个存活敌人
TargetType.SELF：需要 player 存在
TargetType.NONE：允许
TargetType.ALL：v1.1 暂按需要 player 存在，敌人不存在时不阻止，除非现有规则明确要求敌人
```

实现约束：

- 预览方法必须只读。
- 不调用 `card.play()`。
- 不调用 `combat.play_card()`。
- 不调用 `game_state.add_action()`。
- 不调用 `game_state.drive_actions()`。
- 不扣能量。
- 不移动任何牌堆。
- 不改 `StmTypes.TerminalResult`。
- 不把 `StmCard.can_play(game_state)` 改成 tuple。

对应测试：

- 让步骤 1 中的规则测试通过。

完成标准：

- 所有 v1.1 规则测试通过。
- 现有 v1 自动出牌测试仍应通过或只因 UI 后续步骤暂时失败。

---

### 步骤 3：让自动出牌按钮使用预览结果，保证预览与执行一致

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

修改方法：

```gdscript
func _on_auto_play_pressed() -> void:
```

当前逻辑：

```gdscript
var card = game_state.player.card_manager.find_highest_priority_playable_card(game_state)
if card == null:
    status_message = "没有可自动打出的牌"
    ...
_play_card_from_hand(card)
```

改为：

```text
如果 game_state / combat / player 缺失：保持现有“战斗尚未开始”处理
否则调用 combat.get_auto_play_preview(game_state)
如果 preview.ok 为 true：
    _play_card_from_hand(preview.selected_card)
否则：
    status_message 使用 preview.blocked_reason_text
    追加日志
    刷新显示
```

实现约束：

- 不在 `_on_auto_play_pressed()` 中复制目标选择或结算逻辑。
- 不直接扣能量、造成伤害、加格挡或弃牌。
- 点击后真正执行仍由 `_play_card_from_hand(card)` 处理。
- 不删除 `StmCardManager.find_highest_priority_playable_card(game_state)`，以免破坏 v1 测试或后续调用。

对应测试：

- 更新或新增 UI 测试，验证按钮实际打出的牌与预览一致。
- 最高优先级牌无合法目标时，按钮不应尝试打出该牌。

完成标准：

- v1 的自动出牌按钮行为仍可用。
- v1.1 的预览结果与点击行为一致。

---

### 步骤 4：在战斗调试 UI 增加自动出牌预览 Label

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

新增成员变量：

```gdscript
var auto_play_preview_label: Label
```

在 `_build_ui()` 中新增轻量 Label。

建议位置：

```text
StatusLabel 附近，Buttons 容器之前
```

节点名：

```text
AutoPlayPreviewLabel
```

新增或修改辅助方法：

```gdscript
func _refresh_auto_play_preview_label() -> void:
func _auto_play_preview_text(preview: Dictionary) -> String:
func _auto_play_skipped_text(skipped: Array) -> String:
```

刷新规则：

1. `_refresh_display()` 每次刷新时更新该 Label。
2. `_show_no_combat_display()` 中也要更新为“自动出牌预览：战斗尚未开始”。
3. 地图状态且战斗未开始时，显示“自动出牌预览：战斗尚未开始”。
4. 战斗中调用 `combat.get_auto_play_preview(game_state)`。

文案建议：

```text
自动出牌预览：将打出 燃烧
自动出牌预览：将打出 打击；跳过：痛击（能量不足：需要 2，当前 1）
自动出牌预览：没有可自动打出的牌（能量不足：需要 2，当前 0）
自动出牌预览：战斗尚未开始
```

实现约束：

- UI 只格式化和展示预览结果。
- UI 不重新实现完整可打性判断。
- UI 不维护第二套手牌顺序。
- UI 不出现旧原型术语。

对应测试：

- UI 测试检查 Label 存在。
- 战斗前 Label 显示战斗尚未开始。
- 战斗后 Label 显示将打出的牌。
- 费用不足时 Label 显示跳过原因。

完成标准：

- 调试界面有稳定可定位的 `AutoPlayPreviewLabel`。
- 手动刷新、出牌后刷新、结束回合后刷新都不会显示旧预览。

---

### 步骤 5：新增或扩展战斗调试 UI v1.1 测试

优先新增文件：

```text
scripts/stm/tests/test_battle_debug_autoplay_preview_v1_1.gd
```

如果复用旧文件更简洁，也可以扩展：

```text
scripts/stm/tests/test_battle_debug_priority_autoplay_v1.gd
```

但建议新增 v1.1 文件，避免 v1 测试职责膨胀。

测试内容：

1. `AutoPlayPreviewLabel` 节点存在。
2. 进入战斗前显示“战斗尚未开始”。
3. 进入战斗后，预览显示当前将自动打出的最高优先级可打牌。
4. 当最高优先级牌费用不足时，预览显示跳过原因。
5. 当没有可自动打出的牌时，预览显示明确原因。
6. 点击“自动出牌”后，实际打出的牌与预览牌一致。

实现约束：

- 使用现有 `_instantiate_debug_scene()`、`_press_button()`、`_replace_hand()` 风格。
- 如需访问节点路径，沿用已有 `_relocated_debug_path()` 思路。
- 不依赖真实鼠标点击。
- 不依赖时间等待。

完成标准：

- UI v1.1 测试覆盖规格 UI 验收标准。

---

### 步骤 6：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

如果新增以下测试：

```text
res://scripts/stm/tests/test_autoplay_preview_v1_1.gd
res://scripts/stm/tests/test_battle_debug_autoplay_preview_v1_1.gd
```

则加入 `tests` 列表。

实现约束：

- 保留现有测试列表。
- 不加入任何 `will`、`mind`、旧意愿牌原型测试。
- 不移除 v1 自动出牌测试。

完成标准：

- 完整 GUT 能同时运行旧主干测试、v1 测试和 v1.1 测试。

---

### 步骤 7：执行后自检与修复

实现完成后执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果失败：

1. 先记录第一条失败。
2. 定位错误文件和行号。
3. 判断是规格不清、计划实现错误、测试预期错误还是既有行为被破坏。
4. 只修根因。
5. 不扩大 `StmTypes.TerminalResult`。
6. 不改变 `can_play()` bool 语义。
7. 不为绕过测试而在 UI 中直接结算规则。
8. 修复后重新运行完整 GUT。

不得因为新测试通过就忽略旧测试失败。

完成标准：

- 新增 v1.1 测试通过。
- v1 自动出牌测试继续通过。
- 旧主干测试继续通过。
- UI 手测可看到预览文案，并且点击后行为符合预览。

## 每个步骤是否有歧义：自检

### 步骤 1 自检

- 新增测试文件路径明确：`scripts/stm/tests/test_autoplay_preview_v1_1.gd`。
- 测试 reason code 明确。
- 测试不依赖 UI、随机数或人工点击明确。
- 允许先失败明确。

结论：无歧义。

### 步骤 2 自检

- 修改文件明确：`scripts/stm/engine/combat.gd`。
- 公开方法名明确：`get_auto_play_preview(game_state)`。
- 返回 Dictionary 字段明确。
- 阻塞原因 code 明确。
- 判断顺序明确。
- 只读约束明确。
- 明确不改 `can_play()` 返回值、不改 `TerminalResult`。

结论：无歧义。

### 步骤 3 自检

- 修改文件明确：`scripts/stm/debug/battle_debug_scene.gd`。
- 修改方法明确：`_on_auto_play_pressed()`。
- 新逻辑明确：按钮使用 preview.selected_card。
- 执行路径仍复用 `_play_card_from_hand(card)` 明确。
- 不删除 v1 CardManager 方法明确。

结论：无歧义。

### 步骤 4 自检

- 修改文件明确：`scripts/stm/debug/battle_debug_scene.gd`。
- 新增节点名明确：`AutoPlayPreviewLabel`。
- 新增成员变量明确：`auto_play_preview_label`。
- 建议位置明确：`StatusLabel` 附近、`Buttons` 前。
- 刷新时机明确：`_refresh_display()` 与无战斗显示。
- UI 只展示、不结算明确。

结论：无歧义。

### 步骤 5 自检

- 新增 UI 测试文件路径明确。
- 允许扩展旧测试但优先新增文件，取舍明确。
- 测试目标明确。
- 节点路径处理方式明确。
- 不依赖人工点击明确。

结论：基本无歧义；唯一可选点是“新增文件还是扩展旧文件”，本计划已给出优先选择：新增 `test_battle_debug_autoplay_preview_v1_1.gd`。

### 步骤 6 自检

- 修改文件明确：`.gutconfig.json`。
- 新增测试路径明确。
- 保留旧测试明确。
- 不加入旧原型测试明确。

结论：无歧义。

### 步骤 7 自检

- 验证命令明确。
- 失败处理流程明确。
- 禁止越界修复明确。
- 必须跑完整 GUT 明确。

结论：无歧义。

## 风险提示

1. `game_state.current_combat == null` 与 `combat == null` 的情况要分清：规则层可以返回 `NO_COMBAT`，UI 层在没有 combat 对象时也要显示同等文案。
2. `find_highest_priority_playable_card(game_state)` 不判断目标合法性；v1.1 按钮改用 preview 后，避免预览和执行不一致。
3. 不要把 `_card_targets_enemy()` 逻辑继续留成 UI 唯一判断来源；目标合法性预览应进入 `StmCombat` 规则层。
4. 预览文案不要过长，调试 UI 只显示第一条或简短跳过摘要即可。
5. 无副作用测试必须覆盖：能量、手牌、弃牌堆、敌人血量、玩家格挡。
6. 如果发现现有目标类型判断不完整，只补 v1.1 所需 `NONE / SELF / ENEMY / ALL_ENEMIES / ALL`，不要引入正式目标选择系统。

## 等待执行命令

本计划完成后，下一步应等待确认。

确认后再进入代码实现阶段。实现阶段应按本计划执行：

```text
先写测试
再写规则层预览
再接 UI 按钮
再加预览 Label
再更新 GUT 配置
再跑完整测试
```
