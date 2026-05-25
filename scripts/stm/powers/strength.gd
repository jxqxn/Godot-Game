class_name StmStrengthPower
extends "res://scripts/stm/powers/power.gd"


func _init(p_amount: int = 0) -> void:
	power_id = "strength"
	display_name = "力量"
	amount = max(0, int(p_amount))
	duration = -1
	stack_type = STACK_INTENSITY
	is_buff = true


func modify_damage_dealt(value: int, _target = null, _card = null) -> int:
	return int(value) + amount
