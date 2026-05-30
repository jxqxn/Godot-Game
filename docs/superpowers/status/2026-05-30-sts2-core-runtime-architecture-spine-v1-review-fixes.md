# STS2 Core Runtime Architecture Spine v1 审查修正记录

## 背景

本记录对应一次规格审查与代码质量审查后的最小修正。

审查结论：Core Runtime Architecture Spine v1 主体通过，但发现两个需要收敛的点：

```text
1. MapData 未显式声明 encounter_id，CombatRoom / BossRoom 依赖默认值。
2. BattleDebugScene 的调试数值编辑属于调试状态写入，需要明确 debug-only 边界。
```

## 已完成修正

### 1. MapData 显式声明 encounter payload

已在固定地图节点中加入：

```gdscript
{"room_payload": {"encounter_id": "debug_dummy"}}
{"room_payload": {"encounter_id": "boss_dummy"}}
```

这样地图节点到 RoomFactory，再到 CombatRoom / BossRoom / EncounterFactory 的链路不再只依赖默认值。

### 2. MapNode.from_dict 去掉自加载

`StmMapNode.from_dict()` 改为直接构造 `StmMapNode.new(...)`，避免在自身脚本中 `load()` 自身。

### 3. GameState 增加 debug-only 状态写入入口

新增：

```gdscript
func debug_apply_combat_values(values: Dictionary, enemy = null) -> Dictionary
func debug_clear_current_combat() -> void
```

这两个入口只供 BattleDebugScene / 测试工具使用，不作为正式战斗规则入口。

正式玩法仍应通过：

```text
GameFlow
GameState.submit_choice()
Combat.play_card()
Combat.end_turn()
Room.complete()
ChoiceResolver
```

## 已补测试

已增强：

```text
scripts/stm/tests/test_map_node_v1.gd
scripts/stm/tests/test_room_factory_v1.gd
```

新增覆盖：

```text
MapManager 当前节点暴露显式 room_payload
GameFlow 从 MapData 当前节点进入房间时，Room 能收到 encounter_id payload
Boss 节点 payload 能传到 BossRoom
```

## 仍需本地验证

本次修改未在当前环境实际运行 Godot / GUT。合并前应执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

重点观察：

```text
test_map_node_v1.gd
test_room_factory_v1.gd
test_encounter_factory_v1.gd
test_battle_debug_scene.gd
```

## 后续建议

下一次触碰 `BattleDebugScene` 时，应把当前数值编辑器的直接写入迁移为调用：

```gdscript
game_state.debug_apply_combat_values(values, enemy)
game_state.debug_clear_current_combat()
```

不要继续新增 `BattleDebugScene` 直接修改 HP / Deck / MapManager / Room 规则状态的代码。
