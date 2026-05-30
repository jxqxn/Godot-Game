# STS2 休息房间选择请求 v1 设计

## 当前定位

本规格是 `STS2 通用选择请求框架与战斗胜利卡牌奖励 v1` 之后的主干小步扩展。

当前 Godot 主干已经具备：

```text
地图选择房间
战斗房间
战斗胜利后 card_reward 选择请求
选择奖励卡 / 跳过奖励
奖励处理后完成房间并回地图
Boss 胜利直接通关
调试 UI ChoicePanel 展示选择请求
```

下一步要验证 ChoiceRequest 框架不只是 card_reward 专用，而是可以承载第二类房间选择：休息房间。

本阶段目标：

```text
进入休息房后不再自动回血并立即完成
而是创建 rest_choice 选择请求
玩家选择休息或跳过后，规则层处理结果并完成房间
```

## Python 参考项目依据

Python 参考项目中，休息房不是自动结算。

`RestRoom.enter()` 会构建一组 actions，其中包含 `_build_rest_menu()`。

`_build_rest_menu()` 会生成一个选择菜单：

```text
Rest：恢复 30% 最大生命，之后 LeaveRoom
Smith：如果可升级，选择升级卡牌，之后 LeaveRoom
特殊遗物选项：Girya / Peace Pipe / Shovel 等
Skip：直接 LeaveRoom
```

这个菜单通过 `InputRequestAction` 交给 UI / 运行时，让玩家选择。

Godot 当前不应完整复制 Python 的 RestRoom 全能力，但应吸收其边界：

```text
休息房进入后提出选择
玩家提交选择
规则层执行结果
房间完成并回到地图
```

## 要解决的问题

当前 Godot 的 `StmRestRoom.enter()` 行为是：

```text
进入休息房
→ 立刻恢复 30% 最大生命
→ is_completed = true
→ DebugScene 立即进入房间完成流程
```

这有两个问题：

1. 休息房缺少玩家选择，不符合 STS 类房间交互。
2. ChoiceRequest 框架目前只被 card_reward 使用，还没有验证为通用选择请求。

本阶段通过 `rest_choice` 解决这两个问题。

## 目标

### 玩家目标

玩家在地图进入休息房后，可以看到：

```text
选择休息行动
[休息：恢复 30% 最大生命]
[跳过]
```

玩家可以操作：

```text
点击“休息”
或点击“跳过”
```

操作后：

```text
休息：玩家恢复 30% 最大生命，房间完成，地图下一层选择出现
跳过：玩家生命不变，房间完成，地图下一层选择出现
```

### 工程目标

复用现有 ChoiceRequest 框架：

```text
StmChoiceOption
StmChoiceRequest
StmGameState.current_choice_request
StmGameState.submit_choice(option_id)
BattleDebugScene ChoicePanel
```

新增一种 request_type：

```text
request_type = "rest_choice"
```

本阶段不新增第二套休息 UI，不新增独立 RestPanel。

## 非目标

本阶段明确不做：

```text
锻造 / Smith
选择升级哪张牌
卡牌升级系统
DreamCatcher 休息后给卡牌奖励
Coffee Dripper / Fusion Hammer 等遗物交互
Girya / Peace Pipe / Shovel 等特殊休息选项
Ruby Key / Recall
完整营火 UI 美术
正式营火场景
多选 ChoiceRequest
完整 Python InputRequest / Option actions 迁移
MessageBus
RuntimePresenter
AI driver
will / mind / 意愿牌 / 思维牌桌
修改 Python 参考项目
```

本阶段也不修改：

```text
project.godot
StmTypes.TerminalResult
StmCard.can_play(game_state) bool 语义
战斗奖励 card_reward 规则
Boss 胜利通关规则
```

## 核心设计原则

### 1. RestRoom 只创建选择请求，不直接结算休息

进入 RestRoom 时：

```text
RestRoom.enter(game_state)
→ super.enter(game_state)
→ 创建 rest_choice ChoiceRequest
→ game_state.set_choice_request(request)
→ 不恢复 HP
→ 不 is_completed = true
```

### 2. 休息结果由 GameState.submit_choice 规则层解析

UI 只能：

```text
显示 current_choice_request
点击按钮后调用 game_state.submit_choice(option_id)
刷新显示
```

UI 不应：

```text
直接修改 player.hp
直接 complete room
直接清空 choice request
维护第二套 rest state
```

### 3. 房间完成仍由规则层触发

`submit_choice()` 处理 rest_choice 成功后：

```text
clear_choice_request()
room.complete(game_state)
```

DebugScene 只根据 room.completed 刷新地图。

### 4. 内容简单，接口保持可扩展

本阶段只有两个 option：

```text
rest
skip
```

但 request_type / payload 设计不要写死成只有休息房自动回血，以便后续接：

```text
smith_choice
upgrade_card_choice
remove_card_choice
relic_rest_choice
```

## 数据结构设计

复用现有：

```text
StmChoiceOption
StmChoiceRequest
```

### rest_choice request

建议字段：

```text
id = "rest_choice"
title = "选择休息行动"
request_type = "rest_choice"
max_select = 1
must_select = false
context = { "room": self }
```

### rest option payload

```text
action = "rest"
heal_ratio = 0.3
```

或：

```text
action = "rest"
heal_amount = int(player.max_hp * 0.3)
```

本阶段建议在提交时根据当前 player.max_hp 计算，避免创建 request 后玩家 max_hp 变化导致 payload 过期。

### skip option payload

```text
action = "skip"
```

## GameState 集成设计

修改文件：

```text
scripts/stm/engine/game_state.gd
```

在 `submit_choice()` 中新增：

```text
request_type == "rest_choice" → _resolve_rest_choice(request, option)
```

新增私有方法：

```gdscript
func _resolve_rest_choice(request, option) -> Dictionary
func _heal_player_for_rest() -> Dictionary
```

成功返回 code：

```text
REST_TAKEN
REST_SKIPPED
```

失败仍复用：

```text
NO_CHOICE_REQUEST
OPTION_NOT_FOUND
OPTION_DISABLED
UNSUPPORTED_REQUEST_TYPE
INVALID_PAYLOAD
```

### rest_choice 解析规则

如果 `payload.action == "rest"`：

```text
校验 player 存在
before_hp = player.hp
heal_amount = int(player.max_hp * 0.3)
player.hp = min(player.max_hp, player.hp + heal_amount)
after_hp = player.hp
actual_heal = after_hp - before_hp
记录到 room.last_hp_before / last_hp_after / last_heal_amount
clear_choice_request()
room.complete(game_state)
return REST_TAKEN
```

如果 `payload.action == "skip"`：

```text
不修改 player.hp
如果 room 有 last_hp_before / last_hp_after / last_heal_amount，则记录：
    last_hp_before = player.hp
    last_hp_after = player.hp
    last_heal_amount = 0
clear_choice_request()
room.complete(game_state)
return REST_SKIPPED
```

如果 payload 非法：

```text
return INVALID_PAYLOAD
```

## RestRoom 接入设计

修改文件：

```text
scripts/stm/rooms/rest.gd
```

当前行为：

```text
enter(game_state)
→ 直接回血
→ is_completed = true
```

目标行为：

```text
enter(game_state)
→ 重置 last_hp_before / last_hp_after / last_heal_amount
→ 如果 game_state 或 player 缺失：is_completed = true，保持安全退化
→ 否则创建 rest_choice request
→ game_state.set_choice_request(request)
→ 不回血
→ 不完成房间
```

新增方法建议：

```gdscript
func _create_rest_choice_request(game_state)
func _rest_option(game_state)
func _skip_option()
```

选项显示：

```text
休息（恢复 21 点 HP）
跳过
```

其中 21 来自 `int(player.max_hp * 0.3)`，仅作为显示估计。

## DebugScene 接入设计

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

目标是尽量复用已有 ChoicePanel。

当前 DebugScene 进入休息房的逻辑可能会直接：

```text
room_type == "rest"
→ game_flow.complete_current_room()
→ _on_room_completed()
```

本阶段需要改为：

```text
room_type == "rest"
→ game_flow.enter_current_room()
→ RestRoom.enter() 创建 current_choice_request
→ 如果 game_state.has_choice_request():
    map_panel.visible = false 或保持房间内状态
    status_message = "选择休息行动"
    _refresh_display()
    return
```

点击 ChoicePanel 选项后，现有 `_on_choice_option_pressed()` 应该可以复用：

```text
submit_choice(option_id)
如果 result.ok 且 current room completed：_on_room_completed()
否则 _refresh_display()
```

### 休息阶段按钮关系

当有 `current_choice_request` 时，现有奖励阶段禁用逻辑已禁用：

```text
AutoPlayButton
EndTurnButton
HandCardButton
ApplyValuesButton
```

休息房没有 combat，因此这些按钮本来也应不可用。

## 验收标准

### 规则验收

1. `RestRoom.enter(game_state)` 在 player 存在时不立即完成房间。
2. `RestRoom.enter(game_state)` 创建 `current_choice_request`。
3. request 的 `request_type == "rest_choice"`。
4. request title 为“选择休息行动”或等价文案。
5. request 包含“休息”和“跳过”两个 option。
6. 提交“休息”后，玩家 HP 增加 `int(max_hp * 0.3)`，但不超过 max_hp。
7. 提交“休息”后，room completed，request 清空。
8. 提交“跳过”后，玩家 HP 不变，room completed，request 清空。
9. 无效 rest_choice payload 返回 `INVALID_PAYLOAD`。
10. unsupported request_type 仍按既有规则返回 `UNSUPPORTED_REQUEST_TYPE`。
11. `card_reward` 既有测试继续通过。

### 流程验收

1. 地图进入休息房后，不立即出现下一层。
2. 地图进入休息房后，出现 ChoicePanel。
3. 点击休息后，地图下一层出现。
4. 点击跳过后，地图下一层出现。
5. 休息房完成后可以继续前往下一层。
6. Boss 流程不受影响。

### UI 验收

1. 休息房选择阶段 ChoicePanel 显示。
2. ChoiceTitleLabel 显示“选择休息行动”。
3. ChoiceOptionsContainer 有“休息”和“跳过”按钮。
4. 点击“休息”后日志显示恢复 HP 文案。
5. 点击“跳过”后日志显示跳过休息文案。
6. UI 不直接修改 HP，不直接 complete room，只调用 `submit_choice()`。

### 回归验收

完整 GUT 必须继续通过当前全部测试，并新增 rest_choice 测试。

建议新增：

```text
scripts/stm/tests/test_rest_choice_v1.gd
scripts/stm/tests/test_battle_debug_rest_choice_v1.gd
```

并更新：

```text
.gutconfig.json
```

## 安全 / 边界 / 依赖自检

### 安全自检

检查项：

- 不修改 `project.godot`。
- 不新增插件。
- 不新增 autoload。
- 不引入网络、文件下载、第三方库。
- 不修改 Python 参考项目。
- 不恢复 will / mind / 意愿牌 / 思维牌桌 / 本能牌原型。
- 不新增完整 MessageBus / RuntimePresenter。
- 不修改 `StmTypes.TerminalResult`。
- 不修改 `StmCard.can_play(game_state)` bool 语义。
- 测试 deterministic，不依赖随机数、时间或人工点击。

结论：通过。v1 只复用现有 ChoiceRequest 框架，为 RestRoom 增加 rest_choice 请求和规则解析。

### 边界自检

本阶段只做：

```text
request_type = "rest_choice"
RestRoom.enter() 创建选择请求
GameState.submit_choice() 解析 rest / skip
DebugScene 复用 ChoicePanel 展示休息选择
休息/跳过后完成房间并回地图
BDD / TDD 测试
```

本阶段不做：

```text
Smith / 锻造
卡牌升级选择
遗物休息交互
正式营火 UI
特殊休息选项
完整事件系统
完整 InputRequest 迁移
```

结论：通过。功能边界聚焦于“ChoiceRequest 第二个用例”。

### 依赖自检

必须复用：

- `StmChoiceOption`
- `StmChoiceRequest`
- `StmGameState.current_choice_request`
- `StmGameState.submit_choice()`
- `StmRestRoom`
- `StmGameFlow.enter_current_room()` / `advance_to_next_floor()`
- `StmBattleDebugScene.ChoicePanel`
- 现有 GUT 测试体系

不得新增：

- 第二套 RestPanel
- 第二套 GameFlow
- 第二套 Room 完成系统
- 第二套选择状态机
- 第二套 UI 回调绕过 `submit_choice()`

结论：通过。

## 风险提示

1. 旧 `test_rooms.gd` 和 `test_game_flow.gd` 可能假设休息房进入后立即 completed；这些测试需要按新规格改为“选择后完成”。
2. DebugScene 当前对 rest room 有特殊逻辑，可能直接 `complete_current_room()`；本阶段必须移除该绕过逻辑。
3. 休息房没有 combat，但 UI 仍应能显示 ChoicePanel；不要依赖 combat 存在才刷新 ChoicePanel。
4. `last_hp_before / last_hp_after / last_heal_amount` 仍应保留，用于日志和测试。
5. 若玩家满血点击休息，actual_heal 应为 0，但仍应完成房间。
6. 如果 `game_state == null` 或 `player == null`，RestRoom 可以安全完成，避免空引用。

## 下一步

规格确认后，再写实施计划：

```text
docs/superpowers/plans/2026-05-30-sts2-rest-choice-v1.md
```

计划必须逐步写清：

```text
新增/修改哪些测试
修改哪个文件
新增哪些方法
每一步不允许改什么
对应完成标准
计划歧义自检
```

在计划确认前，不进入实现阶段。
