# STS2 Fixed Map Event Node v1 规格设计

## 背景

STS2 EventRoom v1 已完成并通过完整 GUT，但默认固定地图中尚未包含 `event` 节点。当前 EventRoom 主要通过 test-only 地图注入能力验证。

本阶段目标是把已经完成的 `debug_fountain` 事件房接入默认固定地图中的一个非关键分支，让事件房进入正常调试流程。

## 目标

将默认固定地图第 5 层 node 1 从 `rest` 改为 `event`：

```text
第 4 层 rest
→ 第 5 层 node 0 combat
→ 第 5 层 node 1 event(debug_fountain)
→ 第 6 层 rest
→ 第 7 层 boss
```

完成后，BattleDebugScene 正常默认流程应能：

```text
完成第 4 层 rest
→ 看到第 5 层 combat / event 两个分支
→ 选择 event 分支
→ 进入清泉事件房
→ 选择 drink 或 leave
→ 房间完成
→ 继续前往第 6 层 rest
```

## 非目标

本阶段明确不做：

```text
随机事件池
新增第二个事件
EventFactory
商店
遗物
精英房
正式地图 UI
复杂事件叙事系统
Python 运行时依赖
第二套 MapManager / GameFlow / ChoiceRequest
```

## Python 参考项目边界

Python 项目只作为架构和规格参考。

本阶段只参考以下方向：

```text
地图节点 room_type / payload 语义
地图路径 next_nodes 语义
Room / Event / Combat 边界
GameState 只保存状态的方向
```

不得直接迁移 Python 代码，也不得让 Godot 依赖 Python 运行时。

## MapData 规格

修改文件：

```text
scripts/stm/map/map_data.gd
```

更新注释：

```text
nodes[j]["type"]: "combat" | "rest" | "event" | "boss"
```

第 5 层 node 1 修改为：

```gdscript
{"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [{"floor_index": 5, "node_index": 0}]}
```

第 5 层 node 0 combat 保持不变。

第 6 层 rest 与第 7 层 boss 保持不变。

## 行为规格

### MapManager

第 4 层 rest 完成后可见两个第 5 层分支：

```text
node 0 = combat / 战斗房间
node 1 = event / 事件房间
```

第 5 层 event 分支完成后只能前往第 6 层 node 0 rest。

### GameFlow

选择第 5 层 node 1 后：

```text
enter_current_room() 创建 EventRoom
current_choice_request.request_type = event_choice
submit_choice("leave") 或 submit_choice("drink") 完成 EventRoom
advance_to_next_node(5, 0) 成功
```

不得通过 `complete_current_room()` 绕过 event_choice。

### BattleDebugScene

第 4 层 rest 完成后显示两个按钮：

```text
第 5 层 战斗房间
第 5 层 事件房间
```

点击事件房后：

```text
显示 清泉 choice 面板
日志显示 进入事件房
日志不得显示 战斗开始
```

事件选择后：

```text
choice 面板隐藏
地图面板出现
第 6 层 rest 可选
```

## 测试要求

更新既有测试：

```text
scripts/stm/tests/test_fixed_map_node_branch_v1.gd
scripts/stm/tests/test_game_flow_node_branch_v1.gd
scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
```

至少覆盖：

```text
1. 第 4 层后两个第 5 层节点分别是 combat / event。
2. 第 5 层 event 分支能汇合到第 6 层 rest。
3. GameFlow 走默认地图可以进入 event 房并通过 submit_choice 完成。
4. BattleDebugScene 默认地图路径可以点击事件房，显示清泉事件选择。
5. BattleDebugScene 不把事件房记录为战斗开始。
```

## 规格自检：边界

```text
只接入一个 event 节点：通过
只使用已有 debug_fountain：通过
不新增事件池：通过
不新增 EventFactory：通过
不新增正式地图 UI：通过
不修改 Python 项目：通过
不新增平行系统：通过
```

## 规格自检：安全

```text
不会新增文件读写、网络、外部进程或 Python 调用。
不会修改 project.godot。
不会修改 StmTypes.TerminalResult。
不会修改 StmCard.can_play(game_state) bool 语义。
BattleDebugScene 仍只提交 option_id，不直接修改 HP 或 room completion。
```

## 规格自检：依赖

允许依赖：

```text
StmMapData
StmMapManager
StmMapNode
StmRoomFactory
StmEventRoom
StmGameFlow
StmGameState.submit_choice()
StmChoiceResolver
BattleDebugScene
GUT
```

禁止依赖：

```text
Python 运行时
随机地图生成器
事件池
EventFactory
第二套 MapManager / GameFlow / ChoiceRequest
```

## 验收标准

```text
1. 完整 GUT 通过。
2. 默认固定地图第 5 层包含 combat / event 分支。
3. 默认流程可进入事件房。
4. 事件选择后可以推进到第 6 层 rest。
5. EventRoom v1 原有测试保持通过。
6. 不引入随机事件池、EventFactory 或正式地图 UI。
```

完整验证命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```
