# Godot GDScript 核心骨架设计

## 目的

为 `slay-the-model-main` Python 项目搭建一套 Godot 原生 GDScript 核心骨架，并尽可能保留原项目架构。第一阶段重点是稳定边界、类名、职责和运行流程，不追求完整游戏内容。

这个阶段完成后，后续开发应该主要是增量填充：卡牌、敌人、能力、遗物、房间、地图逻辑和 UI 都应接入既有 Godot 规则层接口，而不是反复推倒重构。

## 来源项目上下文

Python 源项目是一个逻辑优先的类杀戮尖塔卡牌构筑游戏引擎。它的重要架构边界如下：

- `engine/`：全局游戏状态、战斗循环、战斗状态、运行流程。
- `actions/`：排队执行的游戏行为。
- `entities/`：生命值、格挡、能力列表、伤害等共享生物行为。
- `player/`：玩家状态、牌堆、能量、卡组、充能球、姿态、库存。
- `cards/`：卡牌基类和具体卡牌定义。
- `enemies/`：敌人基类和敌人意图逻辑。
- `utils/`：枚举、注册表、随机工具、选项和结果类型。
- 卡牌、敌人、事件、遗物、药水、地图、本地化、AI、TUI 等内容密集模块在第一阶段不做完整移植。

## 推荐方案

采用“架构优先”的 GDScript 骨架，而不是机械地把 Python 文件转换成 GDScript。

目录和类模型应尽量贴近 Python 项目，但实现方式要适配 Godot 4.6：

- 纯规则和数据对象使用 `RefCounted`。
- 只有运行入口、场景或未来 UI 集成需要使用 `Node`。
- 牌堆、行为队列、注册表和测试内容使用简单数组与字典。
- 脚本文件保持聚焦，避免后续内容扩展时需要移动核心逻辑。
- 避免移植 Python 专属模式，例如装饰器、动态导入、大范围模块副作用和 TUI 打印。

## 安全模型

此阶段必须保持本地、确定性和低风险：

- 将 `slay-the-model-main/` 视为只读参考材料。不要编辑、删除、重命名或机械重写其中任何文件。
- 不要从 Godot 运行或嵌入 Python 引擎。新的 GDScript 规则层必须独立存在。
- 不要加入网络调用、API key、模型调用、遥测、存档上传或远程内容加载。
- 不要联网下载依赖，不要在实现骨架时引入新的外部 Godot 插件。
- 不要写入 Godot 项目目录之外的位置。
- 不要创建破坏性编辑器工具、代码生成器或批量文件重写脚本。
- 测试必须确定性执行：不使用未设种子的随机断言，不依赖墙上时间，不依赖用户输入。
- 规则测试必须可在 headless 环境运行，不要求打开交互式 Godot 编辑器窗口。

## 边界合同

第一阶段实现应让模块边界足够清晰，方便未来系统接入而不迁移核心逻辑：

- `scripts/stm/engine/` 负责游戏和战斗编排。它可以协调玩家、敌人、卡牌和行为，但不包含具体卡牌或具体敌人的内容规则。
- `scripts/stm/actions/` 负责可执行的状态变更。行为可以通过显式引用修改 `GameState`、`Player`、`Creature`、牌堆和战斗阶段。
- `scripts/stm/entities/` 只负责共享生物状态。它不应知道牌堆、战斗阶段、UI 或遭遇选择。
- `scripts/stm/cards/` 负责卡牌数据和卡牌行为。卡牌可以验证能否打出，并返回或入队行为，但不拥有战斗循环。
- `scripts/stm/player/` 负责玩家专属状态和牌堆流转。它不应知道敌人意图选择。
- `scripts/stm/enemies/` 负责敌人状态和简单意图行为。它不应知道玩家牌堆内部细节。
- `scripts/stm/tests/` 可以直接使用测试专用内容。面向生产的核心文件不得依赖测试文件。
- 未来 UI 场景可以读取状态并调用公开的战斗/游戏方法，但 UI 不能成为规则逻辑的拥有者。
- 未来完整系统，例如能力、遗物、药水、房间、地图、奖励、本地化和消息总线，是扩展点，不是第一阶段隐藏需求。

## 依赖

骨架只依赖当前本地 Godot 项目和 Godot/GDScript 内置能力：

- Godot 版本：4.6.2，与当前项目元数据一致。
- 新规则骨架语言：仅使用 GDScript。
- 验证所需外部工具：本地 Godot 可执行文件。
- 新 GDScript 骨架不依赖 Python 运行时。
- 不需要网络访问。
- Headless 规则测试不需要外部素材资源。
- 第一阶段不要求 autoload 单例；`GameBootstrap` 可以在测试中直接构造 `GameState`。规则层稳定后，未来可以再加入 autoload。
- 单元测试入口遵循项目根目录 `AGENT.md`：`godot -s addons/gut/gut_cmdln.gd`。
- 除项目约定的 GUT 测试入口外，不新增第三方 Godot 插件。如果实现阶段发现 `addons/gut/gut_cmdln.gd` 不存在，应将其报告为测试环境阻塞，而不是联网安装或临时改用另一套测试入口。

## 初始 Godot 文件结构

在项目中创建 `scripts/stm/` 作为规则引擎的包式目录：

- `scripts/stm/utils/types.gd`：目标、牌堆、卡牌、稀有度、战斗、敌人和终局结果的枚举式常量。
- `scripts/stm/utils/option.gd`：可选项对象，包含名称和待执行行为。
- `scripts/stm/actions/action.gd`：行为基类。
- `scripts/stm/actions/action_queue.gd`：按顺序执行行为的队列。
- `scripts/stm/actions/combat_actions.gd`：最小战斗行为，包括攻击、格挡、抽牌、弃牌、打出卡牌和结束回合。
- `scripts/stm/entities/creature.gd`：共享 HP、格挡、死亡、受伤、治疗和能力列表行为。
- `scripts/stm/cards/card.gd`：卡牌基类，包含费用、伤害、格挡、目标类型、升级数据、`can_play` 和 `on_play`。
- `scripts/stm/cards/test/strike.gd`：测试专用 Strike 卡。
- `scripts/stm/cards/test/defend.gd`：测试专用 Defend 卡。
- `scripts/stm/player/card_manager.gd`：卡组、抽牌堆、弃牌堆、手牌、消耗堆、洗牌、抽牌、移动、弃牌、消耗。
- `scripts/stm/player/player.gd`：玩家生物，包含能量、卡牌管理器、抽牌数、金币字段、遗物数组和药水数组。
- `scripts/stm/enemies/enemy.gd`：敌人基类，包含意图字段和最小意图钩子。
- `scripts/stm/enemies/test/dummy_enemy.gd`：测试专用敌人，拥有可预测攻击行为。
- `scripts/stm/engine/combat_state.gd`：每场战斗的计数器和阶段状态。
- `scripts/stm/engine/combat.gd`：使用 `ActionQueue` 的最小玩家/敌人回合状态机。
- `scripts/stm/engine/game_state.gd`：全局运行状态、玩家、当前战斗、当前层数和队列辅助方法。
- `scripts/stm/engine/game_bootstrap.gd`：创建最小测试运行，包括玩家、测试起始牌组和 dummy 敌人。
- `scripts/stm/tests/core_skeleton_test.gd`：第一段可玩规则切片的 GUT 测试。

## 运行时设计

`GameState` 拥有长期存在的对象：

- `player`
- `current_combat`
- `action_queue`
- `current_act`、`floor_in_act`、`current_floor` 等流程字段

`Combat` 拥有战斗内流程：

- 敌人列表
- 一个 `CombatState`
- 阶段流转：`player_start`、`player_action`、`player_end`、`enemy_action`、`enemy_end`
- 开始战斗、开始玩家回合、打出指定卡牌、结束玩家回合、执行敌人回合、检查终局状态的方法

`ActionQueue` 保留为主要调度机制：

- `add_action(action, to_front := false)`
- `add_actions(actions, to_front := false)`
- `execute_next()`
- `execute_all()`
- `is_empty()`

这保留了 Python 项目的重要执行模型：游戏逻辑通过行为队列表达，而不是直接散落在 UI 回调中。

## 最小内容范围

第一阶段只需要测试内容：

- `Strike`：费用 1，攻击牌，造成 6 点伤害，升级后 9 点伤害。
- `Defend`：费用 1，技能牌，获得 5 点格挡，升级后 8 点格挡。
- `DummyEnemy`：固定 HP，固定伤害意图，在敌人阶段攻击玩家。

第一阶段不包含完整卡牌库、敌人库、能力、遗物、药水、事件、房间、地图生成、AI、TUI、本地化或奖励流程。

## 数据流

1. `GameBootstrap` 创建 `GameState`。
2. `GameState` 创建带有小型测试卡组的 `Player`。
3. `GameBootstrap` 创建 `DummyEnemy` 并启动 `Combat`。
4. `Combat` 重置牌堆并准备第一个回合。
5. `CardManager` 将卡牌抽入手牌。
6. 测试或未来 UI 调用战斗方法，从手牌中打出一张卡。
7. `PlayCardAction` 检查费用、消耗能量、调用卡牌行为，并将卡牌移动到弃牌堆或消耗堆。
8. 伤害和格挡行为修改 `Creature` 状态。
9. `EndTurnAction` 将战斗推进到玩家回合结束，弃掉手牌，运行敌人行为，并在战斗未结束时回到玩家回合开始。

## 错误处理和防护

骨架遇到非法规则调用时应清晰失败：

- 打出不在手牌中的卡牌时，应返回 `false` 或通过 `push_error` 输出可读错误。
- 能量不足时打牌应返回 `false`。
- 无效牌堆名称应使用 `push_error` 并失败，不能修改牌堆状态。
- 抽牌堆和弃牌堆都为空时，只应少抽牌，不能崩溃。
- 战斗应返回明确的终局结果常量：胜利、失败、逃跑或无终局结果。

第一版保持本地且简单的错误处理。不要在此阶段引入完整消息总线、本地化层或类似异常系统的抽象。

## 测试策略

使用 GUT 作为项目单元测试入口，并遵守 `AGENT.md` 中的 BDD 约束：

- 在编写任何正式代码前，先写测试方法名。
- 在测试方法中先写 Given-When-Then 模式的中文行为注释。
- 完成行为注释后，才能继续写测试代码和正式代码。

初始测试应覆盖：

- 玩家卡组在战斗开始时重置到抽牌堆。
- 抽牌会将卡牌从抽牌堆移动到手牌。
- Strike 消耗 1 点能量，造成 6 点伤害，并从手牌移动到弃牌堆。
- Defend 消耗 1 点能量，获得 5 点格挡，并从手牌移动到弃牌堆。
- 结束回合会弃掉剩余手牌。
- Dummy 敌人的攻击会先被格挡抵消，再造成 HP 损失。
- 所有敌人 HP 归零时能检测到战斗胜利。

全量单元测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

如果 `addons/gut/gut_cmdln.gd` 尚不存在，应把这件事作为测试环境阻塞报告出来，不应在本阶段联网安装依赖或绕过项目测试入口。

## 未来扩展路径

骨架通过测试后，可以在不改变核心边界的前提下继续增加以下层：

- 为内容发现加入注册表或基于资源的目录。
- 按角色命名空间添加真实卡牌批次。
- 添加敌人意图和遭遇池。
- 添加能力系统和轻量消息/事件总线。
- 添加遗物和药水。
- 添加房间、奖励、地图流程和可保存运行状态。
- 添加读取规则层状态的 Godot 场景/UI，而不是让 UI 拥有规则逻辑。

## 非目标

- 不完整机械转换所有 Python 文件。
- 不为每张卡牌、每个敌人、每个遗物、每瓶药水或每个事件生成 GDScript。
- 不制作视觉 UI；未来可另做测试/调试场景。
- 不实现 AI 决策接口。
- 不追求本地化等价。
- 不为 Godot 包装或嵌入 Python 引擎。
- 不在第一阶段完美复刻所有杀戮尖塔规则交互。

## 验收标准

第一阶段完成时应满足：

- Godot 项目中存在规划好的 `scripts/stm/` 架构骨架。
- 核心类名和职责足够贴近 Python 项目，方便后续移植内容。
- GUT 单元测试能够创建战斗、抽牌、打出 Strike 和 Defend、结束回合、处理 dummy 敌人攻击，并检测战斗胜利。
- 原始 `slay-the-model-main` 目录保持未修改，继续作为参考实现。
