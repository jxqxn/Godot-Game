# Disco Gunfight Cardification Reference

## 用途

本目录收纳一组外部案例机制参考，供后续在 ChatGPT 网站或本仓库中继续抽象、修正和迭代。

这些文档不是当前 Godot 项目的正式开发规格。若要把其中机制转入本项目，应先另写：

```text
docs/superpowers/specs/YYYY-MM-DD-xxx-design.md
docs/superpowers/plans/YYYY-MM-DD-xxx.md
```

并遵守仓库根目录 `AGENTS.md` 中的架构边界与开发红线。

## 文件索引

```text
minimal-cardification-spec.md
```

机制案例的完整参考规格。适合用来讨论状态、操作、压力节点、自动结算、可解释日志和验收标准。

```text
mda-loop-summary.md
```

同一机制的 MDA 视角总结。适合用来讨论 Mechanics / Dynamics / Aesthetics 之间的关系。

```text
machine-readable-spec.json
```

同一机制的机器可读摘要。适合给模型快速读取核心状态、非目标、玩家操作、结算顺序和验收点。

```text
originals/*.docx
```

原始 DOCX 附件。仓库内主要阅读与迭代入口仍是 Markdown 文件。

## 后续迭代建议

在 ChatGPT 网站继续修正时，建议先让模型只做以下任务之一：

```text
1. 抽象机制，不保留具体题材。
2. 用通俗游戏术语重写机制。
3. 提炼当前 Godot 项目的最小可实现切片。
4. 检查哪些概念会触碰 AGENTS.md 的旧原型禁区。
```

不要直接要求模型“照此实现”，否则容易把外部案例、当前项目方向和旧原型禁区混在一起。
