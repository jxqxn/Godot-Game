# <阶段名> 状态记录

## 对应规格与计划

```text
docs/superpowers/specs/YYYY-MM-DD-xxx-design.md
docs/superpowers/plans/YYYY-MM-DD-xxx.md
```

如果本阶段不是新功能或结构性重构，请说明为何不需要规格与计划。

## 当前阶段结论

简述本阶段是否完成、是否通过验证、是否仍有阻塞。

## 完成内容

```text
1. <完成项>
2. <完成项>
3. <完成项>
```

## 修改文件

```text
path/to/file.gd
path/to/test.gd
README.md
AGENTS.md
```

## 测试结果

完整测试命令：

```powershell
godot -s addons/gut/gut_cmdln.gd
```

结果：

```text
Scripts:
Tests:
Passing Tests:
Asserts:
```

记录是否干净退出，尤其是是否出现 ObjectDB / resources still in use 警告。

## 规格审查结论

```text
是否符合规格目标：
是否越过非目标范围：
是否改变既有玩家可见行为：
是否触碰明确禁区：
```

## 代码质量审查结论

```text
是否复用现有主干边界：
是否引入平行系统：
是否把正式规则写进 UI：
是否存在测试替身或 debug 入口污染正式路径：
```

## 已知技术债

```text
1. <技术债>
2. <技术债>
```

若无，请写“暂无本阶段新增已知技术债”。

## 下一步建议

```text
1. <建议>
2. <建议>
3. <建议>
```
