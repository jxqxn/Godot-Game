# STS2 固定地图节点分支 v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-30-sts2-fixed-map-node-branch-v1-design.md
```

本计划只实现规格中的 v1 范围：

```text
固定测试地图节点化
玩家只能选择当前节点连接到的下一层节点
第 4 层休息后显示两个第 5 层节点
GameFlow 支持 node_index
DebugScene 按节点导航
BDD / TDD 测试覆盖
```

不实现：

```text
完整随机地图生成
地图连线绘制
正式地图 UI
事件房 / 商店房 / 精英房完整系统
完整 Python MapManager 迁移
多 act 地图
地图种子
路径交叉检测
Boss 宝箱 / Act 过渡
will / mind / 意愿牌 / 思维牌桌
```

## 实施前提

当前已有：

- `scripts/stm/map/map_data.gd`
  - 当前是 `floors[i].rooms[j].next_floors` 简化结构
- `scripts/stm/map/map_manager.gd`
  - 当前只维护 `_current_floor_index`
  - 当前 `get_available_next_floors()` 聚合当前楼层所有 rooms 的 `next_floors`
- `scripts/stm/engine/game_flow.gd`
  - 当前 `advance_to_next_floor(floor_index)` 只按 floor 导航
- `scripts/stm/debug/battle_debug_scene.gd`
  - 当前下一层按钮只传 `floor_index`
- 现有 GUT 测试体系

## 总体实现顺序

严格按 BDD / TDD：

```text
先写节点地图规则测试
再写 GameFlow 节点推进测试
再写 DebugScene 节点分支 UI 测试
再改 MapData 为 nodes / next_nodes
再改 MapManager 维护 current_node_index
再改 GameFlow 暴露 node API
再改 DebugScene 使用 node API
再更新旧测试和 GUT 配置
最后完整验证
```

## 实施步骤

### 步骤 1：新增固定地图节点分支 BDD 测试

新增文件：

```text
scripts/stm/tests/test_fixed_map_node_branch_v1.gd
```

测试目标：

1. 初始位置是：

```text
floor_index = 0
node_index = 0
room_type = combat
```

2. 第 4 层 node 0 的 room_type 是 `rest`。
3. 第 4 层 node 0 的可用下一节点有两个。
4. 这两个下一节点都属于第 5 层：

```text
floor_index = 4, node_index = 0
floor_index = 4, node_index = 1
```

5. 第 5 层 node 0 是 `combat`。
6. 第 5 层 node 1 是 `rest`。
7. 从第 4 层 node 0 不允许直接导航到第 6 层 node 0。
8. 从第 5 层 node 0 可导航到第 6 层 node 0。
9. 从第 5 层 node 1 可导航到第 6 层 node 0。
10. 第 6 层 node 0 可导航到第 7 层 node 0。
11. 第 7 层 node 0 是 `boss`，没有下一节点。

实现约束：

- 只写测试，不写实现。
- 不改旧测试。
- 不依赖随机数、时间或人工点击。
- 不引入随机地图生成。

完成标准：

- 测试明确锁住“第 4 层后是两个第 5 层节点，而不是第 5 / 第 6 层跳转”。

---

### 步骤 2：新增 GameFlow 节点推进 BDD 测试

新增文件：

```text
scripts/stm/tests/test_game_flow_node_branch_v1.gd
```

测试目标：

1. 从第 1 层到第 4 层沿 node 0 正常推进。
2. 第 4 层 rest 完成 rest_choice 后，`get_available_next_nodes()` 返回两个第 5 层节点。
3. 选择第 5 层 node 0 后：

```text
current_floor_index == 4
current_node_index == 0
current room type == combat
```

4. 完成第 5 层 node 0 combat 后，只能前往第 6 层 node 0。
5. 重新走另一条测试路径，选择第 5 层 node 1 后：

```text
current_floor_index == 4
current_node_index == 1
current room type == rest
```

6. 完成第 5 层 node 1 rest 后，也只能前往第 6 层 node 0。
7. 第 6 层完成后能进入第 7 层 Boss。
8. 不允许第 4 层完成后直接 `advance_to_next_node(5, 0)`。

测试 helper 建议：

```gdscript
func _win_current_combat_room_and_advance_to_node(flow, floor_index: int, node_index: int) -> bool
func _complete_current_rest_choice_and_advance_to_node(flow, floor_index: int, node_index: int) -> bool
func _skip_pending_card_reward(flow) -> bool
func _skip_pending_rest_choice(flow) -> bool
```

实现约束：

- 不通过 `debug_navigate_to_floor_for_test()` 跳过正常路径，除非测试标题明确是 debug 导航。
- 不复用旧的“第 4 层直接跳第 6 层”假设。
- 不改 Boss 胜利规则。

完成标准：

- GameFlow 层证明两条第 5 层分支都存在且汇合到第 6 层。

---

### 步骤 3：新增 DebugScene 地图节点分支 UI BDD 测试

新增文件：

```text
scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
```

测试目标：

1. 调试场景从第 1 层走到第 4 层休息房。
2. 完成第 4 层 rest_choice 后，地图显示两个下一节点按钮。
3. 两个按钮都包含：

```text
第 5 层
```

4. 一个按钮包含：

```text
战斗房间
```

5. 一个按钮包含：

```text
休息房间
```

6. 第 4 层后不显示：

```text
第 6 层
```

作为直接下一步按钮。

7. 点击“第 5 层 战斗房间”后进入 combat。
8. 点击“第 5 层 休息房间”后进入 rest_choice。

实现约束：

- 不依赖真实鼠标点击。
- 复用现有 `_press_button()` / `_debug_node_or_null()` 风格。
- 不新建正式地图 UI。
- 不让 UI 直接修改 MapManager 状态。

完成标准：

- DebugScene UI 不再把第 4 层后分支显示为“第 5 层 / 第 6 层”。

---

### 步骤 4：把 MapData 改成 nodes / next_nodes 固定节点图

修改文件：

```text
scripts/stm/map/map_data.gd
```

当前结构：

```gdscript
{"rooms": [{"type": "rest", "next_floors": [4, 5]}]}
```

目标结构：

```gdscript
{"nodes": [{"type": "rest", "next_nodes": [{"floor_index": 4, "node_index": 0}, {"floor_index": 4, "node_index": 1}]}]}
```

固定地图应为：

```text
第 1 层 node 0 combat → 第 2 层 node 0
第 2 层 node 0 combat → 第 3 层 node 0
第 3 层 node 0 combat → 第 4 层 node 0
第 4 层 node 0 rest   → 第 5 层 node 0 / 第 5 层 node 1
第 5 层 node 0 combat → 第 6 层 node 0
第 5 层 node 1 rest   → 第 6 层 node 0
第 6 层 node 0 rest   → 第 7 层 node 0
第 7 层 node 0 boss   → none
```

实现约束：

- 不新增随机地图数据。
- 不新增坐标字段，除非测试需要；本轮不需要。
- 不保留 `rooms` 与 `nodes` 双结构，避免歧义。

对应测试：

- `test_fixed_map_node_branch_v1.gd` 结构相关测试。

完成标准：

- MapData 能表达第 5 层两个节点。

---

### 步骤 5：更新 MapManager 支持 current_node_index 和 next_nodes

修改文件：

```text
scripts/stm/map/map_manager.gd
```

新增字段：

```gdscript
var _current_node_index: int = 0
```

新增方法：

```gdscript
func get_current_node_index() -> int
func get_current_node_info() -> Dictionary
func get_available_next_nodes() -> Array
func can_navigate_to_next_node(floor_index: int, node_index: int) -> bool
func navigate_to_node(floor_index: int, node_index: int) -> bool
func navigate_to_next_node(floor_index: int, node_index: int) -> bool
```

`get_available_next_nodes()` 返回数组元素格式：

```gdscript
{
    "floor_index": int,
    "node_index": int,
    "floor_name": String,
    "room_type": String,
    "room_name": String,
}
```

`room_name` 可由 MapManager 内部 helper 生成：

```gdscript
func _room_type_display_name(room_type: String) -> String
```

映射：

```text
combat → 战斗房间
rest → 休息房间
boss → Boss 房间
```

修改 `get_available_room_types()`：

```text
返回当前节点的单个 room type 数组：如 ["combat"]
```

保留兼容方法：

```gdscript
func get_available_next_floors() -> Array
func can_navigate_to_next_floor(floor_index: int) -> bool
func navigate_to_next_floor(floor_index: int) -> bool
func navigate_to_floor(floor_index: int) -> bool
```

兼容规则：

- `get_available_next_floors()` 可以调用 `get_available_next_nodes()`，并返回带 `node_index` 的选项。
- `navigate_to_next_floor(floor_index)` 在可达节点里选择该 floor 的第一个节点。
- `navigate_to_floor(floor_index)` 仍默认 node 0，只供旧 debug/test 兼容。

实现约束：

- 不新建第二套 MapManager。
- 不让 MapManager 创建 Room 实例。
- 不让 MapManager 处理房间完成。

对应测试：

- `test_fixed_map_node_branch_v1.gd`。

完成标准：

- MapManager 能准确区分第 5 层 node 0 和 node 1。

---

### 步骤 6：更新 GameFlow 暴露 node API

修改文件：

```text
scripts/stm/engine/game_flow.gd
```

新增方法：

```gdscript
func get_current_node_index() -> int
func get_available_next_nodes() -> Array
func advance_to_next_node(floor_index: int, node_index: int) -> bool
func debug_navigate_to_node_for_test(floor_index: int, node_index: int = 0) -> bool
```

修改 `enter_current_room(room_index: int = 0)`：

- 当前节点只有一个 room type，因此 `room_index` 可继续保留兼容。
- 读取 room type 时依赖 `MapManager.get_available_room_types()` 返回当前节点 room type。

保留兼容：

```gdscript
func get_available_next_floors() -> Array
func advance_to_next_floor(floor_index: int) -> bool
func debug_navigate_to_floor_for_test(floor_index: int) -> bool
```

兼容规则：

- `get_available_next_floors()` 返回 `get_available_next_nodes()` 结果，包含 `node_index`。
- `advance_to_next_floor(floor_index)` 转调 MapManager 的兼容方法。
- `debug_navigate_to_floor_for_test(floor_index)` 转到 `debug_navigate_to_node_for_test(floor_index, 0)`。

实现约束：

- 不改变战斗房、休息房、Boss 房的完成规则。
- 不改 action_queue。
- 不改 card_reward / rest_choice 处理。

对应测试：

- `test_game_flow_node_branch_v1.gd`。
- 旧 `test_game_flow.gd`。

完成标准：

- GameFlow 可以精确推进到第 5 层 node 0 或 node 1。

---

### 步骤 7：更新 BattleDebugScene 下一节点按钮

修改文件：

```text
scripts/stm/debug/battle_debug_scene.gd
```

当前按钮创建逻辑类似：

```gdscript
for option in game_flow.get_available_next_floors():
    var btn = _new_button("NextFloorButton%d" % option["floor_index"], "→ %s" % option["floor_name"])
    btn.pressed.connect(_on_next_floor_selected.bind(option["floor_index"]))
```

目标：

```gdscript
for option in game_flow.get_available_next_nodes():
    var btn = _new_button(
        "NextNodeButton%d_%d" % [option["floor_index"], option["node_index"]],
        "→ %s %s" % [option["floor_name"], option["room_name"]]
    )
    btn.pressed.connect(_on_next_node_selected.bind(option["floor_index"], option["node_index"]))
```

新增方法：

```gdscript
func _on_next_node_selected(floor_index: int, node_index: int) -> void
```

保留兼容：

```gdscript
func _on_next_floor_selected(floor_index: int) -> void
```

兼容方法可以调用：

```gdscript
game_flow.advance_to_next_floor(floor_index)
```

但新 UI 不再使用它。

实现约束：

- UI 只调用 GameFlow，不直接改 MapManager。
- 不新建地图 UI 面板。
- 不改变 ChoicePanel。

对应测试：

- `test_battle_debug_map_node_branch_v1.gd`。
- 旧 DebugScene 测试。

完成标准：

- 第 4 层后按钮显示为两个第 5 层节点，且可点击进入不同 room type。

---

### 步骤 8：更新旧测试以符合节点地图

可能修改文件：

```text
scripts/stm/tests/test_map.gd
scripts/stm/tests/test_game_flow.gd
scripts/stm/tests/test_battle_debug_scene.gd
scripts/stm/tests/test_battle_debug_rest_choice_v1.gd
```

需要查找并更新的旧假设：

```text
第 4 层后可直接选第 6 层
第 5 层 / 第 6 层是二选一
get_available_room_types() 返回当前楼层所有 rooms
get_available_next_floors() 不含 node_index
```

新断言应改为：

```text
第 4 层后两个选项都在第 5 层
第 5 层 node 0 是 combat
第 5 层 node 1 是 rest
第 5 层两条分支都汇合到第 6 层
```

实现约束：

- 只更新与节点地图冲突的测试。
- 不降低 card_reward / rest_choice / Boss 断言强度。
- 不删除旧测试来规避失败。

完成标准：

- 旧测试与节点地图新语义一致。

---

### 步骤 9：更新 GUT 配置

修改文件：

```text
.gutconfig.json
```

新增测试：

```text
res://scripts/stm/tests/test_fixed_map_node_branch_v1.gd
res://scripts/stm/tests/test_game_flow_node_branch_v1.gd
res://scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
```

实现约束：

- 保留所有旧测试。
- 不移除 rest_choice / card_reward 测试。
- 不加入 `.uid` 文件。

完成标准：

- GUT 会运行新增节点地图测试。

---

### 步骤 10：完整验证与 systematic-debugging

本地执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果失败：

1. 只看第一条失败。
2. 定位具体文件和行号。
3. 判断是旧断言过期，还是实现错误。
4. 只修根因。
5. 不借机实现随机地图、正式地图 UI 或事件房。
6. 不改 card_reward / rest_choice 规则。
7. 不改 TerminalResult。
8. 不改 project.godot。

完成标准：

- 新增节点地图测试通过。
- 旧地图、GameFlow、DebugScene 测试通过。
- card_reward / rest_choice / Boss 流程继续通过。
- 手测确认：第 4 层完成后显示两个第 5 层节点，而不是第 5 / 第 6 层。

## 每个步骤是否有歧义：自检

### 步骤 1 自检

- 新增测试文件路径明确。
- 初始节点、第 4 层分支、第 5 层两个节点、第 6 层汇合、第 7 层 Boss 都明确。
- 禁止第 4 层直达第 6 层明确。

结论：无歧义。

### 步骤 2 自检

- GameFlow 新测试路径明确。
- combat 分支和 rest 分支分别验证明确。
- helper 名称和行为明确。

结论：无歧义。

### 步骤 3 自检

- DebugScene UI 测试目标明确。
- 按钮文本必须包含 floor 和 room type 明确。
- 不显示第 6 层直接选项明确。

结论：无歧义。

### 步骤 4 自检

- 修改文件明确。
- nodes / next_nodes 数据结构明确。
- 固定 7 层节点图明确。
- 不保留 rooms 双结构明确。

结论：无歧义。

### 步骤 5 自检

- MapManager 新字段和方法明确。
- 返回 option 字段明确。
- 兼容 floor 方法语义明确。

结论：无歧义。

### 步骤 6 自检

- GameFlow 新 API 明确。
- 兼容旧 API 明确。
- 不碰战斗/奖励/休息规则明确。

结论：无歧义。

### 步骤 7 自检

- DebugScene 要改哪个按钮逻辑明确。
- 新回调 `_on_next_node_selected()` 明确。
- UI 不直接改 MapManager 明确。

结论：无歧义。

### 步骤 8 自检

- 需要更新的旧假设明确。
- 禁止删除测试规避失败明确。

结论：无歧义。

### 步骤 9 自检

- 修改文件明确。
- 新增测试路径明确。
- 保留旧测试明确。

结论：无歧义。

### 步骤 10 自检

- 验证命令明确。
- 失败处理流程明确。
- 禁止越界修复明确。

结论：无歧义。

## 风险提示

1. `get_available_room_types()` 语义会从“当前楼层所有 rooms”改成“当前节点 room type”，旧测试可能需要更新。
2. `advance_to_next_floor(floor_index)` 在同一 floor 多 node 时有歧义，因此新 UI 必须使用 `advance_to_next_node()`。
3. DebugScene 的按钮查找测试要能区分两个“第 5 层”按钮，必须包含 room type 文案。
4. `debug_navigate_to_floor_for_test()` 默认 node 0，测试第 5 层 rest 分支必须使用 `debug_navigate_to_node_for_test(4, 1)`。
5. 如果旧测试依赖第 4 层直达第 6 层，需要改为选择第 5 层 rest 分支再进入第 6 层。

## 等待执行确认

本计划完成后，下一步应等待确认。

确认后再进入实现阶段，按本计划执行：

```text
先写 BDD 测试
再改 MapData
再改 MapManager
再改 GameFlow
再改 DebugScene
再更新旧测试和 GUT 配置
再完整验证
```
