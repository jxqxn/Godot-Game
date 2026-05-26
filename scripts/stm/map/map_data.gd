class_name StmMapData
extends RefCounted

# 固定 7 层测试地图
# floors[i]["rooms"] 是 Array[Dictionary]，每个 room 包含 type 和 next_floors
# floors[i]["name"] 是楼层显示名
# rooms[j]["type"]: "combat" | "rest" | "boss"
# rooms[j]["next_floors"]: Array[int]，指向下一层索引（空数组表示最终层）
const FLOORS: Array = [
	{
		"name": "第 1 层",
		"rooms": [
			{"type": "combat", "next_floors": [1]}
		]
	},
	{
		"name": "第 2 层",
		"rooms": [
			{"type": "combat", "next_floors": [2]}
		]
	},
	{
		"name": "第 3 层",
		"rooms": [
			{"type": "combat", "next_floors": [3]}
		]
	},
	{
		"name": "第 4 层",
		"rooms": [
			{"type": "rest", "next_floors": [4]}
		]
	},
	{
		"name": "第 5 层",
		"rooms": [
			{"type": "combat", "next_floors": [5]},
			{"type": "rest", "next_floors": [5]}
		]
	},
	{
		"name": "第 6 层",
		"rooms": [
			{"type": "rest", "next_floors": [6]}
		]
	},
	{
		"name": "第 7 层",
		"rooms": [
			{"type": "boss", "next_floors": []}
		]
	},
]
