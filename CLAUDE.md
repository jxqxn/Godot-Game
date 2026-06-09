# CLAUDE.md

本文件是 Claude Code 进入本仓库时的入口。项目事实与流程规则仍以 `AGENTS.md`、`README.md` 和最新 `docs/superpowers/status/` 为准。

## 读取顺序

1. 先读 `AGENTS.md`。
2. 再读 `README.md`。
3. 如果要接入新功能或结构调整，读取最新 `docs/superpowers/specs/`、`docs/superpowers/plans/`、`docs/superpowers/status/`。
4. 如果要运行 GodotMaker，先读 `docs/integrations/godotmaker.md`。

## 项目规则

- 使用中文交流；代码注释也使用中文。
- 新功能或结构性重构继续遵守“先规格、再计划、再实现”。
- 正式代码前先写 Given-When-Then 行为注释和 GUT 测试方法名。
- 不要绕过 `StmGameState` / `StmChoiceResolver` / `StmGameFlow` / `StmRoomFactory` 等主干边界。
- 不要修改 `project.godot`、`StmTypes.TerminalResult`、`StmCard.can_play(game_state)` bool 语义或 Python 参考项目，除非用户明确批准。
- 合并前重新运行完整 GUT：`godot -s addons/gut/gut_cmdln.gd`。

## GodotMaker

- GodotMaker 在本仓库中只作为本地工作流层，不是 Godot runtime addon。
- `.godotmaker/config.yaml` 是可提交的项目配置，当前默认 `agent: claude-code`。
- `.claude/godotmaker.yaml` 是主机私有路径配置，不提交；从 `.claude/godotmaker.yaml.example` 复制。
- 如果运行 GodotMaker 的发布脚本或 CLI，先检查 `git diff`，确认没有覆盖本项目的 `AGENTS.md`、`README.md` 或玩法主干文件。
- Codex 继续读取 `AGENTS.md`；不要用 GodotMaker 的 Codex 发布流程替换本项目现有协作规则。
