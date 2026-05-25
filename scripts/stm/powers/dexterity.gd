class_name StmDexterityPower
extends "res://scripts/stm/powers/power.gd"


func _init(p_amount: int = 0) -> void:
	power_id = "dexterity"
	display_name = "敏捷"
	amount = max(0, int(p_amount))
	duration = -1
	stack_type = STACK_INTENSITY
	is_buff = true


func modify_block_gained(value: int, _source = null, _card = null) -> int:
	return int(value) + amount
