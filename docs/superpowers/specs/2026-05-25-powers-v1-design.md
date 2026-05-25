# 战斗状态与能力系统 v1 设计

## 目的

当前 Godot 项目已经具备最小战斗闭环：抽牌、出牌、耗能、伤害、格挡、弃牌、结束回合、敌人攻击、胜负检测，以及可供策划验证的固定战斗调试工具。

下一阶段的目标是补上“状态/能力系统”的第一版规则插槽，让后续卡牌、敌人、遗物和药水可以通过统一机制影响战斗，而不是把特殊规则散落在卡牌、敌人或 UI 回调里。

本阶段不是完整移植 Python 参考项目的 `powers/`。它只建立一个小而稳定的 Godot 原生能力层，验证四个基础状态和三张测试卡：

- `Strength`：力量，增加攻击伤害
- `Dexterity`：敏捷，增加来自卡牌的格挡
- `Weak`：虚弱，降低造成的攻击伤害
- `Vulnerable`：易伤，提高受到的攻击伤害
- `Bash`：造成伤害并施加易伤
- `Inflame`：获得力量
- `Shrug It Off`：获得格挡并抽牌

## 用户价值

对策划来说，本阶段完成后，调试场景不再只能验证 `Strike` 和 `Defend` 这种直给数值卡，还可以验证更接近真实游戏的规则交互：

- 先打 `Inflame`，再打攻击牌，伤害应提高
- 敌人带有 `Vulnerable` 时，受到攻击伤害应提高
- 玩家带有 `Weak` 时，打出的攻击伤害应降低
- 玩家带有 `Dexterity` 时，防御类卡牌获得的格挡应提高
- 状态效果应在调试工具里可见，便于复现和反馈规则问题

对开发来说，本阶段建立的是后续内容生产的地基。只要规则钩子清晰，后续添加更多卡牌或敌人时，就能优先写内容脚本，而不是反复修改战斗主循环。

## 当前基础

Godot 项目当前已有：

- `scripts/stm/actions/action_queue.gd`
- `scripts/stm/actions/combat_actions.gd`
- `scripts/stm/cards/card.gd`
- `scripts/stm/cards/test/strike.gd`
- `scripts/stm/cards/test/defend.gd`
- `scripts/stm/entities/creature.gd`
- `scripts/stm/player/player.gd`
- `scripts/stm/player/card_manager.gd`
- `scripts/stm/enemies/enemy.gd`
- `scripts/stm/enemies/test/dummy_enemy.gd`
- `scripts/stm/engine/combat.gd`
- `scripts/stm/debug/fixtures/fixed_battle_fixture.gd`
- `scripts/stm/debug/battle_debug_scene.gd`
- GUT 测试入口 `.gutconfig.json`

其中 `Creature` 已有 `powers: Array` 字段，但还没有能力对象、堆叠逻辑、查询方法或战斗钩子。

## 参考项目映射

Python 参考项目的 `powers/base.py` 包含完整消息订阅、本地化、伤害阶段和大量事件钩子。Godot 当前阶段不照搬这些复杂机制，只保留以下架构意图：

- 能力是挂在生物身上的对象
- 能力可以堆叠
- 能力有 buff/debuff 属性
- 能力可以修改伤害、格挡或回合流转
- 卡牌通过行动给目标施加能力

本阶段不引入 Python 参考项目里的消息总线、装饰器订阅、本地化解析或完整 `DamagePhase` 系统。

## 推荐方案

采用“轻量能力对象 + 显式规则钩子”的方案。

### 备选方案 A：轻量能力对象

新增 `StmPower` 基类和少量具体能力。`Creature` 负责添加、查找、移除和显示能力。伤害、格挡、回合开始和回合结束由战斗行为显式调用能力方法。

优点：

- 实现小，适合当前 Godot 骨架
- 容易测试
- 后续可以自然演进到消息总线
- 不会提前锁死复杂架构

缺点：

- 钩子数量有限，暂时不能覆盖所有复杂卡牌和遗物

### 备选方案 B：直接做消息总线

仿照 Python 参考项目，引入事件消息、订阅优先级和统一派发。

优点：

- 更接近参考项目
- 长期扩展能力强

缺点：

- 当前项目体量过小，容易过度设计
- 会推高调试和测试成本
- 可能在规则尚未稳定前引入大量抽象

### 备选方案 C：卡牌内硬编码状态效果

每张卡牌自己检查目标状态并直接修改数值。

优点：

- 初期最快

缺点：

- 后续内容一多会失控
- 规则分散，难以复用和测试
- 与架构优先的目标相反

本阶段选择方案 A。

## 新增文件结构

新增目录：

`scripts/stm/powers/`

建议文件：

- `scripts/stm/powers/power.gd`
  - 能力基类
  - 字段：`power_id`、`display_name`、`amount`、`duration`、`stack_type`、`is_buff`、`owner`
  - 方法：`stack_with()`、`modify_damage_dealt()`、`modify_damage_taken()`、`modify_block_gained()`、`on_turn_start()`、`on_turn_end()`、`is_expired()`、`summary_text()`

- `scripts/stm/powers/strength.gd`
  - 永久 buff
  - 按强度堆叠
  - 修改造成的攻击伤害：`damage + amount`

- `scripts/stm/powers/dexterity.gd`
  - 永久 buff
  - 按强度堆叠
  - 修改来自卡牌的格挡：`block + amount`

- `scripts/stm/powers/weak.gd`
  - debuff
  - 按持续时间堆叠
  - 修改造成的攻击伤害：`floor(damage * 0.75)`

- `scripts/stm/powers/vulnerable.gd`
  - debuff
  - 按持续时间堆叠
  - 修改受到的攻击伤害：`floor(damage * 1.5)`

新增测试卡：

- `scripts/stm/cards/test/bash.gd`
  - 费用 2
  - 攻击牌
  - 造成 8 点基础伤害
  - 施加 2 层易伤
  - 升级后 10 点伤害，3 层易伤

- `scripts/stm/cards/test/inflame.gd`
  - 费用 1
  - 能力牌
  - 给玩家 2 点力量
  - 升级后 3 点力量

- `scripts/stm/cards/test/shrug_it_off.gd`
  - 费用 1
  - 技能牌
  - 获得 8 点格挡并抽 1 张牌
  - 升级后 11 点格挡

新增测试：

- `scripts/stm/tests/test_powers_v1.gd`

## 核心数据模型

### StmPower

`StmPower` 是所有状态/能力的基类，使用 `RefCounted`。

字段建议：

- `power_id: String`
- `display_name: String`
- `amount: int`
- `duration: int`
- `stack_type: String`
- `is_buff: bool`
- `owner`

持续时间约定：

- `duration == -1` 表示永久能力
- `duration > 0` 表示剩余回合数
- `duration == 0` 表示已过期

堆叠规则约定：

- `"intensity"`：叠加 `amount`，例如力量、敏捷
- `"duration"`：叠加 `duration`，例如虚弱、易伤
- 第一版不做 `"both"`、`"presence"`、多实例能力

### Creature 的能力接口

`StmCreature` 扩展以下方法：

- `add_power(power) -> void`
- `get_power(power_id: String)`
- `has_power(power_id: String) -> bool`
- `remove_power(power_or_id) -> bool`
- `power_summary_text() -> String`
- `modify_damage_dealt(base_damage: int, target = null, card = null) -> int`
- `modify_damage_taken(base_damage: int, source = null, card = null) -> int`
- `modify_block_gained(base_block: int, source = null, card = null) -> int`
- `notify_turn_start(game_state, combat) -> Array`
- `notify_turn_end(game_state, combat) -> Array`

`add_power()` 如果已有同 `power_id` 能力，应调用已有能力的 `stack_with()`。新增能力必须设置 `owner`。

### 能力显示

第一版显示采用纯文本摘要：

- 力量：`力量 2`
- 敏捷：`敏捷 1`
- 易伤：`易伤 2`
- 虚弱：`虚弱 1`
- 无能力：`无`

调试工具新增显示：

- 玩家状态效果
- 敌人状态效果

## 战斗规则钩子

第一版只引入最小钩子。

### 攻击伤害

攻击结算顺序：

1. 取卡牌或敌人行动的基础伤害
2. 来源生物执行 `modify_damage_dealt()`
3. 目标生物执行 `modify_damage_taken()`
4. 最终伤害不低于 0
5. 调用目标 `take_damage(final_damage, source, card)`

本阶段只处理攻击伤害。暂不区分普通伤害、生命流失、毒、荆棘等类型。

### 格挡

格挡结算顺序：

1. 取卡牌或行动的基础格挡
2. 目标生物执行 `modify_block_gained()`
3. 最终格挡不低于 0
4. 调用目标 `gain_block(final_block)`

本阶段 `Dexterity` 只影响来自卡牌的格挡。为了简单，第一版可以让 `GainBlockAction` 统一经过 `modify_block_gained()`；如果后续需要区分来源，再加 `source` 或 `card` 判断。

### 回合开始和结束

`Combat.start_player_turn()` 调用玩家 `notify_turn_start()`。

`Combat.execute_player_end()` 调用玩家 `notify_turn_end()`。

`Combat.execute_enemy_turn()` 可在每个敌人行动前后调用敌人 `notify_turn_start()` / `notify_turn_end()`，但第一版重点只要求玩家侧持续时间能稳定减少。

`Weak` 和 `Vulnerable` 的持续时间减少规则：

- 玩家身上的 debuff 在玩家回合结束时减少 1
- 敌人身上的 debuff 在敌人行动结束后减少 1
- 永久 buff 不减少

如果实现复杂度过高，第一版可以先覆盖玩家结束回合和敌人结束行动两个明确点，不做更细的阶段事件。

## 行动设计

新增行动：

- `ApplyPowerAction`
  - 字段：`power`、`target`
  - 执行：调用 `target.add_power(power)`
  - 空目标或空能力时返回 `TerminalResult.NONE`

调整现有行动：

- `AttackAction`
  - 使用来源和目标能力修正伤害
  - 保留现有无目标保护

- `GainBlockAction`
  - 使用目标能力修正格挡

- `PlayCardAction`
  - 保持通过 `Combat._execute_play_card()` 进入队列
  - 不让卡牌主动驱动队列

## 卡牌设计

### Bash

`Bash` 的 `play()` 返回两个行动：

1. `AttackAction(player, target, damage, card)`
2. `ApplyPowerAction(VulnerablePower.new(2, 2), target)`

如果没有目标，只返回空数组或不产生有效行动。调试工具中按钮可以暂时不暴露 `Bash`，测试先通过规则层验证。

### Inflame

`Inflame` 的 `play()` 返回：

1. `ApplyPowerAction(StrengthPower.new(2, -1), player)`

能力牌打出后仍应消耗能量并进入弃牌堆。第一版不实现正式“能力牌从战斗中移除”的规则，避免引入额外牌堆规则；后续可以单独做能力牌消耗/移除行为。

### Shrug It Off

`Shrug It Off` 的 `play()` 返回：

1. `GainBlockAction(player, block, card)`
2. `DrawCardsAction(player, 1)`

敏捷应影响它的格挡值。

## 调试工具设计

当前调试工具已经能展示玩家、敌人、牌堆和日志。本阶段只做最小增强：

- 玩家状态区增加类似 `玩家状态效果：力量 2`
- 敌人状态区增加类似 `敌人状态效果：易伤 2`
- 重开战斗后状态效果应回到 `无`
- 详细日志中可以记录能力施加和修正后的结果

本阶段不要求调试工具新增 `Bash`、`Inflame`、`Shrug It Off` 按钮。原因是本阶段重点是规则地基；调试工具按钮扩展可以作为后续“多卡测试夹具/卡牌选择器”阶段处理。

## 固定战斗夹具

现有 `StmFixedBattleFixture` 可以继续使用 `Strike, Defend, Strike, Defend`，不强制加入三张新测试卡。

新增能力测试应通过 `test_powers_v1.gd` 自己创建牌组和战斗，避免调试工具固定内容突然膨胀。

后续如果策划希望在界面点击新卡，再单独做“调试夹具多预设/卡牌选择器”。

## 非目标

本阶段不做：

- 不完整移植 Python `powers/`
- 不实现完整消息总线
- 不实现本地化
- 不实现 Artifact、Frail、Poison、Thorns、Barricade 等其他状态
- 不实现遗物、药水、房间、地图或奖励流程
- 不做正式卡牌库
- 不做正式敌人库
- 不做正式战斗 UI
- 不做卡牌选择器
- 不修改 `slay-the-model-main/`
- 不新增第三方依赖

## 安全和边界

- 只修改 Godot 项目内文件
- 不访问网络
- 不执行 Python 参考项目
- 不修改 `slay-the-model-main/`
- 不新增 Godot 插件
- 不把调试工具变成规则拥有者
- 规则层仍由 `scripts/stm/actions`、`cards`、`entities`、`engine`、`powers` 管理
- 新能力系统必须能在 headless GUT 中确定性运行

## 依赖

- Godot 4.6.2
- GDScript
- GUT
- 现有 `scripts/stm/` 规则层

本阶段不新增除现有 GUT 外的依赖。

## 测试策略

继续使用 GUT，并严格遵守 `AGENT.md`：

- 写正式代码前，先写测试方法名
- 在测试方法中先写中文 Given-When-Then 行为注释
- 完成行为注释后，才能写测试代码和正式代码
- 全量测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

建议新增测试：

1. `test_strength_increases_attack_damage`
   - Given：玩家拥有力量，手牌中有攻击牌
   - When：打出攻击牌
   - Then：敌人受到基础伤害加力量的伤害

2. `test_vulnerable_increases_damage_taken`
   - Given：敌人拥有易伤
   - When：玩家攻击敌人
   - Then：敌人受到提高后的伤害

3. `test_weak_reduces_attack_damage`
   - Given：玩家拥有虚弱
   - When：玩家攻击敌人
   - Then：敌人受到降低后的伤害

4. `test_dexterity_increases_block_from_skill`
   - Given：玩家拥有敏捷
   - When：打出 `Shrug It Off`
   - Then：玩家获得基础格挡加敏捷的格挡

5. `test_apply_power_stacks_intensity_or_duration`
   - Given：目标已有力量或易伤
   - When：再次施加同名能力
   - Then：力量叠加强度，易伤叠加持续时间

6. `test_bash_deals_damage_and_applies_vulnerable`
   - Given：手牌中有 `Bash`
   - When：玩家打出 `Bash`
   - Then：敌人受到伤害并获得易伤

7. `test_inflame_applies_strength_to_player`
   - Given：手牌中有 `Inflame`
   - When：玩家打出 `Inflame`
   - Then：玩家获得力量，卡牌进入弃牌堆

8. `test_shrug_it_off_gains_block_and_draws_card`
   - Given：手牌中有 `Shrug It Off` 且抽牌堆有牌
   - When：玩家打出 `Shrug It Off`
   - Then：玩家获得格挡并抽 1 张牌

9. `test_power_duration_ticks_at_turn_boundaries`
   - Given：玩家或敌人拥有持续时间状态
   - When：对应回合结束
   - Then：持续时间减少并在 0 时移除

10. `test_debug_scene_displays_player_and_enemy_powers`
    - Given：调试场景中的玩家和敌人拥有能力
    - When：刷新显示
    - Then：界面显示状态效果摘要

## 验收标准

完成后应满足：

- 项目存在 `scripts/stm/powers/` 能力基础层
- `Creature` 可以添加、查询、堆叠、移除和显示能力
- `Strength`、`Dexterity`、`Weak`、`Vulnerable` 可用
- 攻击伤害会经过来源和目标能力修正
- 格挡会经过能力修正
- `ApplyPowerAction` 可通过行动队列施加能力
- `Bash`、`Inflame`、`Shrug It Off` 作为测试卡可用
- 调试场景能显示玩家和敌人的状态效果
- 现有 32 个测试继续通过
- 新增能力系统测试通过

## 自检记录

- 范围检查：本阶段只做四个基础状态、三个测试卡和调试显示，不做完整内容库。
- 架构检查：能力归 `powers/` 和 `entities/` 管理，UI 只显示结果。
- 依赖检查：不新增网络、Python、Node 或第三方 Godot 插件依赖。
- 安全检查：不修改 `slay-the-model-main/`，不写项目外路径。
- 歧义检查：`Strength/Dexterity` 按强度叠加；`Weak/Vulnerable` 按持续时间叠加；永久能力使用 `duration == -1`；第一版不做消息总线。
