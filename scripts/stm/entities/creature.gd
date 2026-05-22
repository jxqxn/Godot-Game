class_name StmCreature
extends RefCounted

var _max_hp: int = 1
var _hp: int = 1
var _block: int = 0
var powers: Array = []

var max_hp: int:
	get:
		return _max_hp
	set(value):
		_max_hp = max(1, value)
		_hp = min(_hp, _max_hp)

var hp: int:
	get:
		return _hp
	set(value):
		_hp = clamp(value, 0, _max_hp)

var block: int:
	get:
		return _block
	set(value):
		_block = max(0, value)


func _init(initial_max_hp := 1) -> void:
	_max_hp = max(1, int(initial_max_hp))
	_hp = _max_hp
	_block = 0
	powers = []


func is_dead() -> bool:
	return _hp <= 0


func take_damage(amount, _source = null, _card = null) -> int:
	var incoming := max(0, int(amount))
	var blocked := min(_block, incoming)
	_block -= blocked
	var hp_loss := incoming - blocked
	if hp_loss > 0:
		_hp = max(0, _hp - hp_loss)
	return hp_loss


func heal(amount) -> int:
	var heal_amount := max(0, int(amount))
	var old_hp := _hp
	_hp = min(_max_hp, _hp + heal_amount)
	return _hp - old_hp


func gain_block(amount) -> int:
	var gain := max(0, int(amount))
	_block += gain
	return gain
