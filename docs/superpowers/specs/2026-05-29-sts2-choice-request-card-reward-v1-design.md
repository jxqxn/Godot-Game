# STS2 通用选择请求框架与战斗胜利卡牌奖励 v1 设计

## 当前定位

本规格是 `STS2 自动出牌预览与不可打原因展示 v1.1` 之后的主干小步扩展。

v1.1 已经让战斗中的自动出牌变得可解释：

```text
战斗中显示将自动打出的牌
高优先级牌不可打时显示跳过原因
没有可自动打出的牌时显示明确原因
点击自动出牌后实际打出的牌与预览一致
```

下一步要补足 STS 类游戏的另一个核心闭环：

```text
战斗胜利
→ 出现成长奖励
→ 玩家做选择
→ 角色变强
→ 回到地图继续推进
```

本阶段采用“框架一步到位，内容保持简单”的策略：

```text
框架：建立可复用的最小 ChoiceRequest / ChoiceOption 边界
内容：只实现战斗胜利后的 card_reward 三选一
```

这里的“一步到位”只指选择请求边界一步到位，不指完整选择系统功能一步到位。

## Python 参考项目依据

Python 参考项目中，战斗房间胜利后不是直接离开房间，而是：

```text
CombatRoom.enter()
→ combat.start()
→ COMBAT_WIN
→ _handle_victory()
→ 生成奖励 actions
→ 玩家选择奖励
→ LeaveRoomAction
```

其中卡牌奖励不是专用 UI 逻辑，而是通过通用选择模型表达：

```text
Option：一个可选项，包含显示名和 actions
InputRequest：一次选择请求，包含标题、选项、最大选择数、是否必须选择等
InputRequestAction：把选择请求交给运行时 / UI
```

Godot 项目不应直接复制 Python 运行时，但应吸收其边界：

```text
规则层提出选择请求
UI 展示选择请求
玩家提交选择
规则层解析选择并推进流程
```

## 要解决的问题

当前 Godot 主干已经能完成：

```text
进入战斗
抽牌
出牌
自动出牌
自动出牌预览
敌人行动
战斗胜负
房间完成
回到地图
```

但当前战斗胜利后缺少成长反馈：

```text
玩家打赢后没有获得新牌
没有奖励选择
没有“变强”的反馈
```

如果直接写奖励专用 UI，会造成后续返工：

```text
奖励三选一写一套按钮逻辑
事件选择再写一套按钮逻辑
休息房间再写一套按钮逻辑
商店购买再写一套按钮逻辑
Boss 遗物再写一套按钮逻辑
```

因此本阶段应先建立最小通用选择请求框架，再用它承载第一种实际选择：战斗胜利卡牌奖励。

## 目标

### 玩家目标

玩家在战斗胜利后可以看到：

```text
战斗胜利
选择一张奖励卡牌
奖励卡 1
奖励卡 2
奖励卡 3
跳过奖励
```

玩家可以操作：

```text
点击一张奖励卡
或点击跳过奖励
```

操作后：

```text
选择卡牌：该卡加入玩家 deck
跳过奖励：deck 不变
奖励处理完成：当前房间完成，地图下一层选择出现
```

### 工程目标

建立最小可复用选择请求框架：

```text
StmChoiceOption
StmChoiceRequest
StmGameState.current_choice_request
StmGameState.submit_choice(option_id)
```

本阶段只接入一种请求类型：

```text
request_type = "card_reward"
```

后续可复用到：

```text
事件选项
休息房间：休息 / 锻造
Boss 遗物三选一
商店购买
地图节点选择
弃牌 / 升级 / 移除卡牌选择
```

但这些后续用途不在本阶段实现。

## 非目标

本阶段明确不做：

```text
完整 Python InputRequest / InputSubmission 框架
完整 Option actions 系统
完整 MessageBus
RuntimePresenter
AI 自动决策接口
多选
命令别名
菜单系统
存档菜单
本地化系统
复杂上下文对象
正式奖励 UI 美术
随机稀有度权重
金币奖励
药水奖励
遗物奖励
Boss 遗物
商店
事件系统
休息房间选择
卡牌升级 / 移除 / 变形选择
正式卡牌平衡
新行动队列
新战斗运行时
will / mind / 意愿牌 / 思维牌桌
修改 Python 参考项目
```

本阶段也不修改：

```text
StmCard.can_play(game_state) 的 bool 语义
StmTypes.TerminalResult
project.godot
```

## 核心设计原则

### 1. 选择请求是规则层状态

选择请求不应只是 UI 临时状态。

规则层应能表达：

```text
当前系统正在等待玩家做一个选择
这个选择有标题
这个选择有选项
每个选项有 id / label / detail / payload / enabled
选择提交后由规则层处理
```

### 2. UI 只展示和提交选择

UI 可以：

```text
读取 current_choice_request
显示 title / options / detail
把玩家点击转成 option_id
调用 game_state.submit_choice(option_id)
刷新显示
```

UI 不应：

```text
自己决定奖励是否完成
自己直接 complete room
自己绕过 submit_choice
自己维护第二套 reward state
自己直接操作地图推进
```

### 3. 选择解析由规则层完成

规则层负责：

```text
确认 current_choice_request 存在
确认 option_id 合法
确认 option.enabled
根据 request_type / context / payload 执行规则结果
清空 current_choice_request
推动房间完成或后续流程
```

### 4. 内容简单，接口稳定

本阶段奖励内容可以简单：

```text
固定三张测试奖励卡
或确定性奖励池前三张
```

但接口不要写死成奖励专用：

```text
ChoiceRequest / ChoiceOption 必须能表达未来 event_choice / rest_choice / shop_choice
```

## 数据结构设计

### StmChoiceOption

建议新增文件：

```text
scripts/stm/choices/choice_option.gd
```

建议类名：

```gdscript
class_name StmChoiceOption
extends RefCounted
```

字段：

```text
id: String
label: String
detail: String
payload: Dictionary
enabled: bool
```

建议构造：

```gdscript
func _init(
    p_id: String = "",
    p_label: String = "",
    p_detail: String = "",
    p_payload: Dictionary = {},
    p_enabled: bool = true
) -> void:
```

约束：

```text
id 在同一个 request 内必须唯一
label 是 UI 主显示文本
detail 是 UI 补充文本，可为空
payload 是规则层数据，不由 UI 解释
enabled 为 false 时 UI 可显示但不能提交
```

### StmChoiceRequest

建议新增文件：

```text
scripts/stm/choices/choice_request.gd
```

建议类名：

```gdscript
class_name StmChoiceRequest
extends RefCounted
```

字段：

```text
id: String
title: String
request_type: String
options: Array[StmChoiceOption]
max_select: int
must_select: bool
context: Dictionary
```

v1 约束：

```text
max_select 固定为 1
submit_choice 一次只接受一个 option_id
must_select 可以为 false，用于允许跳过
request_type 本阶段只正式支持 "card_reward"
```

建议方法：

```gdscript
func get_option(option_id: String)
func has_option(option_id: String) -> bool
func enabled_options() -> Array
```

## GameState 集成设计

修改文件：

```text
scripts/stm/engine/game_state.gd
```

新增字段：

```gdscript
var current_choice_request: StmChoiceRequest = null
```

新增方法：

```gdscript
func set_choice_request(request: StmChoiceRequest) -> void
func clear_choice_request() -> void
func has_choice_request() -> bool
func submit_choice(option_id: String) -> Dictionary
```

`submit_choice()` 返回 Dictionary，建议结构：

```text
ok: bool
code: String
message: String
request_type: String
selected_option_id: String
```

基础失败 code：

```text
NO_CHOICE_REQUEST
OPTION_NOT_FOUND
OPTION_DISABLED
UNSUPPORTED_REQUEST_TYPE
INVALID_PAYLOAD
```

成功 code：

```text
CHOICE_RESOLVED
CARD_REWARD_TAKEN
CARD_REWARD_SKIPPED
```

### submit_choice 基础流程

```text
如果 current_choice_request == null：返回 NO_CHOICE_REQUEST
读取 request = current_choice_request
通过 option_id 找 option
找不到：返回 OPTION_NOT_FOUND
option.enabled == false：返回 OPTION_DISABLED
match request.request_type:
    "card_reward": 调用 _resolve_card_reward_choice(request, option)
    _: 返回 UNSUPPORTED_REQUEST_TYPE
```

### card_reward 解析

`card_reward` option payload 建议：

```text
action: "take_card" 或 "skip"
card: StmCard 或 null
```

规则：

```text
如果 action == "skip"：
    clear_choice_request()
    完成当前房间
    返回 CARD_REWARD_SKIPPED

如果 action == "take_card"：
    校验 card != null
    将 card 加入 player.card_manager.deck
    clear_choice_request()
    完成当前房间
    返回 CARD_REWARD_TAKEN
```

房间完成由规则层触发，不能由 UI 直接 complete。

### 房间完成依赖

为了让 `submit_choice()` 能完成当前房间，v1 可以在 request.context 中保存：

```text
room: 当前 StmCombatRoom
```

或保存：

```text
complete_room_callable / room_id
```

本阶段建议使用最小直接方案：

```text
context.room = 当前 room 对象
```

`_resolve_card_reward_choice()` 中调用：

```text
room.complete(game_state)
```

风险提示：

```text
context.room 是对象引用，足够满足当前 Godot 主干。
如果未来需要存档/序列化选择请求，再另开规格把 context 规范化。
```

## 战斗房间接入设计

修改文件：

```text
scripts/stm/rooms/combat.gd
```

当前行为：

```text
handle_combat_result(COMBAT_WIN)
→ complete(game_state)
```

目标行为：

```text
handle_combat_result(COMBAT_WIN)
→ 创建 card_reward ChoiceRequest
→ game_state.set_choice_request(request)
→ 暂不 complete room
```

当玩家通过 `submit_choice()` 选择或跳过奖励后：

```text
_add selected card to deck 或 skip
→ clear_choice_request()
→ room.complete(game_state)
```

### 奖励生成 v1

本阶段奖励内容保持 deterministic。

建议奖励选项：

```text
打击
防御
痛击
```

或使用 fixture 中已有测试卡生成三张新实例。

约束：

```text
奖励卡必须是新实例，不能直接引用当前战斗手牌 / 抽牌堆 / 弃牌堆里的对象
选择后加入 deck
跳过不改 deck
```

### 重复胜利处理

如果 `handle_combat_result(COMBAT_WIN)` 被重复调用：

```text
如果房间已 completed：不重复创建奖励
如果 current_choice_request 已存在且 request_type == "card_reward"：不重复创建奖励
```

避免重复奖励。

## UI 行为设计

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

新增轻量 UI 区域：

```text
ChoicePanel
ChoiceTitleLabel
ChoiceOptionsContainer
```

位置建议：

```text
AutoPlayPreviewLabel 下方
Buttons 上方
```

显示规则：

```text
如果 game_state.current_choice_request == null：ChoicePanel 隐藏
如果存在 request：ChoicePanel 显示
显示 request.title
为每个 option 创建按钮
按钮文本使用 option.label
可选追加 option.detail
点击按钮 → game_state.submit_choice(option.id)
根据返回 message 更新 status_message / log
_refresh_display()
```

战斗奖励 UI 示例：

```text
选择一张奖励卡牌
[打击（1）]
[防御（1）]
[痛击（2）]
[跳过奖励]
```

### UI 与战斗按钮关系

当有 `current_choice_request` 时：

```text
AutoPlayButton disabled
EndTurnButton disabled
HandCardButton disabled
ApplyValuesButton 可暂时 disabled，避免奖励阶段改战斗数值
```

避免奖励阶段继续进行战斗操作。

### 地图显示关系

当战斗胜利但奖励未处理时：

```text
当前房间尚未 completed
地图下一层选择不出现
ChoicePanel 显示
```

奖励选择/跳过后：

```text
room.complete(game_state)
_on_room_completed 或等价刷新路径生效
地图下一层选择出现
```

UI 不直接导航地图。

## 验收标准

### 规则验收

1. 可以创建 `StmChoiceOption`，字段正确保存。
2. 可以创建 `StmChoiceRequest`，通过 id 找到 option。
3. `game_state.set_choice_request()` 后 `has_choice_request()` 为 true。
4. `game_state.clear_choice_request()` 后 `has_choice_request()` 为 false。
5. 没有 request 时 submit 返回 `NO_CHOICE_REQUEST`。
6. option id 不存在时 submit 返回 `OPTION_NOT_FOUND`。
7. disabled option 提交时返回 `OPTION_DISABLED`。
8. unsupported request_type 提交时返回 `UNSUPPORTED_REQUEST_TYPE`。
9. card_reward 选择卡牌后，deck 增加 1 张对应卡牌。
10. card_reward 跳过后，deck 数量不变。
11. card_reward 解析后 current_choice_request 被清空。
12. card_reward 解析后当前 combat room 被 completed。
13. 重复处理 COMBAT_WIN 不会生成重复奖励。

### 流程验收

1. 战斗胜利后不会立即显示下一层选择。
2. 战斗胜利后会出现 card_reward 选择请求。
3. 选择奖励卡后，地图下一层选择出现。
4. 跳过奖励后，地图下一层选择出现。
5. 选择奖励卡加入 deck 后，后续战斗重置牌堆时能进入 deck 流程。

### UI 验收

1. `ChoicePanel` 在无 request 时隐藏。
2. 战斗胜利奖励阶段 `ChoicePanel` 显示。
3. `ChoiceTitleLabel` 显示“选择一张奖励卡牌”或等价文案。
4. 三个奖励卡按钮显示卡名和费用。
5. 存在“跳过奖励”按钮。
6. 点击奖励卡后日志显示“获得 <卡名>”或等价文案。
7. 点击跳过后日志显示“跳过奖励”或等价文案。
8. 奖励阶段自动出牌、结束回合、手牌出牌不可用。
9. UI 不直接修改 deck，不直接 complete room；只调用 `submit_choice()`。

### 回归验收

完整 GUT 必须继续通过，包括：

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
test_autoplay_preview_v1_1.gd
test_battle_debug_autoplay_preview_v1_1.gd
```

本阶段应新增：

```text
test_choice_request_v1.gd
test_combat_card_reward_choice_v1.gd
test_battle_debug_choice_reward_v1.gd
```

具体测试文件可在实施计划中最终确定。

## 安全 / 边界 / 依赖自检

### 安全自检

检查项：

- 不修改 `project.godot`。
- 不新增插件。
- 不新增 autoload。
- 不引入网络、文件下载、第三方库。
- 不修改 Python 参考项目。
- 不恢复 `will/`、`mind/`、意愿牌、思维牌桌、本能牌原型。
- 不新增完整 MessageBus / RuntimePresenter。
- 不修改 `StmTypes.TerminalResult`。
- 不修改 `StmCard.can_play(game_state)` 的 bool 语义。
- 测试 deterministic，不依赖随机数、时间或人工点击。

结论：通过。v1 只新增 Godot 主干选择请求数据结构、GameState 当前选择状态、战斗胜利奖励接入、调试 UI 展示和 GUT 测试。

### 边界自检

本阶段只做：

```text
最小 ChoiceOption
最小 ChoiceRequest
GameState current_choice_request / submit_choice
card_reward request_type
战斗胜利后奖励三选一
选择卡牌加入 deck
跳过奖励
奖励处理后完成房间并回地图
调试 UI 展示选择请求
BDD / TDD 测试
```

本阶段不做：

```text
完整选择系统全部能力
多选
复杂 actions 列表
通用事件系统
休息房间选择
商店选择
Boss 遗物
金币 / 药水 / 遗物奖励
正式 UI 美术
拟物桌面 UI
MessageBus
RuntimeContext
InputRequest / InputSubmission 全量迁移
```

结论：通过。功能边界聚焦于“选择请求框架最小切面 + card_reward 第一个用例”。

### 依赖自检

必须复用：

- `StmGameState`
- `StmCombatRoom`
- `StmGameFlow.handle_combat_result()`
- `StmCombat.check_combat_end()`
- `StmCard`
- `StmCard.copy()` 或奖励生成中新建卡牌实例
- `StmCardManager.deck`
- `StmCardManager.add_to_pile()` 或等价现有加牌方法
- `StmBattleDebugScene`
- 现有 GUT 测试体系

不得新增：

- 第二套 GameFlow
- 第二套 Room 完成系统
- 第二套战斗胜利结算
- 第二套牌堆系统
- 第二套地图推进系统
- 第二套 UI 状态机绕过 `current_choice_request`

结论：通过。选择请求挂在 GameState，奖励完成仍回到现有 Room / GameFlow 主干。

## 风险提示

1. 不要把 ChoiceRequest 做成奖励专用类；否则后续事件/休息/商店会返工。
2. 不要把 ChoiceRequest 一次扩成完整 Python InputRequest；否则当前轮会变成大重构。
3. 不要让 UI 直接 `room.complete(game_state)`；房间完成必须由 `submit_choice()` 规则层完成。
4. 不要让奖励阶段继续允许自动出牌或结束回合。
5. 奖励卡必须是新实例，不能移动当前手牌里的对象。
6. 如果 `card_manager.add_to_pile("deck", card)` 的位置语义不清，实施计划里要先确认 deck 加牌方法，避免加到错误位置。
7. 如果 GUT 出现泄漏警告但测试通过，本轮仍不把资源清理作为功能阻塞项；需要时另开技术债。
8. context 中直接保存 room 对象是 v1 的最小方案，未来若要存档/序列化选择请求，再另开规格规范化 context。

## 下一步

规格确认后，再写实施计划：

```text
docs/superpowers/plans/2026-05-29-sts2-choice-request-card-reward-v1.md
```

计划文档必须逐步写清：

```text
修改哪个文件
新增哪个类 / 方法 / UI 节点 / 测试
每一步不允许改什么
对应测试是什么
完成标准是什么
每一步是否有歧义
```

在计划确认前，不进入代码实现。
