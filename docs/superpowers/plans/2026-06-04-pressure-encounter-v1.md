# Pressure Encounter v1 实施计划

## 对应规格

```text
docs/superpowers/specs/2026-06-04-pressure-encounter-v1-design.md
```

## 本轮目标

实现 Pressure Encounter v1 的最小可测试切片。

目标不是新增一个普通事件，而是在现有 STS2 主干上验证未来统一遭遇框架的第一块运行时种子：

```text
手动构造 debug_pressure_encounter EventRoom
→ 创建独立 PressureEncounterState
→ GameState.current_pressure_encounter 持有当前压力遭遇
→ 生成 pressure_encounter_choice
→ 玩家通过 grasp / express / quiet / discard / refresh 处理浮现候选卡
→ 工作记忆、专注点、行动倾向轨、局势轨、核心触发发生变化
→ 进入固定自动结算管线
→ 输出可解释日志
→ 清理 current_pressure_encounter 并完成房间
```

## 本轮非目标

```text
不接入默认地图
不修改默认 7 层地图
不新增正式地图 UI
不进入 StmCombat
不替换 Combat / Rest / Event / Boss
不新增 current_encounter 泛化抽象
不新增随机事件池
不新增 EventFactory / PressureEncounterFactory
不新增第二套 GameState / GameFlow / ChoiceRequest / DebugScene
不新增完整叙事系统
不新增完整心理系统
不新增装备 / 调查 / 技能树系统
不实现完整后期经济引擎
不新增 withdraw_response
不新增 bystander_exposure
不新增第三个及以上 core_trigger
不修改 StmCard.can_play(game_state) bool 语义
不修改 StmTypes.TerminalResult
不修改 project.godot
不恢复 AGENTS.md 禁止的旧原型体系
```

## 实施顺序

```text
1. 新增 PressureEncounterState 的空壳与首个进入测试。
2. 接入 GameState.current_pressure_encounter 与 EventRoom debug_pressure_encounter 启动分支。
3. 生成 pressure_encounter_choice 的最小 ChoiceRequest。
4. 接入 ChoiceResolver 的 pressure_encounter_choice 转发分支。
5. 实现 grasp / discard / refresh 的最小状态变化。
6. 实现 express / quiet / keep 的最小状态变化。
7. 固定 3 条行动倾向轨与 2 条局势轨。
8. 实现 observation_window 与 panic_spiral 两个 core_trigger。
9. 实现 emotion_unquieted 与 quiet 的真实信息价值。
10. 实现固定自动结算管线。
11. 实现可解释日志与 choice_result detail / state_summary 的非破坏性输出。
12. 补齐 BattleDebugScene 显示测试。
13. 完整 GUT 验证。
14. 规格审查与代码质量审查。
15. 更新 status 文档。
```

---

## 步骤 1：新增 PressureEncounterState 空壳与首个进入测试

新增文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
```

首个测试：

```gdscript
func test_pressure_event_enter_creates_first_pressure_encounter_choice_request() -> void:
```

Given / When / Then：

```gdscript
# Given 一个手动构造的 event_id 为 debug_pressure_encounter 的 EventRoom
# When enter(game_state)
# Then game_state.current_pressure_encounter 不为空
# And current_pressure_encounter 是独立 PressureEncounterState
# And current_choice_request.request_type == "pressure_encounter_choice"
# And title 包含压力节点信息
```

最小实现：

```text
PressureEncounterState 可以先只包含 init / build_choice_request / is_completed。
不要在此步骤实现全部卡牌与结算。
```

歧义自检：

```text
是否把 PressureEncounterState 放进 scripts/stm/events/：否。
是否把 focus_points 等字段摊平进 GameState：否。
是否通过默认地图进入：否，测试手动构造 EventRoom。
是否有歧义：无。
```

---

## 步骤 2：接入 GameState.current_pressure_encounter 与 EventRoom 启动分支

修改文件：

```text
scripts/stm/core/game_state.gd
scripts/stm/rooms/event_room.gd
```

改动：

```gdscript
var current_pressure_encounter = null
```

`StmEventRoom.enter(game_state)` 增加：

```text
当 event_id == "debug_pressure_encounter"：
1. 创建 PressureEncounterState。
2. 初始化压力遭遇。
3. 写入 game_state.current_pressure_encounter。
4. 从状态对象生成 pressure_encounter_choice。
5. 写入 current_choice_request。
```

歧义自检：

```text
是否新增第二套 room / game flow：否。
是否让 EventRoom 保存完整玩法状态：否。
是否继续保留 debug_fountain 行为：是。
是否修改默认地图：否。
是否有歧义：无。
```

---

## 步骤 3：生成 pressure_encounter_choice 的最小 ChoiceRequest

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
```

要求：

```text
request_type == "pressure_encounter_choice"
title 包含：压力遭遇 / 当前节点
options 至少包含：grasp / discard / refresh
每个 option payload 使用：
{
  "action": "pressure_action",
  "pressure_action": "grasp",
  "card_id": "observed_instability"
}
```

建议先实现 Node 1 的最小浮现池：

```text
observed_instability
ally_waiting
hands_shaking
basic_procedure
```

歧义自检：

```text
是否使用 pressure_event_choice：否。
是否使用 encounter_choice：否，v1 暂不过早泛化。
是否让玩家直接点击最终行动：否。
是否有歧义：无。
```

---

## 步骤 4：接入 ChoiceResolver 转发分支

修改文件：

```text
scripts/stm/choices/choice_resolver.gd
```

新增分支：

```gdscript
"pressure_encounter_choice":
    return _resolve_pressure_encounter_choice(game_state, request, option)
```

`_resolve_pressure_encounter_choice()` 只负责桥接：

```text
1. 校验 option payload。
2. 读取 game_state.current_pressure_encounter。
3. 调用 current_pressure_encounter.handle_pressure_action(...)
4. 如果未完成，刷新 current_choice_request。
5. 如果完成，清理 current_choice_request 与 current_pressure_encounter，并完成当前 room。
6. 返回 choice_result。
```

歧义自检：

```text
是否在 ChoiceResolver 内维护工作记忆 / 连锁 / 结算：否。
是否绕过 GameState.submit_choice()：否。
是否让 BattleDebugScene 直接调用 PressureEncounterState：否。
是否有歧义：无。
```

---

## 步骤 5：实现 grasp / discard / refresh 最小状态变化

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
```

新增测试：

```gdscript
func test_pressure_choice_grasp_card_moves_card_to_working_memory() -> void:
func test_pressure_choice_refresh_increases_pressure() -> void:
func test_pressure_choice_discard_releases_working_memory_slot() -> void:
```

状态规则：

```text
grasp：
- focus_points -1
- 从 emergence_pool 移入 working_memory
- 应用该卡 grasp effects
- 记录日志

discard：
- 从 working_memory 或 emergence_pool 移除指定卡
- 成本 0
- 释放工作记忆格
- 记录日志

refresh：
- focus_points -1
- situation_tracks.pressure +1
- 重新生成 emergence_pool
- 记录日志
```

歧义自检：

```text
refresh 是否无代价：否，必须压力 +1。
working_memory 是否只是已选列表：否，必须有容量限制。
discard 是否能释放格子：是。
是否实现复杂随机池：否，先用静态池 / 固定轮换。
是否有歧义：无。
```

---

## 步骤 6：实现 express / quiet / keep 最小状态变化

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
```

规则：

```text
express：
- 来源为 working_memory
- focus_points -1
- 应用 express effects
- 将卡加入 used_cards
- 记录日志

quiet：
- 来源为 emotion / 干扰类 working_memory 卡
- focus_points -1
- 阻止或移除该卡对 emotion_unquieted 的推进
- 至少 hands_shaking 的 quiet 产生 steady_response +1 或等价日志价值
- 加入 quieted_cards
- 记录 insight log

keep：
- 来源为 working_memory
- focus_points -1
- 加入 kept_cards
- 下个 pressure_node 保留
- 记录日志
```

新增测试：

```gdscript
func test_pressure_quiet_prevents_panic_spiral_progress() -> void:
func test_pressure_quiet_emotion_can_create_insight_value() -> void:
```

歧义自检：

```text
quiet 是否只是删除 debuff：否，必须体现真实信息价值。
keep 是否需要完整冻结 UI：否，v1 只需要状态保留。
是否新增情绪洞察轨：否。
是否有歧义：无。
```

---

## 步骤 7：固定 3 条行动倾向轨与 2 条局势轨

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
```

初始化：

```gdscript
action_tendency_tracks = {
    "steady_response": 0,
    "forceful_response": 0,
    "freeze_response": 0,
}

situation_tracks = {
    "pressure": 0,
    "pressure_limit": 6,
    "ally_trust": 0,
}
```

明确不实现：

```text
withdraw_response
bystander_exposure
```

歧义自检：

```text
是否保留 Dictionary / Map 结构方便未来扩展：是。
是否在 v1 加第四条行动倾向：否。
是否在 v1 加第三条局势轨：否。
是否有歧义：无。
```

---

## 步骤 8：实现 observation_window 与 panic_spiral

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
```

新增测试：

```gdscript
func test_pressure_observation_window_triggers_forceful_bonus() -> void:
func test_pressure_unquieted_emotion_triggers_panic_spiral() -> void:
```

规则：

```text
observation_window：
- chain_counts.observation >= 2 时触发
- triggered_cores 添加 observation_window
- forceful_response +1
- 记录日志

panic_spiral：
- chain_counts.emotion_unquieted >= 2 时触发
- triggered_cores 添加 panic_spiral
- freeze_response +1
- 记录日志
```

注意：

```text
每个 core_trigger 只触发一次。
quiet 后的 emotion 卡不应继续推进 emotion_unquieted。
```

歧义自检：

```text
是否只做正向核心：否，必须有污染核心。
是否做第三个 trust_anchor：否。
是否让 panic_spiral 无法处理：否，quiet 必须能影响它。
是否有歧义：无。
```

---

## 步骤 9：补齐 3 个压力节点与 8-12 张静态候选卡

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
```

节点 1：看清局面

```text
observed_instability      对方快失控了       observation
ally_waiting              同伴在等你的判断   relationship
hands_shaking             手在发抖           emotion
basic_procedure           按流程来           technique
```

节点 2：说出关键信息

```text
evidence_not_simple       事情不是表面那样   evidence
situation_closing_in      局势正在收紧       observation
self_doubt                我可能又搞砸了     emotion
keep_talking              继续拖住局面       technique
```

节点 3：临界前一秒

```text
act_now                   现在必须行动       technique
ally_can_hear_you         同伴听得见你       relationship
body_locks_up             身体僵住了         emotion
```

歧义自检：

```text
是否使用 risk_bystander_exposed：否。
是否新增 bystander_exposure 字段：否。
是否需要完整剧情文本：否，只需调试文本和机制含义。
是否有歧义：无。
```

---

## 步骤 10：实现固定自动结算管线

修改文件：

```text
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
```

新增测试：

```gdscript
func test_pressure_event_resolves_highest_action_tendency() -> void:
func test_pressure_auto_resolution_pipeline_writes_ordered_steps() -> void:
```

管线顺序：

```text
LOCK_MEMORY
CHECK_CORES
SUMMARIZE_TENDENCIES
CHOOSE_DOMINANT_TENDENCY
APPLY_PRESSURE_MODIFIER
APPLY_ALLY_TRUST_MODIFIER
BUILD_FINAL_RESULT
WRITE_RESOLUTION_LOG
```

平局优先级：

```text
freeze_response
> forceful_response
> steady_response
```

结果类型：

```text
result_steady
result_forceful
result_freeze
```

歧义自检：

```text
是否只输出一行最终结果：否。
是否允许玩家直接选择最终结果：否。
是否实现自由战斗式结算：否。
是否有歧义：无。
```

---

## 步骤 11：完善 choice_result detail / state_summary 的非破坏性输出

修改文件：

```text
scripts/stm/choices/choice_resolver.gd
scripts/stm/encounters/pressure/pressure_encounter_state.gd
```

目标：

```text
不破坏既有 choice_result 的 ok / code / message / request_type / selected_option_id 语义。
可额外附加 detail 或 state_summary，供 BattleDebugScene 日志面板显示。
```

建议字段：

```gdscript
{
  "detail": "...",
  "state_summary": "..."
}
```

歧义自检：

```text
是否破坏既有测试对 choice_result 的断言：否。
是否把 UI 逻辑写进 PressureEncounterState：否。
是否有歧义：无。
```

---

## 步骤 12：补齐 BattleDebugScene 显示测试

修改文件：

```text
scripts/stm/tests/test_battle_debug_pressure_encounter_v1.gd
```

可选修改文件：

```text
scripts/stm/scenes/battle_debug_scene.gd
```

测试目标：

```text
BattleDebugScene 能显示 pressure_encounter_choice。
ChoicePanel 能显示抓住 / 安抚 / 放弃 / 重新浮现等选项。
日志能显示 focus / working_memory / pressure / core progress / action tendency summary。
BattleDebugScene 不直接修改 PressureEncounterState。
```

歧义自检：

```text
是否新增独立 DebugScene：否。
是否让 BattleDebugScene 解析并修改 payload：否。
是否需要正式 UI 重做：否。
是否有歧义：无。
```

---

## 步骤 13：完整 GUT 验证

执行：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

通过标准：

```text
所有旧测试通过。
新增 Pressure Encounter v1 测试通过。
debug_fountain EventRoom 原有行为不回归。
默认地图相关测试不要求 debug_pressure_encounter 节点。
BattleDebugScene 原有战斗 / 事件显示不回归。
```

歧义自检：

```text
是否允许跳过失败测试：否。
是否允许忽略旧测试失败：否。
是否允许因为没有默认地图节点而失败：否，v1 不要求默认地图接入。
是否有歧义：无。
```

---

## 步骤 14：规格审查与代码质量审查

检查：

```text
是否只新增独立 PressureEncounterState。
是否 GameState 只保存 current_pressure_encounter 引用。
是否 EventRoom 只负责启动，不保存全部玩法状态。
是否 ChoiceResolver 只转发，不维护规则。
是否 BattleDebugScene 只显示和提交，不直接改状态。
是否没有接入默认地图。
是否没有新增旧原型禁区命名。
是否没有新增第二套运行时主干。
是否没有把情绪牌做成纯负面 debuff。
是否固定自动结算管线存在并可测试。
```

歧义自检：

```text
是否发现架构偏离后继续验收：否，必须先修。
是否有歧义：无。
```

---

## 步骤 15：更新 status 文档

如果完整 GUT 通过，新增：

```text
docs/superpowers/status/2026-06-04-pressure-encounter-v1-status.md
```

status 至少记录：

```text
已实现内容
未实现内容
测试命令
测试结果
已知技术债
是否接入默认地图：否
下一阶段建议：v1.1 或 v2 再评估默认地图 / 专用调试地图接入
```

歧义自检：

```text
是否必须记录测试结果：是。
是否必须记录默认地图未接入：是。
是否必须记录技术债：是。
是否有歧义：无。
```
