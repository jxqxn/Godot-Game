# GodotMaker 集成说明

本文记录本项目与 [GodotMaker](https://github.com/RandallLiuXin/GodotMaker) 的兼容配置。GodotMaker 是本地优先的工作流层，不是 Godot 插件，也不应放进 `addons/` 或作为运行时依赖。

## 当前仓库配置

已提交的项目级配置：

```text
.godotmaker/config.yaml
.claude/godotmaker.yaml.example
.worktreeinclude
CLAUDE.md
```

当前默认策略：

```text
GodotMaker 主执行器：Claude Code
视觉 QA 主模型：active runtime native
视觉 QA 备用：Codex
图片生成：Codex
视频生成：关闭
```

这让 Claude Code 可以作为 GodotMaker 主流程执行器，同时保留 Codex 参与视觉检查或图片生成的入口。若本机没有 Codex CLI，可先把 `.godotmaker/config.yaml` 中的 `asset_image_model` 改为 `native` 或显式 API provider。

## 本机首次使用

1. 安装 GodotMaker 前置工具：Godot 4.5+、Node.js 18+、Python 3.10+、Git，以及 Claude Code 或 Codex。
2. 安装 CLI：`npm install -g godotmaker-cli`。
3. 复制 `.claude/godotmaker.yaml.example` 为 `.claude/godotmaker.yaml`。
4. 把 `godot_path` 改成本机 Godot 可执行文件路径；如果 `godot` 已在 PATH，可保留为 `"godot"`。
5. 需要完整 `/gm-*` 工作流时，再运行 `godotmaker` 或从 GodotMaker 仓库执行 `python tools/publish.py --agent claude-code <本项目路径>`。

## 兼容边界

- 不把 GodotMaker 源码作为 submodule 或 vendored dependency 提交进本仓库。
- 不把 GodotMaker 当作 `addons/` 插件接入。
- 不让 GodotMaker 自动发布流程覆盖本项目的 `AGENTS.md`；该文件是 Codex 与人工协作的主规则源。
- 不让 GodotMaker 生成的流程模板替代 `docs/superpowers/specs/`、`docs/superpowers/plans/`、`docs/superpowers/status/`。
- 不让 GodotMaker hooks 或 role lock 绕过本项目既有 BDD/TDD/GUT 流程。

## Claude Code 注意事项

Claude Code 入口是根目录 `CLAUDE.md`，它会要求先读 `AGENTS.md` 和 `README.md`。

`.claude/godotmaker.yaml` 包含本机路径，不提交。`.worktreeinclude` 允许 Claude Code 的 worktree 子 agent 继承 `.claude/`，否则 GodotMaker 子任务可能找不到 Godot 路径或已发布的 `/gm-*` skill。

如果运行 GodotMaker 发布脚本，它可能生成 `.claude/skills/`、`.claude/agents/`、`.claude/config/`、`.godotmaker/hooks/`、`tools/` 等框架托管内容。提交前必须先审查 diff，确认这些文件不会覆盖本项目主规则或玩法边界。

## Codex 注意事项

Codex 仍以 `AGENTS.md` 为项目规则入口。GodotMaker 的 Codex 发布适配层会使用 `.agents/` 并可能把 `AGENTS.md` 当作根指令文件名；本项目已有自己的 `AGENTS.md`，因此启用 GodotMaker Codex 发布前要单独审查，不能直接强制覆盖。

当前 `.godotmaker/config.yaml` 只把 Codex 作为视觉 QA 备用与图片生成提供者。若后续要让 GodotMaker 主流程切到 Codex，应先写新的集成规格或至少更新本文，并确认不会破坏现有 Codex 项目 skill、prompt 和 GUT 流程。

## 升级检查清单

升级 GodotMaker 或重新运行发布脚本后，至少检查：

```text
git status --short
git diff -- AGENTS.md README.md CLAUDE.md .gitignore .godotmaker/config.yaml
godot -s addons/gut/gut_cmdln.gd
```

如果 GodotMaker 生成大量框架文件，建议单独开分支提交，并在 PR 描述中说明是工具层配置，不是玩法实现。
