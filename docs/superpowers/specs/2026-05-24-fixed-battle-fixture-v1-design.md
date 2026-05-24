# 固定战斗内容夹具 v1 设计

## 目的

当前调试场景已经能展示玩家血量、能量、格挡、手牌、抽牌堆、弃牌堆、敌人状态、敌人意图和战斗日志，也能点击 `Strike`、`Defend`、结束回合和重开战斗。

本阶段的目标是把调试场景里临时拼装的测试战斗内容抽成一个明确入口，让“策划测试工具使用哪套测试内容”这件事有清晰边界。

第一版只做一个固定战斗样例：

- 样例名称：基础测试战斗
- 玩家：现有测试玩家，初始生命 70/70，初始能量 3/3
- 卡牌：`Strike, Defend, Strike, Defend`
- 敌人：`DummyEnemy`
- 战斗类型：`debug`

这个夹具不是正式内容库，也不是配表系统。它只是给调试场景提供稳定、可复现的战斗起点。

## 用户价值

策划打开调试场景时，应能稳定进入同一场测试战斗。每次重开战斗后，玩家、敌人、手牌、抽牌堆、弃牌堆和日志都回到同一个起点。

这能让后续测试更容易复现：

- 验证一张测试卡是否按预期造成伤害或获得格挡
- 验证敌人意图和结束回合结算是否稳定
- 验证调试工具的数值修改不会污染下一场测试
- 后续增加多个测试预设时，有一个明确扩展点

## 当前基础

项目当前已经有以下骨架：

- `scripts/stm/engine/game_bootstrap.gd`
- `scripts/stm/engine/game_state.gd`
- `scripts/stm/engine/combat.gd`
- `scripts/stm/player/player.gd`
- `scripts/stm/player/card_manager.gd`
- `scripts/stm/cards/card.gd`
- `scripts/stm/cards/test/strike.gd`
- `scripts/stm/cards/test/defend.gd`
- `scripts/stm/enemies/test/dummy_enemy.gd`
- `scripts/stm/debug/battle_debug_scene.gd`
- `scenes/stm/battle_debug_scene.tscn`
- `scripts/stm/tests/test_battle_debug_scene.gd`

当前调试场景直接 preload 测试卡牌、测试玩家和测试敌人，然后在 `start_debug_combat()` 内组装固定战斗。本设计将这部分“内容创建”移到单独 fixture 模块里。

## 模块设计

新增模块：

`scripts/stm/debug/fixtures/fixed_battle_fixture.gd`

建议类名：

`StmFixedBattleFixture`

职责：

- 提供固定样例名称
- 创建测试牌组
- 创建测试玩家
- 创建测试敌人
- 通过 `StmGameBootstrap` 创建 `GameState` 和 `Combat`
- 返回调试场景启动战斗所需的对象集合

不属于它的职责：

- 不处理按钮点击
- 不刷新 UI
- 不写战斗日志
- 不修改战斗规则
- 不负责正式内容注册
- 不读取外部配置文件

## 返回数据

fixture 创建战斗后，返回一个 Dictionary，建议字段为：

- `name`：样例名称
- `game_state`：创建好的游戏状态
- `combat`：创建好的战斗对象
- `enemy`：当前测试敌人
- `player`：当前测试玩家

调试场景只读取这些字段并保存到自身变量中，然后继续调用 `combat.start(game_state)`，刷新显示并写入日志。

## 数据流

启动调试战斗的数据流：

1. `StmBattleDebugScene.start_debug_combat()` 创建 `StmFixedBattleFixture`
2. fixture 创建新牌组、新玩家、新敌人
3. fixture 通过 `StmGameBootstrap` 创建 `GameState` 和 `Combat`
4. fixture 返回战斗上下文 Dictionary
5. 调试场景保存 `game_state`、`combat`、`enemy`
6. 调试场景启动战斗、重置日志、刷新 UI

重开战斗的数据流相同。每次重开都必须创建全新的玩家、敌人、卡牌和战斗对象，不能复用上一场战斗的实例。

## 与参考项目映射关系

Python 参考项目通常会把“运行一次战斗需要哪些初始对象”集中在启动、状态或内容构造流程里。Godot 当前阶段还没有正式内容库，因此不直接照搬完整内容系统。

本阶段只映射其中一个架构意图：

“战斗场景不应该自己散落地拼内容，而应该依赖一个明确的战斗内容入口。”

后续当卡牌、敌人、遗物、药水、地图和房间流程逐步稳定后，可以再把 fixture 演进为：

- 多个测试战斗预设
- Godot Resource 内容定义
- JSON 或 CSV 配置
- 正式内容注册表

本阶段不做这些演进，只保留可扩展边界。

## 非目标

本阶段不做：

- 不做正式卡牌库
- 不做正式敌人库
- 不做多战斗预设选择器
- 不做 JSON、CSV 或 Resource 配置
- 不做策划配表导入
- 不做正式战斗 UI
- 不做多敌人战斗
- 不接入遗物、药水、地图、房间、奖励流程
- 不修改 Python 参考项目 `slay-the-model-main/`
- 不新增第三方依赖

## 错误处理

fixture 应尽量保持简单，但需要避免调试场景在创建失败时直接崩溃。

建议规则：

- 如果 `GameBootstrap` 创建失败，返回空 Dictionary 或缺少核心字段
- 调试场景在读取 fixture 结果时检查 `game_state`、`combat`、`enemy`
- 如果关键对象缺失，调试场景显示“测试战斗创建失败”，写入日志，并禁用打牌按钮

第一版实现时，如果现有规则层已经稳定，也可以只做最小失败保护。重点是不要让空对象继续进入 `combat.start(game_state)`。

## 测试策略

继续使用 GUT，并严格遵守 `AGENT.md`：

- 写正式代码前，先在测试方法中写中文 Given-When-Then 行为注释和测试方法名
- 完成行为注释前，不写测试代码或正式代码
- spec 和测试说明均使用中文

建议新增或调整的测试：

1. `test_fixed_battle_fixture_creates_named_debug_battle`
   - Given：策划需要一个固定测试战斗样例
   - When：创建固定战斗夹具并请求战斗上下文
   - Then：返回样例名称、游戏状态、战斗对象和 DummyEnemy

2. `test_fixed_battle_fixture_creates_fresh_instances_each_time`
   - Given：策划多次重开同一个固定测试战斗
   - When：连续两次创建 fixture 战斗上下文
   - Then：两次返回的玩家、敌人、卡牌和战斗对象不是同一批实例

3. `test_debug_scene_starts_from_fixed_battle_fixture`
   - Given：调试场景依赖固定战斗夹具启动
   - When：场景完成初始化
   - Then：界面显示基础测试战斗的玩家、敌人、手牌和按钮状态

4. `test_reset_button_restarts_fixed_battle_fixture`
   - Given：策划已经修改战斗状态或打出卡牌
   - When：点击重开战斗
   - Then：调试场景回到 fixture 定义的初始状态

已有调试场景测试应继续通过。

## 安全、边界和依赖

安全边界：

- 不访问网络
- 不读写用户目录
- 不修改 Python 参考项目
- 不执行外部工具
- 不新增运行时权限需求

代码边界：

- `fixed_battle_fixture.gd` 只负责创建测试内容和战斗上下文
- `battle_debug_scene.gd` 只负责展示、按钮交互、日志和数值输入
- 战斗规则仍归 `scripts/stm/engine`、`scripts/stm/actions`、`scripts/stm/cards`、`scripts/stm/player`、`scripts/stm/enemies` 负责

依赖边界：

- 依赖 Godot 4.6.2
- 依赖现有 GDScript 模块
- 依赖现有 GUT 测试框架
- 不新增第三方插件
- 不新增 Python、Node 或网络依赖

## 验收标准

完成后应满足：

- 调试场景不再直接拼装固定战斗内容
- 固定战斗内容由 `StmFixedBattleFixture` 提供
- 每次启动和重开战斗都创建新实例
- 调试场景初始显示与当前功能保持一致
- 现有打牌、结束回合、重开、数值应用、日志测试继续通过
- 新增 fixture 测试通过
- 所有 GUT 单元测试通过

## 自检记录

- 歧义检查：固定战斗样例只有一个，不做预设选择器。
- 范围检查：本阶段只移动测试内容创建边界，不改变战斗规则。
- 安全检查：不访问网络、不修改参考项目、不新增权限。
- 依赖检查：只依赖 Godot、GDScript、GUT 和现有项目脚本。
- 扩展检查：保留未来多预设、Resource 或配置文件演进空间，但本阶段不实现。
