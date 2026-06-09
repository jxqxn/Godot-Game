# GodotMaker / Claude Code 兼容配置状态

日期：2026-06-09

分支：`codex/godotmaker-config`

## 完成内容

- 从最新 `origin/main` 新建独立配置分支，避免叠加到压力遭遇实现分支。
- 新增 `.godotmaker/config.yaml`，默认使用 `agent: claude-code`，并保留 Codex 作为视觉 QA 备用与图片生成入口。
- 新增 `.claude/godotmaker.yaml.example`，真实 `.claude/godotmaker.yaml` 作为本机路径配置保留在本地。
- 新增 `CLAUDE.md`，让 Claude Code 进入仓库后先回到本项目 `AGENTS.md` / `README.md` 规则。
- 新增 `.worktreeinclude`，让 Claude Code worktree 子 agent 可以继承本机 `.claude/` 配置。
- 新增 `docs/integrations/godotmaker.md`，记录 GodotMaker 作为工作流层的边界、首次使用步骤、Codex/Claude Code 兼容注意事项。
- 更新 `.gitignore`、`AGENTS.md`、`README.md`，同步 GodotMaker 配置入口和本地状态忽略规则。

## 验证结果

完整 GUT 已通过：

```text
Scripts: 31
Tests: 235
Passing Tests: 235
Failures: 0
Errors: 0
Asserts: 1182
```

## 规格审查

- 符合本次目标：只配置 GodotMaker / Claude Code / Codex 协作入口，没有新增玩法规则。
- 未把 GodotMaker 放进 `addons/`、submodule 或 Godot runtime。
- 未修改 `project.godot`、玩法脚本、测试脚本或 Python 参考项目。
- 保留 `AGENTS.md` 作为 Codex 与人工协作主规则源，避免 GodotMaker Codex 发布流程覆盖。

## 代码质量审查

- `.godotmaker/config.yaml` 是可提交项目配置；`.claude/godotmaker.yaml` 被忽略，example 被追踪。
- `.worktreeinclude` 只负责 Claude Code worktree 继承，不改变 Git/Godot 运行时行为。
- 文档明确了后续运行 GodotMaker 发布脚本前必须审查 diff，尤其是 `AGENTS.md`、`README.md`、`.claude/`、`.godotmaker/` 与 `tools/`。

## 已知技术债

- 尚未运行 GodotMaker CLI 或 `tools/publish.py`，因此没有提交 `.claude/skills/`、`.godotmaker/hooks/`、`tools/` 等框架托管内容。
- 若后续要让 GodotMaker 主流程切换到 Codex，需要单独审查 `.agents/` 适配层与 `AGENTS.md` 覆盖风险。

## 下一步建议

- 在本机复制 `.claude/godotmaker.yaml.example` 为 `.claude/godotmaker.yaml`，填入实际 Godot 路径。
- 需要完整 GodotMaker `/gm-*` 工作流时，在单独分支运行发布或 CLI 初始化，并审查生成文件后再提交。
