# STS2 EventRoom v1 文档自检记录

## 自检对象

```text
docs/superpowers/status/2026-05-30-sts2-core-runtime-architecture-spine-v1-status.md
docs/superpowers/specs/2026-05-30-sts2-event-room-v1-design.md
docs/superpowers/plans/2026-05-30-sts2-event-room-v1.md
AGENTS.md
```

## 自检结论

文档整体符合当前项目规范：

```text
1. 已先补 status，再写 EventRoom v1 规格，再写 EventRoom v1 计划。
2. 未修改正式代码。
3. 未修改 Python 参考项目。
4. 未引入随机事件池、商店、遗物、精英房或正式地图 UI。
5. EventRoom v1 被限制为一个固定事件 debug_fountain 和两个固定选项 drink / leave。
6. 规则结算被放在 ChoiceResolver，不放在 EventRoom 或 BattleDebugScene。
7. 计划要求先写 BDD 测试，再做最小 TDD 实现。
```

## 对照 AGENTS.md

### 先规格，再计划，再实现

已满足。

当前只新增文档：

```text
specs/2026-05-30-sts2-event-room-v1-design.md
plans/2026-05-30-sts2-event-room-v1.md
status/2026-05-30-sts2-core-runtime-architecture-spine-v1-status.md
```

未进入实现阶段。

### BDD 最高优先级

已满足到计划层。

计划明确第一步和第二步先新增 BDD 测试：

```text
scripts/stm/tests/test_event_room_v1.gd
scripts/stm/tests/test_choice_resolver_event_choice_v1.gd
```

并要求通过 Given-When-Then 注释锁定行为后再实现。

### 最小 TDD

已满足到计划层。

计划明确：

```text
只做一个固定事件 debug_fountain
只做两个固定选项 drink / leave
每一步只做最小实现
失败时只看第一条失败并只修根因
```

### 开发红线

已满足。

文档明确禁止：

```text
第二套 GameFlow / MapManager / ChoiceRequest / ActionQueue
随机事件池
商店
遗物
精英房
正式地图 UI
修改 Python 参考项目
```

### Python 参考项目边界

已满足。

文档明确 Python 项目只作为架构和规格参考，不作为 Godot 运行时的一部分，不直接迁移完整 Python 框架。

## 发现的问题

### 问题 1：GameFlow 测试在计划中的约束不够硬

规格中要求 EventRoom v1 至少覆盖：

```text
GameFlow 可以进入 event 房并在完成后推进到下一个节点。
```

但计划步骤 8 中写到：

```text
如果当前 GameFlow 不支持注入测试地图，则优先测试 RoomFactory + ChoiceResolver 链路，不为本阶段新增大范围注入机制。
```

这个表述本意是避免为了测试暴露过宽入口，但容易被误读为可以跳过 GameFlow 层验收。

## 修正口径

实现 EventRoom v1 时必须保留以下硬性验收：

```text
必须有 GameFlow 层面的 event 房间流程测试。
```

如果当前 GameFlow 不支持直接注入测试地图，应选择最小、安全的方式之一：

```text
1. 在测试中使用现有 debug_navigate_to_node_for_test 能力定位到包含 event 的测试节点；或
2. 为 MapManager 增加极小的测试专用地图注入能力，并明确 debug/test-only；或
3. 在不破坏旧测试的前提下，把默认固定地图的一个非关键节点替换为 event，并同步更新受影响测试。
```

不得使用以下方式绕过：

```text
只测 RoomFactory + ChoiceResolver 就宣称 GameFlow 已验收
让 BattleDebugScene 直接完成房间
让测试直接 room.complete() 代替选择结算
新增第二套 GameFlow 或 MapManager
暴露正式玩法不需要的宽泛写入口
```

## 修正后的执行要求

EventRoom v1 实现阶段必须满足：

```text
1. 先写 EventRoom BDD 测试。
2. 先写 ChoiceResolver event_choice BDD 测试。
3. 必须写 GameFlow event 房间流程测试。
4. BattleDebugScene 只能通过 GameState.submit_choice() 提交选择。
5. 完整 GUT 必须通过。
```

## 当前文档状态

```text
status 文档：通过
spec 文档：通过
plan 文档：基本通过，但步骤 8 需要按本自检记录的“修正口径”执行
```

后续如果继续实现，应优先把计划步骤 8 的口径落实到测试中，不能把 GameFlow 验收降级为可选项。
