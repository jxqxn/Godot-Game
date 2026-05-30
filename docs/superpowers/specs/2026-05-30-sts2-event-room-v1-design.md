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
2. 把事件 id、标题、描述、选项 payload 放入 ChoiceRequest。
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

描述：

```text
你发现了一处安静的清泉。
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
source = event_room
min_select = 1
can_cancel = false
context.room = self
context.event_id = debug_fountain
```

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

可以在固定测试地图中加入一个 event 节点，但必须保持整体流程极小。

建议最小改法：

```text
第 2 层或第 3 层替换为 event 节点
```

示例：

```gdscript
{"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [...]}
```

如果替换现有 combat 节点会破坏大量旧测试，则本阶段允许只在测试中构造 event MapNode，不立即改默认主线地图。

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
```

## 验收标准

```text
1. 新增 EventRoom v1 相关测试通过。
2. 既有 187 个测试保持通过。
3. 完整 GUT 通过。
4. 不修改 Python 参考项目。
5. 不引入随机事件池、商店、遗物、正式地图 UI。
6. 不新增任何平行运行时系统。
```

完整验证命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```
