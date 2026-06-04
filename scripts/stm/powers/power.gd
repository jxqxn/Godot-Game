class_name StmPower
extends RefCounted

const STACK_INTENSITY := "intensity"
const STACK_DURATION := "duration"

var power_id: String = ""
var display_name: String = ""
var amount: int = 0
var duration: int = -1
var stack_type: String = STACK_INTENSITY
var is_buff: bool = false
var _owner_ref: WeakRef = null
var owner:
	get:
		if _owner_ref == null:
			return null
		return _owner_ref.get_ref()
	set(value):
		if value == null:
			_owner_ref = null
			return
		var next_owner_ref: WeakRef = weakref(value)
		_owner_ref = next_owner_ref


func _init(p_amount: int = 0, p_duration: int = -1) -> void:
	amount = int(p_amount)
	duration = int(p_duration)


func stack_with(other) -> void:
	if other == null:
		return
	if stack_type == STACK_DURATION:
		duration = max(0, duration) + max(0, int(other.duration))
		return
	amount += int(other.amount)


func modify_damage_dealt(value: int, _target = null, _card = null) -> int:
	return value


func modify_damage_taken(value: int, _source = null, _card = null) -> int:
	return value


func modify_block_gained(value: int, _source = null, _card = null) -> int:
	return value


func on_turn_start() -> void:
	pass


func on_turn_end() -> void:
	if duration > 0:
		duration -= 1


func is_expired() -> bool:
	return duration == 0


func summary_text() -> String:
	var visible_value := amount
	if stack_type == STACK_DURATION:
		visible_value = duration
	return "%s %d" % [display_name, visible_value]
