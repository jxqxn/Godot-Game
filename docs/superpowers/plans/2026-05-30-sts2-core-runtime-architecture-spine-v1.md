# STS2 Core Runtime Architecture Spine v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-30-sts2-core-runtime-architecture-spine-v1-design.md
```

本计划只做架构定型，不新增玩家可见玩法。

本轮目标：

```text
ChoiceResolver
MapNode
RoomFactory
EncounterFactory
```

把当前已经验证通过的选择、地图、房间、战斗遭遇创建逻辑迁移到稳定边界上。

## 总原则

本轮是“行为不变的架构迁移”。

必须保持：

```text
card_reward 外部行为不变
rest_choice 外部行为不变
固定地图节点分支不变
BattleDebugScene 操作不变
Boss 胜利通关不变
完整 GUT 通过
```

禁止：

```text
新增事件房
新增 Smith / 升级牌
新增商店 / 遗物
新增随机地图生成
新增正式地图 UI
改 project.godot
改 TerminalResult
改 StmCard.can_play(game_state) bool 语义
修改 Python 参考项目
恢复 will / mind / 意愿牌 / 思维牌桌
```

## 实施顺序总览

严格按 TDD：

```text
1. ChoiceResolver 测试
2. ChoiceResolver 实现并迁移 GameState 选择解析
3. MapNode 测试
4. MapNode 实现并让 MapManager 内部适配
5. RoomFactory 测试
6. RoomFactory 实现并让 GameFlow 通过 factory 创建 room
7. EncounterFactory 测试
8. EncounterFactory 实现并让 CombatRoom/BossRoom 通过 payload 获取 encounter
9. 更新旧测试与 GUT 配置
10. 完整规格审查、代码质量审查、验证
```

每一步完成后优先运行相关测试，最后完整运行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

---

## 步骤 1：新增 ChoiceResolver BDD 测试

新增文件：

```text
scripts/stm/tests/test_choice_resolver_v1.gd
```

测试目标：

1. `GameState.submit_choice()` 处理 `card_reward` 的外部行为不变。
2. 选择 `take_card` 后：

```text
玩家 deck 增加对应卡牌
current_choice_request 被清空
context.room 被 complete
返回 ok = true
返回 code = CARD_REWARD_TAKEN
```

3. 选择 `skip_reward` 后：

```text
不加卡
current_choice_request 被清空
context.room 被 complete
返回 code = CARD_REWARD_SKIPPED
```

4. `GameState.submit_choice()` 处理 `rest_choice` 的外部行为不变。
5. 选择 `rest` 后：

```text
恢复 30% max_hp，不超过上限
记录 room.last_hp_before / last_hp_after / last_heal_amount
current_choice_request 被清空
context.room 被 complete
返回 code = REST_TAKEN
```

6. 选择 `skip` 后：

```text
HP 不变
current_choice_request 被清空
context.room 被 complete
返回 code = REST_SKIPPED
```

7. Unsupported request_type 返回：

```text
ok = false
code = UNSUPPORTED_REQUEST_TYPE
```

实现约束：

- 只写测试，不改实现。
- 测试仍通过 `GameState.submit_choice()` 公共入口验证行为。
- 不直接调用未来 resolver 私有方法。

完成标准：

- 测试准确锁住行为不变。

---

## 步骤 2：新增 ChoiceResolver 并迁移 GameState

新增文件：

```text
scripts/stm/choices/choice_resolver.gd
```

新增 class：

```gdscript
class_name StmChoiceResolver
extends RefCounted
```

新增方法：

```gdscript
func resolve(game_state, request, option) -> Dictionary
```

迁移逻辑：

从 `scripts/stm/engine/game_state.gd` 迁出：

```text
_resolve_card_reward_choice
_resolve_rest_choice
_record_rest_result
_complete_choice_context_room
_choice_card_display_name
_choice_result
```

GameState 保留：

```gdscript
func submit_choice(option_id: String) -> Dictionary
```

但 `submit_choice()` 只负责：

```text
检查 current_choice_request 是否存在
检查 request.get_option 是否存在
检查 option 是否存在
检查 option.enabled
调用 ChoiceResolver.resolve(self, request, option)
```

建议实现方式：

```gdscript
const ChoiceResolverScript := preload("res://scripts/stm/choices/choice_resolver.gd")
var _choice_resolver = ChoiceResolverScript.new()
```

实现约束：

- 不改变返回 Dictionary 字段。
- 不改变 code/message 文案，避免 UI 和测试变化。
- 不把 ChoiceResolver 变成 autoload。
- 不新增 action 化选择系统。

对应测试：

```text
test_choice_resolver_v1.gd
现有 test_choice_request_v1.gd
test_combat_card_reward_choice_v1.gd
test_rest_choice_v1.gd
BattleDebugScene 相关选择测试
```

完成标准：

- ChoiceResolver 测试通过。
- 现有 choice 相关测试通过。
- GameState 不再直接包含具体 `_resolve_*_choice` 规则方法。

---

## 步骤 3：新增 MapNode BDD 测试

新增文件：

```text
scripts/stm/tests/test_map_node_v1.gd
```

测试目标：

1. `StmMapNode.new(floor_index, node_index, room_type, next_nodes, room_payload)` 能保存字段。
2. `display_room_name()` 返回：

```text
combat → 战斗房间
rest → 休息房间
boss → Boss 房间
unknown → 原字符串
```

3. `to_option(floor_name)` 返回：

```text
floor_index
node_index
floor_name
room_type
room_name
```

4. `has_next_node(floor_index, node_index)` 能判断 next_nodes。
5. `from_dict(floor_index, node_index, dict)` 能从当前 MapData 字典创建 node。
6. MapManager 的 `get_available_next_nodes()` 外部行为不变，尤其第 4 层后仍是两个第 5 层节点。

实现约束：

- 先写测试。
- 不修改 MapData 可见路径。
- 不做坐标、连线、随机生成。

完成标准：

- MapNode 作为轻量模型可用。

---

## 步骤 4：实现 MapNode 并适配 MapManager

新增文件：

```text
scripts/stm/map/map_node.gd
```

建议结构：

```gdscript
class_name StmMapNode
extends RefCounted

var floor_index: int
var node_index: int
var room_type: String
var room_payload: Dictionary
var next_nodes: Array
```

建议方法：

```gdscript
func _init(p_floor_index := 0, p_node_index := 0, p_room_type := "", p_next_nodes := [], p_room_payload := {})
static func from_dict(floor_index: int, node_index: int, data: Dictionary)
func display_room_name() -> String
func to_option(floor_name: String) -> Dictionary
func has_next_node(target_floor_index: int, target_node_index: int) -> bool
func to_dict() -> Dictionary
```

修改文件：

```text
scripts/stm/map/map_manager.gd
```

调整点：

- `_node_info(floor_index, node_index)` 可以继续返回 Dictionary 兼容旧测试。
- 新增内部 helper：

```gdscript
func _node_at(floor_index: int, node_index: int)
```

返回 `StmMapNode` 或 null。

- `get_available_next_nodes()` 使用 `StmMapNode.to_option(floor_name)` 生成 option。
- `get_current_node_info()` 继续返回 Dictionary，保持旧接口。
- 新增可选方法：

```gdscript
func get_current_node()
```

返回 `StmMapNode`。

实现约束：

- 不删除现有 public 方法。
- 不要求全项目立即改用 MapNode。
- 不改变 `.gutconfig.json` 之外的测试顺序。

对应测试：

```text
test_map_node_v1.gd
test_map.gd
test_fixed_map_node_branch_v1.gd
test_game_flow_node_branch_v1.gd
```

完成标准：

- MapManager 节点 API 外部行为不变。
- 新 MapNode 测试通过。

---

## 步骤 5：新增 RoomFactory BDD 测试

新增文件：

```text
scripts/stm/tests/test_room_factory_v1.gd
```

测试目标：

1. combat MapNode 创建 `StmCombatRoom`。
2. rest MapNode 创建 `StmRestRoom`。
3. boss MapNode 创建 `StmBossRoom`。
4. unknown room_type 返回 null。
5. GameFlow 进入当前房间时通过 RoomFactory 创建 room，但外部行为不变：

```text
第 1 层 enter_current_room() 创建 combat
第 4 层 node 0 创建 rest
第 7 层 node 0 创建 boss
```

实现约束：

- 先写测试。
- 不新增 EventRoom。
- 不新增 ShopRoom / EliteRoom。
- 不改变 RestRoom / BossRoom 规则。

完成标准：

- GameFlow 不再直接 match room_type new 房间。

---

## 步骤 6：实现 RoomFactory 并迁移 GameFlow

新增文件：

```text
scripts/stm/rooms/room_factory.gd
```

新增 class：

```gdscript
class_name StmRoomFactory
extends RefCounted
```

新增方法：

```gdscript
func create_room(map_node)
```

支持：

```text
combat → CombatRoomScript.new(payload)
rest → RestRoomScript.new(payload)
boss → BossRoomScript.new(payload)
unknown → null
```

如果现有 Room 构造函数尚不接受 payload，则本阶段可以：

```text
先创建 room
如果 room 有 set_room_payload(payload)，则调用
否则忽略 payload
```

修改文件：

```text
scripts/stm/engine/game_flow.gd
```

调整：

- 新增：

```gdscript
const RoomFactoryScript := preload("res://scripts/stm/rooms/room_factory.gd")
var _room_factory = RoomFactoryScript.new()
```

- `enter_current_room()` 不再调用 `_create_room(room_type)`。
- 改为：

```gdscript
var map_node = _map_manager.get_current_node()
var room = _room_factory.create_room(map_node)
```

- 删除或停止使用 `_create_room(room_type)`。

实现约束：

- 不改变 `enter_current_room(room_index := 0)` 外部签名。
- 不改变 GameFlow 其他流程约束。
- 不让 RoomFactory 处理 room completion。

对应测试：

```text
test_room_factory_v1.gd
test_game_flow.gd
test_game_flow_node_branch_v1.gd
test_battle_debug_scene.gd
```

完成标准：

- GameFlow 通过 RoomFactory 创建房间。
- 所有现有房间行为不变。

---

## 步骤 7：新增 EncounterFactory BDD 测试

新增文件：

```text
scripts/stm/tests/test_encounter_factory_v1.gd
```

测试目标：

1. `debug_dummy` 返回：

```text
enemies.size() == 1
enemy.enemy_name == DummyEnemy
combat_type == debug
```

2. `boss_dummy` 返回：

```text
enemies.size() == 1
enemy.enemy_name == BossEnemy
combat_type == boss
```

3. unknown encounter_id 返回空配置或失败配置，但不抛运行时错误。
4. CombatRoom 使用 payload：

```text
{"encounter_id": "debug_dummy"}
```

能启动 DummyEnemy 战斗。

5. BossRoom 使用 payload：

```text
{"encounter_id": "boss_dummy"}
```

能启动 BossEnemy 战斗。

实现约束：

- 先写测试。
- 不新增新的敌人类型。
- 不新增随机遭遇。
- 不新增奖励表。

完成标准：

- 当前 debug combat / boss combat 行为不变，但敌人创建逻辑移到 EncounterFactory。

---

## 步骤 8：实现 EncounterFactory 并迁移 CombatRoom / BossRoom

新增目录/文件：

```text
scripts/stm/encounters/encounter_factory.gd
```

新增 class：

```gdscript
class_name StmEncounterFactory
extends RefCounted
```

新增方法：

```gdscript
func create_encounter(encounter_id: String) -> Dictionary
```

返回格式：

```gdscript
{
    "ok": true,
    "enemies": [enemy],
    "combat_type": "debug"
}
```

支持 id：

```text
debug_dummy
boss_dummy
```

修改文件：

```text
scripts/stm/rooms/combat.gd
scripts/stm/rooms/boss_room.gd
```

新增 room payload 支持：

```gdscript
var room_payload: Dictionary = {}
func set_room_payload(payload: Dictionary) -> void
```

CombatRoom.enter(game_state)：

```text
读取 room_payload.encounter_id，默认 debug_dummy
调用 EncounterFactory.create_encounter(encounter_id)
用返回 enemies / combat_type 启动 combat
```

BossRoom.enter(game_state)：

```text
读取 room_payload.encounter_id，默认 boss_dummy
调用 EncounterFactory.create_encounter(encounter_id)
用返回 enemies / combat_type 启动 combat
```

MapData 可在对应 node 增加 payload：

```gdscript
{"type": "combat", "room_payload": {"encounter_id": "debug_dummy"}, ...}
{"type": "boss", "room_payload": {"encounter_id": "boss_dummy"}, ...}
```

实现约束：

- 不改变 DummyEnemy / BossEnemy 数值。
- 不改变 combat.start() 入口。
- 不让 EncounterFactory 修改 GameState。
- 不新增第二套 Combat。

对应测试：

```text
test_encounter_factory_v1.gd
test_rooms.gd
test_game_flow.gd
test_battle_debug_scene.gd
```

完成标准：

- CombatRoom / BossRoom 不再直接决定 fixture 敌人。
- 现有战斗流程保持不变。

---

## 步骤 9：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

加入：

```text
res://scripts/stm/tests/test_choice_resolver_v1.gd
res://scripts/stm/tests/test_map_node_v1.gd
res://scripts/stm/tests/test_room_factory_v1.gd
res://scripts/stm/tests/test_encounter_factory_v1.gd
```

实现约束：

- 不移除任何现有测试。
- 不加入 `.uid` 文件。
- 不绕过失败测试。

完成标准：

- 完整 GUT 会运行新增架构测试。

---

## 步骤 10：规格审查与代码质量审查

完成实现后进行双重审查。

### 规格审查

检查：

```text
玩家可见行为是否完全不变
ChoiceResolver 是否接管 choice 规则
MapNode 是否存在且 MapManager 行为不变
RoomFactory 是否接管 Room 创建
EncounterFactory 是否接管 encounter 创建
是否没有新增非目标玩法
```

### 代码质量审查

检查：

```text
GameState 是否仍包含具体 _resolve_*_choice 规则
GameFlow 是否仍直接 new CombatRoom / RestRoom / BossRoom
CombatRoom 是否仍直接绑定 FixedBattleFixtureScript 创建敌人
BossRoom 是否仍直接硬编码 BossEnemy 创建流程
MapManager 是否保持地图职责，不创建 Room
DebugScene 是否仍只调用公开入口，不直接改规则状态
是否有临时兼容代码未测试
```

如发现必须修复项，必须先修复，再进入验证。

---

## 步骤 11：完整验证

本地执行：

```powershell
git pull origin main
godot -s addons/gut/gut_cmdln.gd
```

验证通过标准：

```text
所有新增架构测试通过
所有旧测试通过
Scripts / Tests / Asserts 均无失败
BattleDebugScene 手测仍可完整跑通固定流程
```

失败处理：

```text
只看第一条失败
定位文件和行号
判断是测试旧假设还是实现错误
只修根因
不借机新增玩法
不扩大系统范围
```

---

## 每一步歧义自检

### 步骤 1 自检

- 测试文件路径明确。
- card_reward / rest_choice 行为断言明确。
- Unsupported request_type 行为明确。
- 只通过 GameState 公共入口验证，避免绑定内部实现。

结论：无歧义。

### 步骤 2 自检

- 新增文件明确。
- 迁移哪些方法明确。
- GameState 保留哪些职责明确。
- 不改变返回 code/message 明确。

结论：无歧义。

### 步骤 3 自检

- MapNode 字段明确。
- 方法名和返回字段明确。
- 不做坐标/连线/随机地图明确。

结论：无歧义。

### 步骤 4 自检

- MapManager 新 helper 与兼容方法明确。
- get_current_node_info 继续返回 Dictionary 明确。
- get_current_node 可返回 MapNode 明确。

结论：无歧义。

### 步骤 5 自检

- RoomFactory 测试目标明确。
- 支持 room_type 明确。
- unknown 行为明确。

结论：无歧义。

### 步骤 6 自检

- GameFlow 迁移点明确。
- RoomFactory 不处理完成规则明确。
- 不改变 enter_current_room 签名明确。

结论：无歧义。

### 步骤 7 自检

- EncounterFactory 支持 id 明确。
- debug_dummy / boss_dummy 验收明确。
- 不新增新敌人明确。

结论：无歧义。

### 步骤 8 自检

- CombatRoom / BossRoom 迁移目标明确。
- payload 字段明确。
- 不改变敌人数值和 combat.start 明确。

结论：无歧义。

### 步骤 9 自检

- GUT 新增测试路径明确。
- 不移除旧测试明确。

结论：无歧义。

### 步骤 10 自检

- 规格审查项明确。
- 代码质量审查项明确。
- 审查问题必须修复后再验证明确。

结论：无歧义。

### 步骤 11 自检

- 验证命令明确。
- 失败处理流程明确。
- 禁止越界修复明确。

结论：无歧义。

## 风险与控制

### 风险 1：纯架构迁移破坏玩法

控制：

```text
每一步先写测试
保持外部 API 不变
完整 GUT 回归
```

### 风险 2：借架构机会顺手加内容

控制：

```text
本轮不新增 EventRoom / Smith / 新敌人
所有新类只服务现有行为迁移
```

### 风险 3：一次改动太大，失败难定位

控制：

```text
ChoiceResolver、MapNode、RoomFactory、EncounterFactory 分四段提交
每段测试独立
```

### 风险 4：兼容 API 留下长期歧义

控制：

```text
保留旧方法只为旧测试和过渡
新实现和新 UI 优先使用 node / factory / resolver 接口
后续单独规格清理 legacy floor API
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
