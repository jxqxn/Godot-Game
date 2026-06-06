# Pressure Encounter v1.1 状态记录

## 对应规格与计划

```text
docs/superpowers/specs/2026-06-06-pressure-encounter-v1-1-quality-review.md
docs/superpowers/plans/2026-06-06-pressure-encounter-v1-1-plan.md
```

## 当前阶段结论

Pressure Encounter v1.1 最小机制质量切片已完成，并通过完整 GUT。本阶段继续不接入默认地图，只强化 v1 压力遭遇内部的候选库存、操作语义、成果率和自动执行过程。

## 完成内容

```text
1. 新增 candidate_stock / candidate_piles，候选在 stock / emergence_pool / working_memory / used / discarded 之间移动。
2. refresh 支持固定 seed 与 refresh_page_size，改为从有限 stock 受控抽取候选页。
3. grasp 只让候选离开 stock 并进入 working_memory；普通观察卡不再 grasp 即触发强数值，emotion 保留即时污染。
4. discard 只作用于 working_memory，并让候选回到 stock。
5. keep 不消耗 focus，继续占用 working_memory，并可带入下一压力节点。
6. express 后候选进入 used，不回当前 stock。
7. 自动执行阶段生成 locked_auto_execution_snapshot / dominant_action / outcome_rate。
8. 自动执行生成 auto_execution_events / final_consequence / value_summary。
9. auto_execution_events 使用可扩展事件结构，包含 objective_progress / relationship_synergy / emotion_interference / cost_or_setup 等基础类型。
10. 更新 BattleDebugScene 测试，使放弃操作只在候选进入 working_memory 后出现。
```

## 修改文件

```text
.gutconfig.json
AGENTS.md
README.md
scripts/stm/encounters/pressure/pressure_encounter_state.gd
scripts/stm/tests/test_pressure_encounter_v1.gd
scripts/stm/tests/test_pressure_encounter_v1_1.gd
scripts/stm/tests/test_battle_debug_pressure_encounter_v1.gd
docs/superpowers/status/2026-06-06-pressure-encounter-v1-1-status.md
```

## 测试结果

完整测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd "-gjunit_xml_file=$resultPath" -gexit -glog=1
```

结果：

```text
Scripts: 31
Tests: 234
Passing Tests: 234
Failures: 0
Errors: 0
Asserts: 1179
```

完整 GUT 干净退出。未观察到 ObjectDB / resources still in use 警告。

## 规格审查结论

```text
是否符合规格目标：是，已实现候选库存、受控 refresh、操作语义修正、dominant_action、outcome_rate、auto_execution_events、final_consequence 与 value_summary。
是否越过非目标范围：否，未接入默认地图，未新增 DebugScene、PressureEncounterFactory、current_encounter 泛化、phase scheduler 或更多局势轨。
是否改变既有玩家可见行为：有意改变 Pressure Encounter 内部调试原型行为；未 grasp 的浮现候选不再显示 discard，普通观察卡 grasp 不再立即给强数值，keep 不再消耗 focus。旧战斗、休息、事件、地图主干测试保持通过。
是否触碰明确禁区：否，未修改 project.godot、StmTypes.TerminalResult、StmCard.can_play(game_state) 语义或 Python 参考项目。
```

## 代码质量审查结论

```text
是否复用现有主干边界：是，仍走 EventRoom -> ChoiceRequest -> GameState.submit_choice() -> ChoiceResolver -> Room 完成路径。
是否引入平行系统：否，未新增第二套 GameState / GameFlow / ChoiceRequest / DebugScene。
是否把正式规则写进 UI：否，BattleDebugScene 只显示 ChoiceRequest 与 choice_result 日志，规则仍在 PressureEncounterState。
是否存在测试替身或 debug 入口污染正式路径：否，新增测试直接构造 PressureEncounterState 或复用现有 debug map 注入能力。
```

## 已知技术债

```text
1. refresh 的受控随机为轻量稳定排序算法，不是完整 RNG/权重池。
2. outcome_rate 公式仍是 v1.1 可测默认值，尚未做平衡验证。
3. auto_execution_events 只有最小事件流，尚未实现复杂触发、站位、伤害、成长或多轮循环。
4. next_round_delta 目前只记录在 value_summary / 事件中，尚未应用到后续遭遇。
```

## 下一步建议

```text
1. 做 v1.2 规格：评估是否把 next_round_delta 安全应用到下一压力节点。
2. 设计专用调试状态面板，显示 stock / working_memory / outcome_rate / auto_execution_events，但继续保持 UI 不写规则。
3. 等机制稳定后，再评估是否接入默认地图或增加专用调试地图入口。
```
