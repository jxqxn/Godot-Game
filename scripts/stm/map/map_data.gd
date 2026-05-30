class_name StmMapData
extends RefCounted

# 固定 7 层测试地图。
# floors[i]["nodes"] 是 Array[Dictionary]，每个 node 包含 type 和 next_nodes。
# floors[i]["name"] 是楼层显示名。
# nodes[j]["type"]: "combat" | "rest" | "boss"。
# nodes[j]["next_nodes"]: Array[Dictionary]，每项包含 floor_index 和 node_index。
const FLOORS: Array = [
	{
		"name": "第 1 层",
		"nodes": [
			{"type": "combat", "next_nodes": [{"floor_index": 1, "node_index": 0}]}
		]
	},
	{
		"name": "第 2 层",
		"nodes": [
			{"type": "combat", "next_nodes": [{"floor_index": 2, "node_index": 0}]}
		]
	},
	{
		"name": "第 3 层",
		"nodes": [
			{"type": "combat", "next_nodes": [{"floor_index": 3, "node_index": 0}]}
		]
	},
	{
		"name": "第 4 层",
		"nodes": [
			{"type": "rest", "next_nodes": [
				{"floor_index": 4, "node_index": 0},
				{"floor_index": 4, "node_index": 1},
			]}
		]
	},
	{
		"name": "第 5 层",
		"nodes": [
			{"type": "combat", "next_nodes": [{"floor_index": 5, "node_index": 0}]},
			{"type": "rest", "next_nodes": [{"floor_index": 5, "node_index": 0}]},
		]
	},
	{
		"name": "第 6 层",
		"nodes": [
			{"type": "rest", "next_nodes": [{"floor_index": 6, "node_index": 0}]}
		]
	},
	{
		"name": "第 7 层",
		"nodes": [
			{"type": "boss", "next_nodes": []}
		]
	},
]
