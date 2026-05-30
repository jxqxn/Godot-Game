# STS2 休息房间选择请求 v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-30-sts2-rest-choice-v1-design.md
```

本计划只实现规格中的 v1 范围：

```text
request_type = "rest_choice"
RestRoom.enter() 创建选择请求
GameState.submit_choice() 解析 rest / skip
DebugScene 复用 ChoicePanel 展示休息选择
休息 / 跳过后完成房间并回地图
BDD / TDD 测试
```

不实现：

```text
Smith / 锻造
卡牌升级选择
遗物休息交互
正式营火 UI
特殊休息选项
完整事件系统
完整 InputRequest 迁移
MessageBus
RuntimePresenter
will / mind / 意愿牌 / 思维牌桌
```

## 实施前提

当前已有：

- `scripts/stm/choices/choice_option.gd`
- `scripts/stm/choices/choice_request.gd`
- `scripts/stm/engine/game_state.gd`
  - 已有 `current_choice_request`
  - 已有 `submit_choice(option_id)`
  - 已支持 `card_reward`
- `scripts/stm/rooms/rest.gd`
  - 当前进入后立即恢复 30% HP 并完成房间
- `scripts/stm/debug/battle_debug_scene.gd`
  - 已有通用 `ChoicePanel`
  - 已有 `_on_choice_option_pressed()` 调用 `submit_choice()`
- `.gutconfig.json`
  - 当前已包含主干和 card_reward 相关测试

## 总体实现顺序

严格按 BDD / TDD：

```text
先写 rest_choice 规则测试
再写 DebugScene rest_choice UI 测试
再实现 GameState rest_choice 解析
再改 RestRoom 创建 request
再改 DebugScene 休息房进入流程
再更新旧测试和 GUT 配置
最后完整验证
```

## 实施步骤

### 步骤 1：新增 rest_choice 规则 BDD 测试

新增文件：

```text
scripts/stm/tests/test_rest_choice_v1.gd
```

测试目标：

1. `StmRestRoom.enter(game_state)` 在 player 存在时不立即完成房间。
2. `StmRestRoom.enter(game_state)` 创建 `game_state.current_choice_request`。
3. request 的 `request_type == "rest_choice"`。
4. request title 包含“选择休息行动”。
5. request 包含“休息”和“跳过”两个 option。
6. 休息 option 的 payload：

```text
action = "rest"
```

7. 跳过 option 的 payload：

```text
action = "skip"
```

8. 提交休息 option 后：

```text
player.hp 增加 int(player.max_hp * 0.3)，但不超过 max_hp
room.is_completed == true
current_choice_request == null
room.last_hp_before / last_hp_after / last_heal_amount 正确
result.code == "REST_TAKEN"
```

9. 满血提交休息 option 后：

```text
player.hp 仍为 max_hp
last_heal_amount == 0
room.is_completed == true
```

10. 提交跳过 option 后：

```text
player.hp 不变
room.is_completed == true
current_choice_request == null
last_heal_amount == 0
result.code == "REST_SKIPPED"
```

11. rest_choice payload 非法时返回 `INVALID_PAYLOAD`。

实现约束：

- 只写测试，不写实现。
- 不接 UI。
- 不修改 card_reward 测试。
- 不依赖随机数、时间或人工点击。

完成标准：

- 测试明确锁住“进入休息房先等待选择，选择后完成”。

---

### 步骤 2：新增 DebugScene rest_choice UI BDD 测试

新增文件：

```text
scripts/stm/tests/test_battle_debug_rest_choice_v1.gd
```

测试目标：

1. 调试场景导航到休息房后，点击进入房间不会立即显示下一层。
2. 进入休息房后 `ChoicePanel` 显示。
3. `ChoiceTitleLabel` 显示“选择休息行动”。
4. `ChoiceOptionsContainer` 中存在“休息”和“跳过”按钮。
5. 点击“休息”后：

```text
player.hp 恢复
ChoicePanel 隐藏
current_choice_request 清空
当前 room completed
地图下一层选择出现
日志包含恢复 HP 文案
```

6. 点击“跳过”后：

```text
player.hp 不变
ChoicePanel 隐藏
当前 room completed
地图下一层选择出现
日志包含跳过休息文案
```

实现约束：

- 复用已有 `_instantiate_debug_scene()` / `_press_button()` / `_debug_node_or_null()` 风格。
- 不依赖真实鼠标点击。
- 不改正式 UI。
- 不写 RestPanel。

完成标准：

- UI 测试证明 ChoicePanel 可复用到第二种 request_type。

---

### 步骤 3：在 GameState 中实现 rest_choice 解析

修改文件：

```text
scripts/stm/engine/game_state.gd
```

修改 `submit_choice()`：

```gdscript
match request_type:
    "card_reward":
        return _resolve_card_reward_choice(request, option)
    "rest_choice":
        return _resolve_rest_choice(request, option)
    _:
        return _choice_result(false, "UNSUPPORTED_REQUEST_TYPE", ...)
```

新增方法：

```gdscript
func _resolve_rest_choice(request, option) -> Dictionary
func _record_rest_result(room, before_hp: int, after_hp: int) -> void
func _complete_choice_context_room(request) -> void   # 复用已有，不重复实现
```

`_resolve_rest_choice()` 逻辑：

```text
payload 不是 Dictionary → INVALID_PAYLOAD
payload.action == "rest":
    校验 player 存在
    before_hp = player.hp
    heal_amount = int(float(player.max_hp) * 0.3)
    player.hp = min(player.max_hp, player.hp + heal_amount)
    after_hp = player.hp
    写入 room.last_hp_before / last_hp_after / last_heal_amount
    clear_choice_request()
    _complete_choice_context_room(request)
    return REST_TAKEN

payload.action == "skip":
    before_hp = player.hp if player 存在 else 0
    after_hp = before_hp
    写入 room.last_hp_before / last_hp_after / last_heal_amount = 0
    clear_choice_request()
    _complete_choice_context_room(request)
    return REST_SKIPPED

其他 action → INVALID_PAYLOAD
```

返回 code：

```text
REST_TAKEN
REST_SKIPPED
INVALID_PAYLOAD
```

实现约束：

- 不改 card_reward 分支语义。
- 不改 action_queue。
- 不改 TerminalResult。
- 不让 UI 参与 HP 修改。
- 不引入 Smith / upgrade 逻辑。

对应测试：

- `test_rest_choice_v1.gd` 中 submit 相关测试通过。

完成标准：

- rest_choice 成功后清空 request。
- rest_choice 成功后 complete room。
- HP 与 last_* 字段正确。

---

### 步骤 4：改 RestRoom.enter() 创建 rest_choice 请求

修改文件：

```text
scripts/stm/rooms/rest.gd
```

新增 preload：

```gdscript
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
```

修改 `enter(game_state)`：

当前行为：

```text
重置 last_*
如果无 player：is_completed = true
否则直接恢复 HP
is_completed = true
```

目标行为：

```text
super.enter(game_state)
重置 last_*
如果 game_state == null or game_state.player == null:
    is_completed = true
    return
否则：
    game_state.set_choice_request(_create_rest_choice_request(game_state))
    不回血
    不完成
```

新增方法：

```gdscript
func _create_rest_choice_request(game_state)
func _create_rest_choice_options(game_state) -> Array
func _rest_option(game_state)
func _skip_option()
func _rest_heal_preview_text(game_state) -> String
```

请求内容：

```text
id = "rest_choice"
title = "选择休息行动"
request_type = "rest_choice"
options = rest + skip
max_select = 1
must_select = false
context = { "room": self }
```

按钮文本建议：

```text
休息（恢复 21 点 HP）
跳过
```

实现约束：

- 不在 RestRoom.enter() 中恢复 HP。
- 不在 RestRoom.enter() 中 complete room，除非 game_state/player 缺失。
- 不实现 Smith。
- 不实现遗物。

对应测试：

- `test_rest_choice_v1.gd` 中 RestRoom enter 相关测试通过。

完成标准：

- 进入 RestRoom 后等待 rest_choice。

---

### 步骤 5：调整 DebugScene 进入休息房流程

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

修改方法：

```gdscript
func _on_enter_room_pressed() -> void
```

当前休息房逻辑大概率是：

```text
if room_type == "rest":
    game_flow.complete_current_room()
    读取 last_heal_amount
    _on_room_completed()
    return
```

目标逻辑：

```text
if room_type == "rest":
    if _has_active_choice_request():
        map_panel.visible = false
        status_message = "选择休息行动"
        _append_log("进入休息房")
        _refresh_display()
        return
    # 仅保留安全兜底：如果 RestRoom 因无 player 直接 completed，则 _on_room_completed()
```

注意：`game_flow.enter_current_room()` 已经调用 `RestRoom.enter()`，所以 DebugScene 不应再调用 `game_flow.complete_current_room()`。

实现约束：

- UI 不直接修改 HP。
- UI 不直接 complete room。
- UI 不维护第二套 rest state。
- 复用 `_on_choice_option_pressed()`。

对应测试：

- `test_battle_debug_rest_choice_v1.gd` 通过。

完成标准：

- 休息房进入后显示 ChoicePanel。
- 点击选择后回地图。

---

### 步骤 6：增强 DebugScene choice 结果日志

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

检查现有方法：

```gdscript
func _choice_result_log_text(result: Dictionary) -> String
```

要求支持：

```text
REST_TAKEN → 显示恢复 HP 文案，例如 “休息：恢复 21 点 HP（40 → 61）”
REST_SKIPPED → 显示 “跳过休息”
CARD_REWARD_TAKEN / CARD_REWARD_SKIPPED 旧文案不退化
```

可以直接使用 `result.message`，前提是 GameState 返回 message 足够清楚。

实现约束：

- 不为 rest_choice 新建 UI 专用日志状态。
- 不破坏 card_reward 日志测试。

完成标准：

- UI 测试能从 LogLabel 找到恢复 / 跳过文案。

---

### 步骤 7：更新旧测试以符合新休息房流程

可能修改文件：

```text
scripts/stm/tests/test_rooms.gd
scripts/stm/tests/test_game_flow.gd
scripts/stm/tests/test_battle_debug_scene.gd
```

需要查找旧假设：

```text
RestRoom.enter() 后立即 is_completed == true
GameFlow.enter_current_room() 进入 rest 后立即 unlock next floors
DebugScene 进入 rest 后立即显示房间完成
```

新断言应改为：

```text
进入 rest 后 current_choice_request 存在
room 未完成
submit skip/rest 后 room 完成
然后 next floors 出现
```

实现约束：

- 只更新与新规格冲突的旧测试。
- 不为了让测试通过而恢复自动休息。
- 不改战斗奖励测试。

完成标准：

- 旧测试与 rest_choice 新流程一致。

---

### 步骤 8：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

新增测试：

```text
res://scripts/stm/tests/test_rest_choice_v1.gd
res://scripts/stm/tests/test_battle_debug_rest_choice_v1.gd
```

实现约束：

- 保留所有旧测试。
- 不移除 card_reward 相关测试。
- 不加入 `.uid` 文件。

完成标准：

- GUT 会运行新增 rest_choice 测试。

---

### 步骤 9：完整验证与 systematic-debugging

本地执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果失败：

1. 只看第一条失败。
2. 定位具体文件和行号。
3. 判断是新规格导致旧断言过期，还是实现错误。
4. 只修根因。
5. 不借机实现 Smith / 遗物 / 正式 UI。
6. 不改 card_reward 规则。
7. 不改 TerminalResult。
8. 不改 project.godot。

完成标准：

- 新增 rest_choice 测试通过。
- card_reward 测试继续通过。
- GameFlow / DebugScene 旧测试继续通过。
- 手测确认：进入休息房 → 选择休息/跳过 → 回地图。

## 每个步骤是否有歧义：自检

### 步骤 1 自检

- 新增测试文件路径明确。
- RestRoom 行为变化明确。
- rest / skip 结果明确。
- last_* 字段要求明确。

结论：无歧义。

### 步骤 2 自检

- 新增 UI 测试文件路径明确。
- ChoicePanel 节点复用明确。
- 休息 / 跳过按钮与结果明确。
- 不依赖真实点击明确。

结论：无歧义。

### 步骤 3 自检

- 修改文件明确。
- 新增 request_type 明确。
- rest_choice 分支、返回 code、HP 计算明确。
- 不改 card_reward 明确。

结论：无歧义。

### 步骤 4 自检

- 修改文件明确。
- RestRoom.enter 新行为明确。
- 新增 helper 方法明确。
- 不在 enter 里回血 / complete 明确。

结论：无歧义。

### 步骤 5 自检

- 修改方法明确。
- 删除 DebugScene rest 特殊 complete 绕过明确。
- 复用 submit_choice 明确。

结论：无歧义。

### 步骤 6 自检

- 日志来源明确。
- rest_choice 与 card_reward 文案兼容要求明确。

结论：无歧义。

### 步骤 7 自检

- 需要更新的旧假设明确。
- 禁止恢复自动休息明确。

结论：无歧义。

### 步骤 8 自检

- 修改文件明确。
- 新增测试路径明确。
- 保留旧测试明确。

结论：无歧义。

### 步骤 9 自检

- 验证命令明确。
- 失败处理流程明确。
- 禁止越界修复明确。

结论：无歧义。

## 风险提示

1. `test_game_flow.gd` 里休息房相关测试大概率会失败，因为旧流程是进入即完成。
2. `battle_debug_scene.gd` 里休息房特殊分支必须小心移除，避免 UI 绕过 `submit_choice()`。
3. `RestRoom.enter()` 在 player 缺失时可以安全完成，这是为了防止空引用，不代表正常流程。
4. `last_hp_before / last_hp_after / last_heal_amount` 要在 GameState 解析 rest_choice 时写入，而不是 UI 写入。
5. 满血休息恢复量为 0，但仍算选择成功并完成房间。
6. 现有 ChoicePanel 文案要能同时服务 card_reward 和 rest_choice。

## 等待执行确认

本计划完成后，下一步应等待确认。

确认后再进入实现阶段，按本计划执行：

```text
先写 BDD 测试
再实现 GameState rest_choice
再改 RestRoom
再改 DebugScene
再更新旧测试和 GUT 配置
再完整验证
```
