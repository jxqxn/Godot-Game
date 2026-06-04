# Reference Docs Curation 状态记录

## 对应规格与计划

本阶段是参考材料整理与上传，不是新玩法或结构性重构；未新增正式运行时行为，因此不单独创建 spec / plan。

## 当前阶段结论

已将根目录参考材料整理为正式仓库文档目录，便于后续在 GitHub / ChatGPT 网站中继续审阅和迭代。

## 完成内容

```text
1. 新增 docs/references/disco-gunfight-cardification/ 参考目录。
2. 将两份 Markdown 参考文档改为稳定英文文件名并加入文档元信息。
3. 将 JSON 参考规格复制为 machine-readable-spec.json。
4. 将两份 DOCX 原始附件归档到 originals/。
5. 新增目录 README，说明用途、边界与后续迭代方式。
```

## 修改文件

```text
docs/references/disco-gunfight-cardification/README.md
docs/references/disco-gunfight-cardification/minimal-cardification-spec.md
docs/references/disco-gunfight-cardification/mda-loop-summary.md
docs/references/disco-gunfight-cardification/machine-readable-spec.json
docs/references/disco-gunfight-cardification/originals/minimal-cardification-spec.docx
docs/references/disco-gunfight-cardification/originals/mda-loop-summary.docx
docs/superpowers/status/2026-06-04-reference-docs-curation-status.md
README.md
```

根目录原始参考文件未删除。

## 测试结果

本阶段未修改 Godot 运行时代码，未重新运行完整 GUT。已做文档文件存在性检查、Markdown 关键字段检查与 `git diff --check`。

## 规格审查结论

```text
不新增玩法规则：通过
不修改 Godot 运行时：通过
不把外部案例冒充当前项目规格：通过
保留 ChatGPT 网站可读 Markdown 入口：通过
保留原始 DOCX 附件：通过
```

## 代码质量审查结论

```text
参考材料放入 docs/references/ 独立目录：通过
文件名稳定且适合 GitHub 链接：通过
Markdown 顶部说明用途和使用边界：通过
未引入运行时依赖：通过
```

## 已知技术债

```text
暂无本阶段新增已知技术债。
```

## 下一步建议

```text
1. 在 ChatGPT 网站基于 docs/references/disco-gunfight-cardification/README.md 继续修正机制理解。
2. 修正完成后，再把机制抽象为当前项目自己的正式规格。
3. 转入实现前，仍需另写 docs/superpowers/specs/ 与 docs/superpowers/plans/。
```
