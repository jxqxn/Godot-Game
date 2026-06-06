# Python 参考项目架构规则

遇到架构、数据流、职责边界、卡牌或候选位置语义问题时，必须先参考 `slay-the-model-main/` 中的 Python 项目，再给出 Godot 侧方案。

处理顺序：

```text
1. 先说明 Python 项目的对应架构。
2. 再说明 Godot 项目的映射方案。
3. 如果 Godot 侧需要偏离 Python 架构，必须在规格中说明原因、边界和后续迁移方向。
```

当前默认映射：

```text
Python Card / registry
→ Godot encounter.candidate_definitions

Python CardManager.piles
→ Godot candidate_piles / candidate_stock / emergence_pool / working_memory / used_cards

Python card id / registered name
→ Godot stock_ids / stock_add_ids / candidate_id

Python action 产出意图，管理器处理位置流动
→ Godot auto_execution_events / pending_carryover 产出回流意图，下一 pressure_node 初始化时应用
```

这条规则是后续规格、计划、实现与审查的默认要求。
