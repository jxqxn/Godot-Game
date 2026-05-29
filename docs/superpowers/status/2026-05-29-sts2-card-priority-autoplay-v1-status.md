# STS2 手牌优先级排序与自动出牌 v1 实现状态

## 对应文档

```text
docs/superpowers/specs/2026-05-27-sts2-card-priority-autoplay-v1-design.md
docs/superpowers/plans/2026-05-27-sts2-card-priority-autoplay-v1.md
```

## 当前状态

v1 已实现并接入当前 Godot 主干。

已落地内容：

```text
StmCard.play_priority
StmCard.copy() 保留 play_priority
测试卡固定 play_priority
StmCardManager.get_hand_sorted_by_priority()
StmCardManager.find_highest_priority_playable_card(game_state)
战斗调试界面按优先级显示手牌
战斗调试界面“自动出牌”按钮
自动出牌复用 _play_card_from_hand() / StmCombat.play_card() / PlayCardAction / ActionQueue
GUT 规则测试与调试 UI 测试
```

## 代码收敛状态

此前 `scenes/stm/battle_debug_scene.tscn` 曾临时挂载：

```text
res://scripts/stm/debug/battle_debug_scene_priority_fix.gd
```

该补丁脚本中的行为已合并回：

```text
res://scripts/stm/debug/battle_debug_scene.gd
```

当前场景已重新直接挂载主脚本，避免后续维护时出现“场景运行补丁脚本、开发者修改主脚本”的分叉。

## 当前已知边界

v1 仍只做：

```text
排序展示
最高优先级可打牌选择
自动打出当前可打牌
```

v1 不做：

```text
自动出牌预览
不可打原因分解
复杂目标选择 UI
正式卡牌平衡
will / mind / 意愿牌 / 思维牌桌 等旧原型恢复
```

## 下一步建议：v1.1

优先推进：

```text
自动出牌预览与不可打原因展示
```

建议规则层先提供只读查询，不改变结算逻辑：

```text
当前自动出牌将选择哪张牌
没有可打牌时的原因：无手牌 / 能量不足 / 没有合法目标 / 其他 can_play 限制
```

UI 只显示规则层查询结果，不直接计算卡牌效果，不绕过 `StmCombat.play_card()`。

## 验证建议

变更后运行：

```bash
godot -s addons/gut/gut_cmdln.gd
```

确认 `.gutconfig.json` 中的旧主干测试和新增自动出牌测试全部通过后，再进入 v1.1。
