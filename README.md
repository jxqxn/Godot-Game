# Cards / Godot-Game

这是一个基于 Godot 的卡牌战斗原型项目，当前主线围绕 STS2 复刻方向推进：地图、房间、GameFlow、战斗调试工具，以及手牌优先级排序与自动出牌 v1。

## 当前项目定位

项目目标是构建一个可测试、可迭代的卡牌战斗主干。当前重点不是扩展复杂叙事或心理系统，而是先稳定以下核心闭环：

```text
固定地图 / 房间流程
→ 进入战斗
→ 抽牌、出牌、结算行动队列
→ 结束回合 / 敌人行动
→ 战斗胜负与房间完成
```

在此基础上，当前已接入：

```text
手牌中的卡牌拥有 play_priority
→ 调试战斗界面按优先级显示手牌
→ 点击“自动出牌”
→ 系统选择当前最高优先级且可打出的牌
→ 复用现有 StmCombat.play_card / PlayCardAction / ActionQueue 流程结算
```

当前 v1 已完成：手牌优先级排序与自动出牌。
下一步建议推进 v1.1：自动出牌预览与不可打原因展示。

## 运行入口

Godot 工程入口：

```text
project.godot
```

当前主场景：

```text
res://scenes/stm/battle_debug_scene.tscn
```

在 Godot 编辑器中打开项目后，可以直接运行主场景进入战斗调试工具。

## 测试

当前项目使用 GUT 测试。推荐在项目根目录执行：

```bash
godot -s addons/gut/gut_cmdln.gd
```

当前 `.gutconfig.json` 覆盖的核心测试包括：

```text
core_skeleton_test.gd
test_battle_debug_scene.gd
test_fixed_battle_fixture.gd
test_powers_v1.gd
test_map.gd
test_rooms.gd
test_game_flow.gd
test_card_priority_autoplay_v1.gd
test_battle_debug_priority_autoplay_v1.gd
test_combat_can_play_guard.gd
```

2026-05-29：上次人工确认 GUT 测试通过；后续每次变更合并前应重新运行完整测试。

## 当前主线文档

规格文档：

```text
docs/superpowers/specs/2026-05-27-sts2-card-priority-autoplay-v1-design.md
```

实施计划：

```text
docs/superpowers/plans/2026-05-27-sts2-card-priority-autoplay-v1.md
```

实现状态：

```text
docs/superpowers/status/2026-05-29-sts2-card-priority-autoplay-v1-status.md
```

## 关键代码区域

```text
scripts/stm/cards/          卡牌定义与测试卡
scripts/stm/player/         玩家与卡牌管理器
scripts/stm/actions/        战斗行动与 ActionQueue
scripts/stm/engine/         Combat / GameState / GameFlow 主干
scripts/stm/map/            固定地图与楼层导航
scripts/stm/rooms/          战斗房、休息房、Boss 房
scripts/stm/debug/          战斗调试场景与固定测试夹具
scripts/stm/tests/          GUT 测试
```

## 开发红线

当前阶段不要恢复或新增以下旧原型体系：

```text
will/
mind/
意愿牌
本能牌
思维牌桌
人格痕迹
扶植 / 压制
独立 will_debug_scene
```

新功能应优先复用现有主干：

```text
StmCard
StmCardManager
StmCombat
StmGameState
StmCombatActions.PlayCardAction
ActionQueue / add_action / drive_actions
现有 GUT 测试配置
```

不要新增平行手牌系统、平行行动队列或平行战斗结算逻辑。

## 建议的下一步

优先推进一个小范围 v1.1：

```text
自动出牌预览
```

目标是在战斗调试界面显示当前自动出牌将选择哪张牌，以及没有可打牌时的原因。该功能应只读取现有规则层结果，不改变战斗结算逻辑。
