# STS2 EventRoom v1 状态记录

## 对应规格与计划

```text
docs/superpowers/specs/2026-05-30-sts2-event-room-v1-design.md
docs/superpowers/plans/2026-05-30-sts2-event-room-v1.md
```

## 当前阶段结论

STS2 EventRoom v1 已完成，并已通过完整 GUT。

本阶段没有引入正式事件系统、随机事件池、商店、遗物、精英房或正式地图 UI；目标是验证现有 Core Runtime Architecture Spine v1 是否能承接一个新房间类型和一个新选择类型。

## 完成内容

已完成以下主干链路：

```text
MapNode room_type = event
→ RoomFactory 创建 EventRoom
→ EventRoom.enter() 发出 event_choice
→ GameState.submit_choice(option_id)
→ ChoiceResolver 结算 event_choice
→ EventRoom 完成
→ GameFlow 推进到下一个节点
```

已新增或扩展：

```text
scripts/stm/rooms/event_room.gd
scripts/stm/rooms/room_factory.gd
scripts/stm/map/map_node.gd
scripts/stm/map/map_manager.gd
scripts/stm/engine/game_flow.gd
scripts/stm/choices/choice_resolver.gd
scripts/stm/debug/battle_debug_scene.gd
.gutconfig.json
```

核心行为：

```text
1. 新增 StmEventRoom。
2. 新增 room_type = event。
3. 新增 event_choice 选择类型。
4. 新增固定事件 debug_fountain。
5. 新增 drink 选项：恢复 5 点 HP，不超过 max_hp。
6. 新增 leave 选项：HP 不变，完成事件房。
7. ChoiceResolver 负责 event_choice 结算。
8. EventRoom 只负责创建 ChoiceRequest，不直接修改 HP / Deck / MapManager / GameFlow。
9. BattleDebugScene 可显示并提交 event_choice，且不会把事件房记录为“战斗开始”。
10. GameFlow 通过 test-only 地图注入能力完成 event 房流程测试。
```

## 测试结果

2026-05-31 人工确认完整 GUT 通过：

```text
Scripts: 28
Tests: 199
Passing Tests: 199
Asserts: 962
```

完整测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

GUT 退出时仍可能出现：

```text
ObjectDB instances leaked at exit
resources still in use at exit
```

当前功能验收以 `All tests passed` 和退出码 0 为准。

## 新增测试覆盖

新增并纳入 `.gutconfig.json`：

```text
scripts/stm/tests/test_event_room_v1.gd
scripts/stm/tests/test_choice_resolver_event_choice_v1.gd
scripts/stm/tests/test_game_flow_event_room_v1.gd
scripts/stm/tests/test_battle_debug_event_choice_v1.gd
```

补强测试：

```text
scripts/stm/tests/test_room_factory_v1.gd
scripts/stm/tests/test_map_node_v1.gd
scripts/stm/tests/test_choice_request_v1.gd
scripts/stm/tests/test_choice_resolver_v1.gd
```

## 规格审查结论

```text
只新增 debug_fountain 一个固定事件：通过
只新增 drink / leave 两个选项：通过
不引入随机事件池：通过
不引入商店 / 遗物 / 精英房：通过
不引入正式地图 UI：通过
不修改 Python 参考项目：通过
GameFlow event 房流程测试：通过
BattleDebugScene 只通过 submit_choice 提交事件选择：通过
```

## 代码质量审查结论

```text
EventRoom 只创建 event_choice：通过
ChoiceResolver 负责 event_choice 结算：通过
GameState 只保留 submit_choice 公共入口：通过
RoomFactory 只负责创建 event 房间：通过
GameFlow 没有事件专用结算分支：通过
BattleDebugScene 没有直接修改 HP / room completion：通过
未新增平行 ChoiceRequest / GameFlow / MapManager / ActionQueue：通过
```

## 已知技术债

```text
1. event 节点尚未接入默认固定地图。
2. 当前只有 debug_fountain 一个固定事件。
3. 尚未引入 EventFactory；本阶段因只有一个事件，不需要。
4. 尚未引入随机事件池、正式地图 UI、事件插画或复杂叙事分支。
5. GUT 退出时仍有 ObjectDB / resources still in use 警告，后续可单独清理。
```

## 下一步建议

建议从以下小步中选择一个：

```text
1. 将 event 节点接入默认固定地图中的一个非关键分支，并同步更新受影响测试。
2. 新增 Smith / upgrade 选择，验证第二种非战斗选择类型。
3. 清理 GUT 退出时的 ObjectDB / resources still in use 警告。
```

如果继续扩展事件系统，应先另写规格和计划，不要直接扩大 EventRoom v1：

```text
不要直接新增随机事件池
不要直接新增 EventFactory
不要直接接入商店 / 遗物 / 精英房
不要把事件规则写进 BattleDebugScene
```
