# 新功能 Intake Prompt

用于开始新功能、玩法扩展或结构性重构前。目标是在写正式代码前，把范围、边界和测试切片说清楚。

```text
请先按本项目 AGENTS.md / README.md / 最新 status 进入上下文，不要直接实现。

本次想推进的内容是：
[一句话目标]

请先输出一个 intake 判断，包含：

1. 任务类型
   - 新玩法 / 结构重构 / 调试工具 / 测试清理 / 文档维护 / 其他

2. 是否需要规格与计划
   - 若是新功能或结构性重构，先给出应创建的 spec / plan 文件名。
   - 若不是，说明为什么可以直接走最小 TDD 或文档更新。

3. 主干接入点
   - 会经过哪些现有边界：Room / ChoiceRequest / GameState.submit_choice() / ChoiceResolver / GameFlow / RoomFactory / EncounterFactory / BattleDebugScene。
   - 明确哪些规则不能写进 UI。

4. 非目标
   - 本轮明确不做什么，防止范围膨胀。

5. BDD/TDD 切片
   - 先写哪一个测试方法。
   - Given / When / Then 行为注释要表达什么。
   - 第一条预期失败是什么。

6. 风险与红线
   - 是否触碰 project.godot、StmTypes.TerminalResult、StmCard.can_play(game_state) bool 语义、Python 参考项目。
   - 是否可能引入平行系统或恢复 will/mind 旧原型。

7. 验证与文档
   - 目标测试命令。
   - 完整 GUT 命令。
   - 完成后应更新哪些 README / AGENTS / status 文档。

在 intake 完成前，不要修改正式代码。
```
