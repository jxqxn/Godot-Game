# STS2 Fixed Map Event Node v1 状态记录

## 对应规格与计划

```text
docs/superpowers/specs/2026-05-31-sts2-fixed-map-event-node-v1-design.md
docs/superpowers/plans/2026-05-31-sts2-fixed-map-event-node-v1.md
```

## 当前阶段结论

STS2 Fixed Map Event Node v1 已完成，并已通过完整 GUT。

本阶段只把已完成的 `debug_fountain` EventRoom 接入默认固定地图中的一个非关键分支，没有扩展事件系统本身。

## 完成内容

默认固定地图现在包含一个事件分支：

```text
第 4 层 rest
→ 第 5 层 node 0 combat
→ 第 5 层 node 1 event(debug_fountain)
→ 第 6 层 rest
→ 第 7 层 boss
```

已修改：

```text
scripts/stm/map/map_data.gd
scripts/stm/tests/test_fixed_map_node_branch_v1.gd
scripts/stm/tests/test_game_flow_node_branch_v1.gd
scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
scripts/stm/tests/test_map.gd
scripts/stm/tests/test_game_flow.gd
scripts/stm/tests/test_map_node_v1.gd
README.md
AGENTS.md
```

## 测试结果

2026-05-31 人工确认完整 GUT 通过：

```text
Scripts: 28
Tests: 200
Passing Tests: 200
Asserts: 986
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

## 规格审查结论

```text
只接入一个 event 节点：通过
只复用 debug_fountain：通过
不新增随机事件池：通过
不新增第二个事件：通过
不新增 EventFactory：通过
不新增商店 / 遗物 / 精英房：通过
不新增正式地图 UI：通过
不修改 Python 参考项目：通过
不新增平行 MapManager / GameFlow / ChoiceRequest：通过
```

## 代码质量审查结论

```text
MapData 只修改第 5 层 node 1：通过
第 5 层 node 0 combat 保持不变：通过
第 6 层 rest 与第 7 层 boss 保持不变：通过
GameFlow 默认路径通过 submit_choice("leave") 完成 event_choice：通过
BattleDebugScene 不解析 event payload：通过
BattleDebugScene 不直接修改 HP / room completion：通过
BattleDebugScene 进入事件房不记录“战斗开始”：通过
```

## 已知技术债

```text
1. 当前仍只有 debug_fountain 一个固定事件。
2. 尚未引入 EventFactory；本阶段仍不需要。
3. 尚未引入随机事件池、正式地图 UI、事件插画或复杂叙事分支。
4. GUT 退出时仍有 ObjectDB / resources still in use 警告，后续可单独清理。
```

## 下一步建议

建议从以下小步中选择一个：

```text
1. 新增 Smith / upgrade 选择，验证第二种非战斗选择类型。
2. 清理 GUT 退出时的 ObjectDB / resources still in use 警告。
3. 新增第二个固定事件，但仍不引入随机事件池或 EventFactory。
```

如果继续扩展事件系统，应先另写规格和计划，不要直接扩大本阶段范围。
