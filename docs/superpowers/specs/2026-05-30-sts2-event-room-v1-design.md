# STS2 EventRoom v1 规格设计

## 背景

Core Runtime Architecture Spine v1 已完成，当前主干边界已经包含：

```text
StmMapNode
StmRoomFactory
StmChoiceResolver
StmGameFlow
```

EventRoom v1 的目标不是扩展复杂事件系统，而是用一个极小的新房间类型验证当前架构是否能自然承接新内容。

## 目标

新增一个最小事件房流程：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom.enter() 发出 event_choice
→ 玩家选择事件选项
→ ChoiceResolver 结算 event_choice
→ EventRoom 完成
→ GameFlow 允许继续推进地图节点
```

## 非目标

本阶段明确不做：

```text
随机事件池
事件权重
事件稀有度
复杂叙事分支
商店
遗物
精英房
正式地图 UI
正式事件插画
事件脚本 DSL
第二套 ChoiceRequest
第二套 GameFlow
第二套 MapManager
第二套事件运行时
```

## Python 参考项目使用边界

Python 项目只作为架构和规格参考，不作为 Godot 运行时的一部分。

本阶段可参考：

```text
Room / Event / Combat 边界
InputRequest / ChoiceRequest 思路
GameState 只保存状态的方向
地图节点 room_type / payload 语义
```

本阶段不得：

```text
直接迁移完整 Python 框架
让 Godot 依赖 Python 运行时
把 Python 事件系统原样复制到 Godot
新增平行 Action / InputRequest 框架
```

## 新增房间类型

新增：

```text
room_type = event
```

`StmMapNode.display_room_name()` 对 event 应返回：

```text
事件房间
```

`StmRoomFactory.create_room(map_node)` 遇到 event 时应创建：

```text
StmEventRoom
```

## EventRoom v1

新增文件：

```text
scripts/stm/rooms/event_room.gd
```

新增 class：

```gdscript
class_name StmEventRoom
extends StmRoom
```

### 职责

EventRoom 只负责：

```text
1. 进入房间时创建 event_choice。
2. 把事件 id、标题、选项 payload 放入 ChoiceRequest。
3. 被 ChoiceResolver 完成后标记房间完成。
```

EventRoom 不负责：

```text
直接修改玩家 HP
直接修改 Deck
直接推进地图
直接调用 GameFlow
直接处理事件选项结算规则
```

## 固定事件

EventRoom v1 只支持一个固定事件：

```text
event_id = debug_fountain
```

显示标题：

```text
清泉
```

## 事件选项

`debug_fountain` 提供两个选项。

### 选项 1：drink

```text
id = drink
label = 饮用泉水（恢复 5 点 HP）
payload.action = heal
payload.amount = 5
```

行为：

```text
玩家 HP 恢复 5 点，不超过 max_hp
EventRoom 记录 last_hp_before
EventRoom 记录 last_hp_after
EventRoom 记录 last_event_action = heal
EventRoom 完成
current_choice_request 清空
返回 ok = true
返回 code = EVENT_HEAL_TAKEN
```

### 选项 2：leave

```text
id = leave
label = 离开
payload.action = leave
```

行为：

```text
玩家 HP 不变
EventRoom 记录 last_hp_before
EventRoom 记录 last_hp_after
EventRoom 记录 last_event_action = leave
EventRoom 完成
current_choice_request 清空
返回 ok = true
返回 code = EVENT_LEFT
```

## ChoiceRequest 规格

EventRoom.enter(game_state) 应设置：

```text
request_type = event_choice
title = 清泉
max_select = 1
must_select = false
context.room = self
context.event_id = debug_fountain
```

说明：当前 `StmChoiceRequest` API 使用 `max_select / must_select` 字段，不使用 `min_select / can_cancel` 命名。

## ChoiceResolver 规格

`StmChoiceResolver.resolve()` 新增支持：

```text
event_choice
```

支持 payload action：

```text
heal
leave
```

未知 action 返回：

```text
ok = false
code = INVALID_PAYLOAD
```

未知 request_type 仍保持现有行为：

```text
ok = false
code = UNSUPPORTED_REQUEST_TYPE
```

## MapData 规格

EventRoom v1 不强制修改默认 `StmMapData.FLOORS`。

为满足 GameFlow 层验收，本阶段使用最小 test-only 地图注入能力构造 event 节点路径：

```gdscript
[
    {
        "name": "测试第 1 层",
        "nodes": [
            {"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [{"floor_index": 1, "node_index": 0}]}
        ]
    },
    {
        "name": "测试第 2 层",
        "nodes": [
            {"type": "rest", "room_payload": {}, "next_nodes": []}
        ]
    }
]
```

该 test-only 能力不得变成正式玩法入口。

## BattleDebugScene 规格

BattleDebugScene 只允许：

```text
显示当前 event_choice
提交玩家选择到 GameState.submit_choice(option_id)
刷新状态
```

BattleDebugScene 不得：

```text
直接修改玩家 HP
直接调用 room.complete()
直接修改 MapManager
直接解析 event_choice payload
把事件房记录为战斗开始
```

## 测试要求

必须新增 BDD 测试，至少覆盖：

```text
1. RoomFactory 可以根据 event MapNode 创建 EventRoom。
2. EventRoom.enter() 会创建 event_choice。
3. 选择 drink 后恢复 HP，清空 choice，完成房间。
4. 选择 leave 后 HP 不变，清空 choice，完成房间。
5. GameFlow 可以进入 event 房并在完成后推进到下一个节点。
6. BattleDebugScene 不直接处理事件规则，只通过 submit_choice。
7. BattleDebugScene 进入事件房时记录“进入事件房”，不得记录“战斗开始”。
```

## 规格自检：边界

### 功能边界

```text
范围内：
1. 一个固定事件 debug_fountain。
2. 两个固定选项 drink / leave。
3. 一个新房间类型 event。
4. 一个新选择类型 event_choice。
5. 通过 ChoiceResolver 结算 HP 恢复或离开。
6. 通过 GameFlow 验证 event 房间完成后可继续推进。

范围外：
1. 随机事件池。
2. 多事件注册表。
3. EventFactory。
4. 商店、遗物、精英房。
5. 正式地图 UI。
6. 复杂事件脚本系统。
7. Python 运行时依赖。
```

结论：边界清晰，EventRoom v1 是架构验证阶段，不是正式事件系统阶段。

### 架构边界

```text
EventRoom：只创建 event_choice，不结算规则。
ChoiceResolver：结算 event_choice，并负责 HP 变化与完成 context.room。
GameState：保留 submit_choice 公共入口，不写 event_choice 私有规则分支。
RoomFactory：只根据 room_type 创建 EventRoom，不处理完成逻辑。
MapNode：只表达 room_type / payload / next_nodes，不创建房间。
GameFlow：只进入房间、完成房间、推进节点，不写事件专用结算分支。
BattleDebugScene：只显示与提交选择，不解析 payload，不直接改 HP。
```

结论：没有新增平行系统，必须复用现有主干。

## 规格自检：安全

### 状态安全

```text
1. heal 只能修改 player.hp。
2. heal 后 player.hp 不得超过 player.max_hp。
3. leave 不得修改 HP、Deck、MapManager 或 Combat。
4. invalid payload 不得清空 current_choice_request，不得完成房间。
5. EventRoom 不得直接修改玩家状态。
6. BattleDebugScene 不得直接修改玩家 HP 或 room completion。
```

结论：玩家状态修改被限制在 ChoiceResolver 的 event_choice 分支内。

### 运行时安全

```text
1. 不新增文件读写。
2. 不新增网络访问。
3. 不新增外部进程调用。
4. 不新增 Python 运行时调用。
5. 不新增 autoload。
6. 不修改 project.godot。
7. 不修改 StmTypes.TerminalResult。
8. 不修改 StmCard.can_play(game_state) bool 语义。
```

结论：本功能只在 Godot 现有运行时内扩展，不引入外部执行风险。

### UI 安全

```text
1. UI 只提交 option_id。
2. UI 不解析 event_choice payload。
3. UI 不直接调用 room.complete()。
4. UI 不直接改 MapManager。
5. UI 不新增事件专用规则分支。
```

结论：避免把正式规则写进 BattleDebugScene。

## 规格自检：依赖

### 允许依赖

```text
StmRoom
StmRoomFactory
StmMapNode
StmGameFlow
StmGameState.submit_choice()
StmChoiceResolver
StmChoiceRequest
StmChoiceOption
BattleDebugScene 现有 choice 显示/提交能力
GUT 测试框架
```

### 禁止依赖

```text
Python 参考项目运行时
第二套 ChoiceRequest / InputRequest
第二套 GameFlow
第二套 MapManager
第二套 ActionQueue
第二套 DebugScene 运行时
随机事件生成器
事件 DSL
商店 / 遗物 / 精英房系统
```

### 依赖缺口处理

```text
1. GameFlow event 节点路径通过最小 test-only 地图注入能力解决。
2. test-only 地图注入不得变成正式玩法入口。
3. GameFlow 层验收不得降级。
```

结论：依赖可控，GameFlow event 流程测试是硬性验收，且已通过 GUT。

## 验收标准

```text
1. 新增 EventRoom v1 相关测试通过。
2. 既有测试保持通过。
3. 完整 GUT 通过。
4. 不修改 Python 参考项目。
5. 不引入随机事件池、商店、遗物、正式地图 UI。
6. 不新增任何平行运行时系统。
7. 必须有 GameFlow 层面的 event 房间流程测试。
8. BattleDebugScene 必须只通过 GameState.submit_choice() 提交事件选择。
```

2026-05-30 人工确认完整 GUT 通过：

```text
Scripts: 28
Tests: 199
Passing Tests: 199
Asserts: 962
```

完整验证命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```
