# STS2 EventRoom v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-30-sts2-event-room-v1-design.md
```

## 本轮目标

本轮只新增一个最小事件房，用来验证 Core Runtime Architecture Spine v1 的扩展能力。

目标链路：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom 发出 event_choice
→ ChoiceResolver 结算事件选择
→ EventRoom 完成
→ GameFlow 完成房间并允许地图推进
```

## 总原则

本轮必须严格保持小范围：

```text
只做一个固定事件 debug_fountain
只做两个固定选项 drink / leave
只验证 event_choice 选择结算
只复用现有 ChoiceRequest / ChoiceOption / GameState.submit_choice()
```

禁止：

```text
新增随机事件池
新增商店
新增遗物
新增精英房
新增正式地图 UI
新增复杂叙事系统
新增第二套 GameFlow / MapManager / ChoiceRequest / ActionQueue
修改 Python 参考项目
```

## 实施顺序总览

严格按 BDD / TDD：

```text
1. 新增 EventRoom BDD 测试
2. 新增 ChoiceResolver event_choice BDD 测试
3. 新增 EventRoom 最小实现
4. 扩展 RoomFactory 支持 event
5. 扩展 MapNode 显示 event 房间名
6. 扩展 ChoiceResolver 支持 event_choice
7. 处理 event 测试地图路径
8. 增加 GameFlow event 房间流程测试
9. 增加 BattleDebugScene event_choice 展示/提交测试
10. 更新 .gutconfig.json
11. 完整 GUT 验证
12. 规格审查与代码质量审查
```

每一步完成后优先运行相关测试，最后完整运行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

---

## 步骤 1：新增 EventRoom BDD 测试

新增文件：

```text
scripts/stm/tests/test_event_room_v1.gd
```

测试目标：

```text
1. EventRoom.get_room_type() 返回 event。
2. EventRoom.enter(game_state) 创建 event_choice。
3. event_choice 的 title/source/context/event_id 正确。
4. event_choice 包含 drink / leave 两个选项。
5. EventRoom 初始进入后未完成。
```

Given-When-Then 示例：

```gdscript
# Given 一个带有 debug_fountain payload 的 EventRoom
# When 进入房间
# Then GameState 会收到 event_choice，并且房间尚未完成
```

实现约束：

```text
只写测试，不写正式实现。
不修改 RoomFactory。
不修改 ChoiceResolver。
```

完成标准：

```text
测试能准确描述 EventRoom v1 行为，允许先失败。
```

### 步骤 1 歧义自检

```text
是否明确测试文件：是，test_event_room_v1.gd。
是否明确测试对象：是，EventRoom 进入房间后的 event_choice 创建行为。
是否允许写实现：否，只写测试。
是否允许直接完成房间：否，进入后应保持未完成。
是否有歧义：无。
```

---

## 步骤 2：新增 ChoiceResolver event_choice BDD 测试

新增文件：

```text
scripts/stm/tests/test_choice_resolver_event_choice_v1.gd
```

测试目标：

```text
1. 选择 drink 后：
   - 玩家 HP +5，不超过 max_hp
   - current_choice_request 被清空
   - EventRoom 被 complete
   - 返回 ok = true
   - 返回 code = EVENT_HEAL_TAKEN

2. 选择 leave 后：
   - 玩家 HP 不变
   - current_choice_request 被清空
   - EventRoom 被 complete
   - 返回 ok = true
   - 返回 code = EVENT_LEFT

3. invalid payload 返回：
   - ok = false
   - code = INVALID_PAYLOAD
   - current_choice_request 不被清空
   - EventRoom 不被 complete
```

实现约束：

```text
通过 GameState.submit_choice() 公共入口验证。
不要直接调用 ChoiceResolver 私有方法。
不要让 EventRoom 或测试直接修改完成状态来绕过 resolver。
```

完成标准：

```text
event_choice 的结算行为被测试锁住。
```

### 步骤 2 歧义自检

```text
是否明确测试文件：是，test_choice_resolver_event_choice_v1.gd。
是否明确公共入口：是，只通过 GameState.submit_choice()。
是否明确成功分支：是，drink / leave。
是否明确失败分支：是，invalid payload。
是否明确失败分支是否清空 choice：是，不清空。
是否允许直接调用 resolver 私有方法：否。
是否有歧义：无。
```

---

## 步骤 3：新增 EventRoom 最小实现

新增文件：

```text
scripts/stm/rooms/event_room.gd
```

建议结构：

```gdscript
class_name StmEventRoom
extends StmRoom

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")

var last_hp_before: int = 0
var last_hp_after: int = 0
var last_event_action: String = ""
```

`enter(game_state)`：

```text
1. super.enter(game_state)
2. 读取 room_payload.event_id，默认 debug_fountain
3. 创建 event_choice
4. game_state.set_choice_request(request)
```

固定事件：

```text
event_id = debug_fountain
title = 清泉
description = 你发现了一处安静的清泉。
```

选项：

```text
drink → payload {"action": "heal", "amount": 5}
leave → payload {"action": "leave"}
```

实现约束：

```text
EventRoom 不直接修改玩家 HP。
EventRoom 不直接完成自己。
EventRoom 不推进地图。
EventRoom 不调用 GameFlow。
```

对应测试：

```text
test_event_room_v1.gd
```

完成标准：

```text
EventRoom enter 行为测试通过。
```

### 步骤 3 歧义自检

```text
是否明确新增文件：是，scripts/stm/rooms/event_room.gd。
是否明确继承关系：是，extends StmRoom。
是否明确 event_id 默认值：是，debug_fountain。
是否明确选项 payload：是，heal amount=5 与 leave。
是否允许 EventRoom 修改 HP：否。
是否允许 EventRoom 自己 complete：否。
是否有歧义：无。
```

---

## 步骤 4：扩展 RoomFactory 支持 event

修改文件：

```text
scripts/stm/rooms/room_factory.gd
```

新增 preload：

```gdscript
const EventRoomScript := preload("res://scripts/stm/rooms/event_room.gd")
```

新增 match 分支：

```gdscript
"event":
    room = EventRoomScript.new()
```

实现约束：

```text
继续通过 _apply_room_payload 注入 payload。
unknown room_type 仍返回 null。
RoomFactory 不处理 room completion。
```

对应测试：

```text
test_room_factory_v1.gd
test_event_room_v1.gd
```

完成标准：

```text
RoomFactory 可以根据 event MapNode 创建 EventRoom。
```

### 步骤 4 歧义自检

```text
是否明确修改文件：是，room_factory.gd。
是否明确新增分支：是，room_type = event。
是否保留 payload 注入：是，继续使用 _apply_room_payload。
是否允许 RoomFactory 处理完成规则：否。
是否改变 unknown 行为：否，仍返回 null。
是否有歧义：无。
```

---

## 步骤 5：扩展 MapNode 显示 event 房间名

修改文件：

```text
scripts/stm/map/map_node.gd
```

`display_room_name()` 新增：

```gdscript
"event":
    return "事件房间"
```

实现约束：

```text
不改变 combat/rest/boss 的既有显示名。
unknown 仍返回原字符串。
```

对应测试：

```text
test_map_node_v1.gd
test_event_room_v1.gd
```

完成标准：

```text
event MapNode 能生成 room_name = 事件房间。
```

### 步骤 5 歧义自检

```text
是否明确修改文件：是，map_node.gd。
是否明确新增显示名：是，事件房间。
是否改变既有显示名：否。
是否改变 unknown 行为：否。
是否有歧义：无。
```

---

## 步骤 6：扩展 ChoiceResolver 支持 event_choice

修改文件：

```text
scripts/stm/choices/choice_resolver.gd
```

`resolve()` 新增分支：

```gdscript
"event_choice":
    return _resolve_event_choice(game_state, request, option)
```

新增方法：

```gdscript
func _resolve_event_choice(game_state, request, option) -> Dictionary
func _record_event_result(request, before_hp: int, after_hp: int, action: String) -> void
```

行为：

```text
action = heal:
  - 校验 game_state.player
  - before_hp = player.hp
  - heal_amount = payload.amount，默认 0
  - player.hp = min(player.max_hp, player.hp + heal_amount)
  - after_hp = player.hp
  - 记录 room.last_hp_before / last_hp_after / last_event_action
  - clear_choice_request
  - complete context room
  - 返回 EVENT_HEAL_TAKEN

action = leave:
  - HP 不变
  - 记录 room.last_hp_before / last_hp_after / last_event_action
  - clear_choice_request
  - complete context room
  - 返回 EVENT_LEFT

invalid payload/action:
  - 返回 INVALID_PAYLOAD
  - 不清空 current_choice_request
  - 不完成 context room
```

实现约束：

```text
复用现有 _complete_choice_context_room。
复用现有 _choice_result。
不要新增第二套选择结算系统。
不要让 EventRoom 自己结算 HP。
```

对应测试：

```text
test_choice_resolver_event_choice_v1.gd
test_choice_resolver_v1.gd
```

完成标准：

```text
event_choice 选择结算通过 GameState.submit_choice() 完成。
```

### 步骤 6 歧义自检

```text
是否明确修改文件：是，choice_resolver.gd。
是否明确新增 request_type：是，event_choice。
是否明确支持 action：是，heal / leave。
是否明确 invalid 行为：是，不清空 choice、不完成 room。
是否允许新增第二套选择系统：否。
是否允许 EventRoom 结算 HP：否。
是否有歧义：无。
```

---

## 步骤 7：处理 event 测试地图路径

本步骤目标是为步骤 8 的 GameFlow event 房间流程测试准备可达 event 节点。

优先级：

```text
方案 A：最小测试专用地图注入能力。
方案 B：不破坏旧测试的前提下，在默认固定地图中加入 event 节点并同步更新受影响测试。
方案 C：如果已有 debug/test-only 导航能力足够，则复用现有能力构造 event 节点路径。
```

硬性要求：

```text
必须为 GameFlow event 房间流程测试提供真实路径。
不能只测 RoomFactory + ChoiceResolver 就跳过 GameFlow 验收。
```

实现约束：

```text
不要破坏现有固定 7 层地图测试。
不要借机新增随机地图。
不要新增第二套 MapManager。
不要暴露正式玩法不需要的宽泛状态写入口。
```

完成标准：

```text
存在一个可用于 GameFlow 测试的 event 节点路径。
```

### 步骤 7 歧义自检

```text
是否明确本步骤目的：是，为 GameFlow event 测试准备路径。
是否必须修改默认 MapData：否，优先测试专用能力。
是否允许跳过 GameFlow 验收：否。
是否允许新增第二套 MapManager：否。
是否允许新增随机地图：否。
是否有歧义：无。实现时只需在 A/B/C 中选择最小安全方案。
```

---

## 步骤 8：增加 GameFlow event 房间流程测试

新增独立文件优先：

```text
scripts/stm/tests/test_game_flow_event_room_v1.gd
```

测试目标：

```text
1. GameFlow 通过 RoomFactory 进入 event 房间。
2. EventRoom.enter() 创建 event_choice。
3. 通过 GameState.submit_choice("drink") 或 submit_choice("leave") 完成事件。
4. event_choice 完成后，当前 room.is_completed = true。
5. room 完成后，GameFlow 可以 advance_to_next_node。
```

硬性要求：

```text
本步骤不可降级为只测 RoomFactory + ChoiceResolver。
必须存在 GameFlow 层面的 event 房间流程测试。
```

实现约束：

```text
不新增第二套 GameFlow。
不为了测试暴露正式玩法不需要的宽泛写入口。
不让测试直接 room.complete() 绕过 submit_choice。
```

完成标准：

```text
GameFlow 层面对 event 房间至少有一条完整最小验证路径。
```

### 步骤 8 歧义自检

```text
是否明确测试文件：是，优先 test_game_flow_event_room_v1.gd。
是否明确测试入口：是，GameFlow.enter_current_room() 与 GameState.submit_choice()。
是否明确推进验证：是，advance_to_next_node。
是否允许只测 RoomFactory + ChoiceResolver：否。
是否允许直接 room.complete()：否。
是否有歧义：无。
```

---

## 步骤 9：增加 BattleDebugScene event_choice 展示/提交测试

新增文件优先：

```text
scripts/stm/tests/test_battle_debug_event_choice_v1.gd
```

测试目标：

```text
1. BattleDebugScene 能显示 event_choice 当前标题和选项。
2. BattleDebugScene 提交 drink/leave 时调用 GameState.submit_choice()。
3. BattleDebugScene 不直接修改玩家 HP。
4. BattleDebugScene 不直接调用 room.complete()。
```

实现约束：

```text
如果现有 BattleDebugScene 的 choice UI 已通用支持 request/options，则优先复用旧入口。
不要新增事件专用 UI 运行时。
不要把 event_choice payload 解析写进 BattleDebugScene。
```

完成标准：

```text
事件选择在调试场景中走通，但规则仍在 ChoiceResolver。
```

### 步骤 9 歧义自检

```text
是否明确测试文件：是，test_battle_debug_event_choice_v1.gd。
是否明确 UI 职责：是，只显示和提交。
是否允许 UI 解析 payload：否。
是否允许 UI 修改 HP 或 complete room：否。
是否有歧义：无。
```

---

## 步骤 10：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

加入新增测试文件：

```text
res://scripts/stm/tests/test_event_room_v1.gd
res://scripts/stm/tests/test_choice_resolver_event_choice_v1.gd
res://scripts/stm/tests/test_game_flow_event_room_v1.gd
res://scripts/stm/tests/test_battle_debug_event_choice_v1.gd
```

实现约束：

```text
不移除任何旧测试。
不跳过失败测试。
不加入 .uid 文件。
```

完成标准：

```text
完整 GUT 会运行 EventRoom v1 相关测试。
```

### 步骤 10 歧义自检

```text
是否明确修改文件：是，.gutconfig.json。
是否明确新增测试路径：是，四个 EventRoom v1 相关测试。
是否允许移除旧测试：否。
是否允许跳过失败测试：否。
是否有歧义：无。
```

---

## 步骤 11：完整验证

执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

通过标准：

```text
所有 EventRoom v1 新测试通过
所有旧测试通过
无失败 Scripts / Tests / Asserts
BattleDebugScene 手测可提交 event_choice
```

失败处理：

```text
只看第一条失败
定位根因
只修根因
不借机扩大功能
不借机新增玩法
```

### 步骤 11 歧义自检

```text
是否明确验证命令：是，godot -s addons/gut/gut_cmdln.gd。
是否明确通过标准：是，新旧测试全部通过。
是否允许忽略失败：否。
是否允许借失败扩大范围：否。
是否有歧义：无。
```

---

## 步骤 12：规格审查与代码质量审查

### 规格审查

检查：

```text
是否只新增 debug_fountain 一个固定事件
是否只新增 drink / leave 两个选项
是否没有随机事件池
是否没有商店 / 遗物 / 精英房
是否没有正式地图 UI
是否没有修改 Python 参考项目
是否有 GameFlow event 房间流程测试
```

### 代码质量审查

检查：

```text
EventRoom 是否只负责创建 event_choice
ChoiceResolver 是否负责 event_choice 结算
GameState 是否仍只提供 submit_choice 公共入口
RoomFactory 是否只负责创建房间
GameFlow 是否没有事件专用结算分支
BattleDebugScene 是否没有直接修改事件规则状态
是否没有新增平行 ChoiceRequest / GameFlow / MapManager / ActionQueue
```

如发现必须修复项，必须先修复，再进入最终验证。

### 步骤 12 歧义自检

```text
是否明确审查类型：是，规格审查 + 代码质量审查。
是否明确 GameFlow 测试是审查项：是。
是否明确发现问题后的处理：是，必须先修复再最终验证。
是否有歧义：无。
```

## 全局歧义自检

### EventRoom 是否应该直接回血？

结论：不应该。

回血属于事件选择结算规则，应由 ChoiceResolver 处理。EventRoom 只负责发起选择。

### 是否应该修改默认地图加入 event？

结论：不强制。

但必须存在 GameFlow event 房间流程测试路径。如果不改默认地图，就必须提供最小测试专用路径能力。

### 是否可以跳过 GameFlow event 测试？

结论：不可以。

GameFlow event 测试是规格硬性验收。

### 是否要参考 Python 项目实现完整事件系统？

结论：不需要，也不允许。

Python 参考项目只提供架构方向，不迁移完整框架。

### 是否要新增 EventFactory？

结论：本阶段不需要。

只有一个固定事件时，直接在 EventRoom 内构造 ChoiceRequest 即可。未来如果事件数量增加，再单独规格化 EventFactory。

## 风险与控制

### 风险 1：EventRoom 变成复杂事件系统入口

控制：

```text
只允许 debug_fountain
只允许 drink / leave
不做随机池
不做事件 DSL
```

### 风险 2：规则被写进 UI

控制：

```text
BattleDebugScene 只能显示与提交选择
HP 修改只能在 ChoiceResolver 中发生
```

### 风险 3：为了测试新增过宽 debug 入口

控制：

```text
优先构造最小 event 测试路径能力
GameFlow 测试只做最小验证
不暴露正式运行时不需要的宽泛状态写入口
```

### 风险 4：破坏既有固定地图测试

控制：

```text
默认不改 MapData
如必须改，先补测试并逐项确认旧行为变化
```

## 等待执行确认

计划完成后，下一步应等待确认。

确认后进入实现阶段，严格按：

```text
先写 BDD 测试
再做最小 TDD 实现
再审查
再验证
```
