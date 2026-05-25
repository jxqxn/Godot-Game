class_name StmVulnerablePower
extends "res://scripts/stm/powers/power.gd"


func _init(p_duration: int = 0) -> void:
	power_id = "vulnerable"
	display_name = "易伤"
	amount = 0
	duration = max(0, int(p_duration))
	stack_type = STACK_DURATION
	is_buff = false


func modify_damage_taken(value: int, _source = null, _card = null) -> int:
	return int(floor(float(value) * 1.5))
