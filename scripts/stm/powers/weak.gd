class_name StmWeakPower
extends StmPower


func _init(p_duration: int = 0) -> void:
	power_id = "weak"
	display_name = "虚弱"
	amount = 0
	duration = max(0, int(p_duration))
	stack_type = STACK_DURATION
	is_buff = false


func modify_damage_dealt(value: int, _target = null, _card = null) -> int:
	return int(floor(float(value) * 0.75))
