# STS2 通用选择请求框架与战斗胜利卡牌奖励 v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-29-sts2-choice-request-card-reward-v1-design.md
```

本计划只实现规格中的 v1 范围：

```text
最小 ChoiceOption
最小 ChoiceRequest
GameState current_choice_request / submit_choice
card_reward request_type
战斗胜利后奖励三选一
选择卡牌加入 deck
跳过奖励
奖励处理后完成房间并回地图
战斗调试 UI 展示选择请求
BDD / TDD 测试
```

不实现完整 Python InputRequest / InputSubmission，不引入完整 MessageBus / RuntimePresenter / AI driver，不恢复 `will/`、`mind/`、`意愿牌`、`思维牌桌` 等旧原型。

## 实施前提

当前主干已有：

- `scripts/stm/engine/game_state.gd`
  - 管理 `player`、`current_combat`、`action_queue`。
  - 已有 `add_action()`、`add_actions()`、`drive_actions()`。
- `scripts/stm/engine/game_flow.gd`
  - `handle_combat_result(result)` 会把战斗结果交给当前房间。
  - `advance_to_next_floor()` 要求当前房间 completed。
- `scripts/stm/rooms/combat.gd`
  - `handle_combat_result(COMBAT_WIN)` 当前直接 `complete(game_state)`。
- `scripts/stm/debug/battle_debug_scene.gd`
  - 已有地图面板、战斗面板、手牌按钮、自动出牌预览、状态日志。
  - `_finish_combat_result(result)` 在胜利后调用 `game_flow.handle_combat_result(result)` 并进入 `_on_room_completed()`。
- `scripts/stm/player/card_manager.gd`
  - 已有 `deck`。
  - 已有 `add_to_pile(pile_name, card, pos_type)`。
  - 已有 `get_pile(pile_name)`。
- 测试配置 `.gutconfig.json` 已覆盖主干、v1、v1.1 测试。

## 总体实现顺序

严格按 BDD / TDD：

```text
先写选择框架规则测试
再写战斗奖励流程测试
再写 UI 行为测试
再实现 ChoiceOption / ChoiceRequest
再接 GameState submit_choice
再接 CombatRoom 奖励请求
再接 DebugScene ChoicePanel
再更新 GUT 配置
最后跑完整 GUT
```

## 实施步骤

### 步骤 1：新增选择请求规则 BDD 测试

新增文件：

```text
scripts/stm/tests/test_choice_request_v1.gd
```

测试目标：

1. `StmChoiceOption` 能保存 `id / label / detail / payload / enabled`。
2. `StmChoiceRequest` 能保存 `id / title / request_type / options / max_select / must_select / context`。
3. `StmChoiceRequest.get_option(option_id)` 能返回对应 option。
4. `StmChoiceRequest.has_option(option_id)` 正确返回 true / false。
5. `StmChoiceRequest.enabled_options()` 只返回 enabled option。
6. `StmGameState.set_choice_request(request)` 后 `has_choice_request()` 为 true。
7. `StmGameState.clear_choice_request()` 后 `has_choice_request()` 为 false。
8. 无 request 时 `submit_choice()` 返回 `NO_CHOICE_REQUEST`。
9. option id 不存在时 `submit_choice()` 返回 `OPTION_NOT_FOUND`。
10. disabled option 提交时 `submit_choice()` 返回 `OPTION_DISABLED`。
11. unsupported request_type 提交时 `submit_choice()` 返回 `UNSUPPORTED_REQUEST_TYPE`。

实现约束：

- 只写测试，不写实现。
- 不引入外部依赖。
- 不修改现有测试。
- 测试不依赖 UI。
- 测试不依赖随机数、时间或人工点击。

完成标准：

- 测试文件路径明确。
- 失败 code 文案与规格一致。
- 这些测试在实现前允许失败。

---

### 步骤 2：新增战斗胜利 card_reward 规则 / 流程 BDD 测试

新增文件：

```text
scripts/stm/tests/test_combat_card_reward_choice_v1.gd
```

测试目标：

1. `StmCombatRoom.handle_combat_result(COMBAT_WIN, game_state)` 不再立即 complete room。
2. 战斗胜利后创建 `game_state.current_choice_request`。
3. request 的 `request_type == "card_reward"`。
4. request title 为“选择一张奖励卡牌”或等价文案。
5. request 至少包含 3 个奖励卡 option 和 1 个跳过 option。
6. 奖励卡 option 的 payload：

```text
action = "take_card"
card != null
```

7. 跳过 option 的 payload：

```text
action = "skip"
card = null
```

8. 选择奖励卡后：

```text
deck.size() + 1
加入的是对应 card
current_choice_request == null
room.is_completed == true
```

9. 跳过奖励后：

```text
deck.size() 不变
current_choice_request == null
room.is_completed == true
```

10. 重复调用 `handle_combat_result(COMBAT_WIN, game_state)` 不会生成重复奖励 request。
11. 如果 room 已 completed，再次处理胜利不会重新创建奖励。

实现约束：

- 使用 `StmCombatRoom` 和现有 `StmGameState`。
- 使用 fixture / 测试卡创建玩家和战斗环境。
- 不要求真实打完战斗；可以直接调用 `handle_combat_result(COMBAT_WIN, game_state)` 验证房间行为。
- 不接 UI。
- 不引入随机奖励。

完成标准：

- 流程测试明确锁住“胜利后等待奖励，奖励后完成房间”。

---

### 步骤 3：新增战斗调试 UI BDD 测试

新增文件：

```text
scripts/stm/tests/test_battle_debug_choice_reward_v1.gd
```

测试目标：

1. 无 `current_choice_request` 时 `ChoicePanel` 隐藏。
2. 战斗胜利后 `ChoicePanel` 显示。
3. `ChoiceTitleLabel` 显示“选择一张奖励卡牌”或等价文案。
4. `ChoiceOptionsContainer` 中有 3 个奖励卡按钮和 1 个跳过按钮。
5. 奖励阶段 `AutoPlayButton` disabled。
6. 奖励阶段 `EndTurnButton` disabled。
7. 奖励阶段手牌按钮 disabled。
8. 点击奖励卡按钮后：

```text
日志包含“获得 <卡名>”或等价文案
deck 数量增加
ChoicePanel 隐藏
地图下一层选择出现
```

9. 点击跳过奖励后：

```text
日志包含“跳过奖励”或等价文案
deck 数量不变
ChoicePanel 隐藏
地图下一层选择出现
```

实现约束：

- 复用现有 `_instantiate_debug_scene()`、`_press_button()`、`_relocated_debug_path()` 风格。
- 不依赖真实鼠标点击。
- 不依赖时间等待。
- 不需要正式 UI 美术。

完成标准：

- UI 测试覆盖规格中的 UI 验收标准。

---

### 步骤 4：新增 StmChoiceOption

新增文件：

```text
scripts/stm/choices/choice_option.gd
```

新增类：

```gdscript
class_name StmChoiceOption
extends RefCounted
```

字段：

```gdscript
var id: String = ""
var label: String = ""
var detail: String = ""
var payload: Dictionary = {}
var enabled: bool = true
```

构造方法：

```gdscript
func _init(
    p_id: String = "",
    p_label: String = "",
    p_detail: String = "",
    p_payload: Dictionary = {},
    p_enabled: bool = true
) -> void:
```

实现约束：

- 不依赖 UI。
- 不包含 actions 列表。
- 不包含 Python Option 的 command / localization 逻辑。
- payload 只作为规则数据容器。

对应测试：

- 让 `test_choice_request_v1.gd` 中 ChoiceOption 字段测试通过。

完成标准：

- 类可被 `preload()` 或 global class 使用。

---

### 步骤 5：新增 StmChoiceRequest

新增文件：

```text
scripts/stm/choices/choice_request.gd
```

新增类：

```gdscript
class_name StmChoiceRequest
extends RefCounted
```

字段：

```gdscript
var id: String = ""
var title: String = ""
var request_type: String = ""
var options: Array = []
var max_select: int = 1
var must_select: bool = true
var context: Dictionary = {}
```

构造方法：

```gdscript
func _init(
    p_id: String = "",
    p_title: String = "",
    p_request_type: String = "",
    p_options: Array = [],
    p_max_select: int = 1,
    p_must_select: bool = true,
    p_context: Dictionary = {}
) -> void:
```

新增方法：

```gdscript
func get_option(option_id: String)
func has_option(option_id: String) -> bool
func enabled_options() -> Array
```

实现约束：

- 不执行选择结果。
- 不知道 card_reward 规则。
- 不知道 UI。
- 不新增多选处理。

对应测试：

- 让 `test_choice_request_v1.gd` 中 request 查询测试通过。

完成标准：

- `get_option()` 使用 `option.id` 查找。
- `enabled_options()` 过滤 `enabled == true`。

---

### 步骤 6：在 StmGameState 中接入 current_choice_request 与 submit_choice

修改文件：

```text
scripts/stm/engine/game_state.gd
```

新增 preload：

```gdscript
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
```

新增字段：

```gdscript
var current_choice_request = null
```

新增方法：

```gdscript
func set_choice_request(request) -> void
func clear_choice_request() -> void
func has_choice_request() -> bool
func submit_choice(option_id: String) -> Dictionary
```

新增私有辅助方法：

```gdscript
func _choice_result(ok: bool, code: String, message: String, request_type: String = "", selected_option_id: String = "") -> Dictionary
func _resolve_card_reward_choice(request, option) -> Dictionary
func _complete_choice_context_room(request) -> void
func _choice_card_display_name(card) -> String
```

`submit_choice()` 逻辑：

```text
current_choice_request == null → NO_CHOICE_REQUEST
request.get_option(option_id) == null → OPTION_NOT_FOUND
option.enabled == false → OPTION_DISABLED
request.request_type == "card_reward" → _resolve_card_reward_choice(request, option)
其他 request_type → UNSUPPORTED_REQUEST_TYPE
```

`_resolve_card_reward_choice()` 逻辑：

```text
payload.action == "skip":
    clear_choice_request()
    _complete_choice_context_room(request)
    return CARD_REWARD_SKIPPED

payload.action == "take_card":
    校验 card != null
    player / card_manager 存在
    player.card_manager.add_to_pile("deck", card)
    clear_choice_request()
    _complete_choice_context_room(request)
    return CARD_REWARD_TAKEN

其他：
    return INVALID_PAYLOAD
```

返回 code：

```text
NO_CHOICE_REQUEST
OPTION_NOT_FOUND
OPTION_DISABLED
UNSUPPORTED_REQUEST_TYPE
INVALID_PAYLOAD
CHOICE_RESOLVED
CARD_REWARD_TAKEN
CARD_REWARD_SKIPPED
```

实现约束：

- 不改 `drive_actions()`。
- 不改 action queue。
- 不改 TerminalResult。
- 不引入 MessageBus。
- UI 不参与规则解析。
- `submit_choice()` 不直接导航地图，只完成 room。

对应测试：

- 让 `test_choice_request_v1.gd` 和 `test_combat_card_reward_choice_v1.gd` 中 submit 相关测试通过。

完成标准：

- 成功/失败都返回结构化 Dictionary。
- card_reward 成功后清空 request。
- card_reward 成功后完成 room。

---

### 步骤 7：在 StmCombatRoom 中创建 card_reward 请求

修改文件：

```text
scripts/stm/rooms/combat.gd
```

新增 preload：

```gdscript
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
```

修改方法：

```gdscript
func handle_combat_result(result: int, game_state) -> void:
```

目标逻辑：

```text
如果 result != COMBAT_WIN：保持原行为
如果 is_completed：return
如果 game_state.current_choice_request 已存在且 request_type == "card_reward"：return
否则创建 card_reward request 并 set_choice_request(request)
```

新增方法：

```gdscript
func _create_card_reward_request(game_state)
func _create_card_reward_options() -> Array
func _reward_card_option(option_id: String, card) -> StmChoiceOption
func _skip_reward_option() -> StmChoiceOption
func _card_reward_label(card) -> String
```

奖励卡 v1：

```text
StrikeScript.new()
DefendScript.new()
BashScript.new()
```

请求内容：

```text
id = "combat_card_reward"
title = "选择一张奖励卡牌"
request_type = "card_reward"
options = 3 张 take_card + 1 个 skip
max_select = 1
must_select = false
context = { "room": self }
```

实现约束：

- 不立即 `complete(game_state)`。
- 不生成随机奖励。
- 不加金币 / 药水 / 遗物。
- 奖励卡必须是新实例。
- 不复制 Python 的完整 reward action 系统。

对应测试：

- 让 `test_combat_card_reward_choice_v1.gd` 通过。

完成标准：

- 胜利后 room 未完成但 request 存在。
- submit 后 room 完成。

---

### 步骤 8：调整 BattleDebugScene 的战斗胜利流程

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

修改方法：

```gdscript
func _finish_combat_result(result: int) -> void:
```

当前行为倾向：

```text
handle_combat_result(result)
_on_room_completed()
```

目标行为：

```text
handle_combat_result(result)
如果 game_state.current_choice_request != null：
    status_message = "战斗胜利，选择奖励"
    _refresh_display()
    return
否则如果当前 room completed：
    _on_room_completed()
否则：
    _refresh_display()
```

实现约束：

- 不在 UI 里创建奖励 request。
- 不在 UI 里 complete room。
- UI 只根据 `current_choice_request` 决定显示选择区。

对应测试：

- 战斗胜利后不立即出现下一层，先出现 ChoicePanel。

完成标准：

- 胜利后进入奖励阶段，地图不提前推进。

---

### 步骤 9：在 BattleDebugScene 新增 ChoicePanel

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

新增成员变量：

```gdscript
var choice_panel: VBoxContainer
var choice_title_label: Label
var choice_options_container: VBoxContainer
```

在 `_build_ui()` 中新增 UI：

```text
AutoPlayPreviewLabel 下方
Buttons 上方
```

节点名：

```text
ChoicePanel
ChoiceTitleLabel
ChoiceOptionsContainer
```

新增方法：

```gdscript
func _refresh_choice_panel() -> void
func _rebuild_choice_option_buttons(request) -> void
func _choice_option_button_text(option) -> String
func _on_choice_option_pressed(option_id: String) -> void
func _choice_result_log_text(result: Dictionary) -> String
```

显示规则：

```text
无 request：ChoicePanel.visible = false，清空 option buttons
有 request：ChoicePanel.visible = true，显示 title，为每个 option 建按钮
```

按钮点击逻辑：

```text
var result = game_state.submit_choice(option_id)
status_message = result.message
_append_log(_choice_result_log_text(result))
如果 result.ok 且 game_flow.current_room completed：
    _on_room_completed()
否则：
    _refresh_display()
```

实现约束：

- UI 不读取 payload.card 后直接加 deck。
- UI 不直接调用 room.complete()。
- UI 不直接导航地图。
- UI 不维护第二套 reward state。

对应测试：

- 让 `test_battle_debug_choice_reward_v1.gd` 中 ChoicePanel 相关测试通过。

完成标准：

- ChoicePanel 能显示/隐藏。
- 选择/跳过后 UI 正确刷新。

---

### 步骤 10：奖励阶段禁用战斗操作

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

修改方法：

```gdscript
func _refresh_button_states() -> void
func _refresh_hand_buttons(player = null) -> void
func _can_play_card_from_hand(card) -> bool
func _refresh_auto_play_preview_label() -> void
```

建议新增辅助方法：

```gdscript
func _has_active_choice_request() -> bool:
```

规则：

```text
如果 _has_active_choice_request():
    end_turn_button.disabled = true
    auto_play_button.disabled = true
    apply_values_button.disabled = true
    hand card buttons disabled = true
    AutoPlayPreviewLabel 可显示 “自动出牌预览：等待选择奖励”
```

实现约束：

- 不影响无 request 时的 v1.1 行为。
- 不改自动出牌规则层。

对应测试：

- UI 测试验证奖励阶段战斗按钮禁用。
- 旧 v1 / v1.1 UI 测试继续通过。

完成标准：

- 奖励阶段不会继续出牌或结束回合。

---

### 步骤 11：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

新增测试路径：

```text
res://scripts/stm/tests/test_choice_request_v1.gd
res://scripts/stm/tests/test_combat_card_reward_choice_v1.gd
res://scripts/stm/tests/test_battle_debug_choice_reward_v1.gd
```

实现约束：

- 保留所有旧测试。
- 不移除 v1 / v1.1 测试。
- 不加入 will / mind 旧原型测试。

完成标准：

- GUT 运行 15 个测试脚本左右，旧新测试都在列表中。

---

### 步骤 12：执行完整验证与 systematic-debugging

本地执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果失败：

1. 只看第一条失败。
2. 定位具体文件和行号。
3. 判断是测试预期、规格歧义、实现错误还是旧行为被破坏。
4. 只修根因。
5. 不借机引入完整 InputRequest / MessageBus。
6. 不改变 `can_play()` bool 语义。
7. 不改变 `TerminalResult`。
8. 不绕过 `submit_choice()` 在 UI 里直接完成奖励。
9. 修复后重新跑完整 GUT。

完成标准：

- 新增测试通过。
- v1.1 测试继续通过。
- 主干旧测试继续通过。
- 手测确认：战斗胜利 → 奖励三选一 → 选择/跳过 → 回地图。

## 每个步骤是否有歧义：自检

### 步骤 1 自检

- 新增测试文件路径明确。
- ChoiceOption / ChoiceRequest 字段明确。
- GameState 基础失败 code 明确。
- 只写测试、不写实现明确。

结论：无歧义。

### 步骤 2 自检

- 新增测试文件路径明确。
- CombatRoom 胜利后行为明确：不立即 complete，先创建 request。
- submit 后 deck / room / request 状态明确。
- 可直接调用 handle_combat_result，不要求真实战斗明确。

结论：无歧义。

### 步骤 3 自检

- 新增 UI 测试文件路径明确。
- ChoicePanel 节点名明确。
- 奖励按钮数量明确：3 奖励 + 1 跳过。
- 奖励阶段禁用哪些按钮明确。
- 点击按钮后的 UI 与 deck 结果明确。

结论：无歧义。

### 步骤 4 自检

- 新增文件路径明确。
- 类名明确。
- 字段和构造参数明确。
- 不包含 actions / commands / localization 明确。

结论：无歧义。

### 步骤 5 自检

- 新增文件路径明确。
- 类名明确。
- 字段和查询方法明确。
- 不包含 card_reward 规则明确。

结论：无歧义。

### 步骤 6 自检

- 修改文件明确。
- 新增字段和方法明确。
- submit_choice 分支和返回 code 明确。
- card_reward 对 deck / request / room 的影响明确。
- 不改 ActionQueue / TerminalResult 明确。

结论：无歧义。

### 步骤 7 自检

- 修改文件明确。
- 修改方法明确。
- 奖励卡来源明确：Strike / Defend / Bash 新实例。
- request 字段明确。
- 重复胜利保护明确。

结论：无歧义。

### 步骤 8 自检

- 修改文件明确。
- 修改方法明确。
- 胜利后 UI 流程明确：有 request 时不调用 _on_room_completed。
- 不在 UI 创建 request 或 complete room 明确。

结论：无歧义。

### 步骤 9 自检

- 修改文件明确。
- 新增 UI 节点名明确。
- 新增方法明确。
- 点击按钮只调用 submit_choice 明确。
- 选择后根据 room completed 刷新流程明确。

结论：无歧义。

### 步骤 10 自检

- 修改方法明确。
- 奖励阶段禁用目标明确。
- 不影响无 request 时 v1.1 行为明确。

结论：无歧义。

### 步骤 11 自检

- 修改文件明确。
- 新增测试路径明确。
- 保留旧测试明确。

结论：无歧义。

### 步骤 12 自检

- 验证命令明确。
- 失败处理流程明确。
- 禁止越界修复明确。

结论：无歧义。

## 风险提示

1. `game_state.submit_choice()` 需要完成 room，但不应直接导航地图；地图推进仍由现有 GameFlow / DebugScene 刷新路径处理。
2. `CombatRoom.handle_combat_result()` 改为奖励 pending 后，旧测试中可能假设胜利后 room 立即 completed；如果有，应根据新规格调整测试，而不是绕过奖励。
3. `_finish_combat_result()` 不能无条件 `_on_room_completed()`，否则奖励阶段会被跳过。
4. 奖励卡必须是新实例，不能从手牌/抽牌堆/弃牌堆中移动。
5. `ChoiceRequest.context.room = self` 是 v1 最小方案，不做存档序列化保证。
6. DebugScene 已经有较多 UI 逻辑，本轮只加 ChoicePanel，不做正式 UI 重构。
7. 如果失败文案或按钮文本与测试稍有差异，应优先统一文案，不扩大系统范围。

## 等待执行确认

本计划完成后，下一步应等待确认。

确认后再进入实现阶段，按本计划执行：

```text
先写 BDD 测试
再实现 ChoiceOption / ChoiceRequest
再实现 GameState submit_choice
再接 CombatRoom card_reward
再接 DebugScene ChoicePanel
再更新 GUT 配置
再跑完整测试
```
