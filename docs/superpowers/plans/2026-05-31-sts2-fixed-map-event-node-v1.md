# STS2 Fixed Map Event Node v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-05-31-sts2-fixed-map-event-node-v1-design.md
```

## 本轮目标

把已完成的 `debug_fountain` EventRoom 接入默认固定地图中的一个非关键分支。

目标路径：

```text
第 4 层 rest
→ 第 5 层 node 0 combat
→ 第 5 层 node 1 event(debug_fountain)
→ 第 6 层 rest
→ 第 7 层 boss
```

## 非目标

```text
不新增随机事件池
不新增第二个事件
不新增 EventFactory
不新增商店 / 遗物 / 精英房
不新增正式地图 UI
不修改 Python 参考项目
不新增第二套 MapManager / GameFlow / ChoiceRequest
```

## 实施顺序

```text
1. 更新 MapManager 固定地图分支测试。
2. 更新 GameFlow 默认地图 event 分支测试。
3. 更新 BattleDebugScene 默认地图 event 分支测试。
4. 修改 MapData 第 5 层 node 1 为 event。
5. 完整 GUT 验证。
6. 规格审查与代码质量审查。
7. 更新 README / AGENTS / status 文档。
```

---

## 步骤 1：更新 MapManager 固定地图分支测试

修改文件：

```text
scripts/stm/tests/test_fixed_map_node_branch_v1.gd
```

调整：

```text
第 4 层后两个第 5 层节点：combat / event
第 5 层 node 1 测试命名从 rest branch 改为 event branch
第 5 层 event branch 汇合到第 6 层 rest
```

歧义自检：

```text
是否修改默认地图：此步骤不修改，只更新测试预期。
是否改成随机地图：否。
是否保留 combat 分支：是。
是否有歧义：无。
```

---

## 步骤 2：更新 GameFlow 默认地图 event 分支测试

修改文件：

```text
scripts/stm/tests/test_game_flow_node_branch_v1.gd
```

调整：

```text
第 4 层后 node 1 预期为 event。
选择 node 1 后 enter_current_room() 创建 EventRoom。
必须通过 GameState.submit_choice("leave") 或 drink 完成 event_choice。
完成后 advance_to_next_node(5, 0) 成功。
Boss 路径测试改为走 event 分支并汇合到第 6 层。
```

歧义自检：

```text
是否允许 complete_current_room() 绕过事件选择：否。
是否允许 test-only 地图注入：否，本阶段要验证默认地图。
是否仍覆盖 combat 分支：是。
是否有歧义：无。
```

---

## 步骤 3：更新 BattleDebugScene 默认地图 event 分支测试

修改文件：

```text
scripts/stm/tests/test_battle_debug_map_node_branch_v1.gd
```

调整：

```text
第 4 层完成后显示 combat / event 两个按钮。
点击事件房进入 event_choice。
ChoicePanel 标题为 清泉。
日志包含 进入事件房。
日志不包含 战斗开始。
提交 离开 或 饮用泉水 后显示第 6 层 rest 节点。
```

歧义自检：

```text
是否允许 BattleDebugScene 解析 payload：否。
是否允许 BattleDebugScene 直接改 HP：否。
是否允许 BattleDebugScene 直接 room.complete()：否。
是否有歧义：无。
```

---

## 步骤 4：修改 MapData 第 5 层 node 1 为 event

修改文件：

```text
scripts/stm/map/map_data.gd
```

改动：

```gdscript
{"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [{"floor_index": 5, "node_index": 0}]}
```

同时更新注释：

```text
"combat" | "rest" | "event" | "boss"
```

歧义自检：

```text
是否修改第 5 层 node 0：否。
是否修改 Boss 路径：否。
是否新增第二个 event：否。
是否有歧义：无。
```

---

## 步骤 5：完整 GUT 验证

执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

通过标准：

```text
所有测试通过。
EventRoom v1 原有测试继续通过。
默认地图分支测试通过。
BattleDebugScene 默认路径可进入事件房。
```

歧义自检：

```text
是否允许跳过失败测试：否。
是否允许忽略旧测试失败：否。
是否有歧义：无。
```

---

## 步骤 6：规格审查与代码质量审查

检查：

```text
是否只接入一个 event 节点。
是否只复用 debug_fountain。
是否没有新增随机事件池 / EventFactory。
是否没有新增正式地图 UI。
是否没有把事件规则写进 BattleDebugScene。
是否没有新增平行 MapManager / GameFlow / ChoiceRequest。
```

歧义自检：

```text
是否发现问题后继续验收：否，必须先修。
是否有歧义：无。
```

---

## 步骤 7：更新文档

需要检查并按需更新：

```text
README.md
AGENTS.md
docs/superpowers/specs/
docs/superpowers/plans/
docs/superpowers/status/
```

如果完整 GUT 通过，新增 status 文档：

```text
docs/superpowers/status/2026-05-31-sts2-fixed-map-event-node-v1-status.md
```

歧义自检：

```text
是否必须记录测试结果：是。
是否必须记录已知技术债：是。
是否有歧义：无。
```
