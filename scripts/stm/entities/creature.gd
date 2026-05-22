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
		_max_hp = int(max(1, value))
		_hp = int(min(_hp, _max_hp))

var hp: int:
	get:
		return _hp
	set(value):
		_hp = int(clamp(value, 0, _max_hp))

var block: int:
	get:
		return _block
	set(value):
		_block = int(max(0, value))


func _init(initial_max_hp: int = 1) -> void:
	_max_hp = int(max(1, int(initial_max_hp)))
	_hp = _max_hp
	_block = 0
	powers = []


func is_dead() -> bool:
	return _hp <= 0


func take_damage(amount, _source = null, _card = null) -> int:
	var incoming: int = max(0, int(amount))
	var blocked: int = min(_block, incoming)
	_block -= blocked
	var hp_loss: int = incoming - blocked
	if hp_loss > 0:
		_hp = int(max(0, _hp - hp_loss))
	return hp_loss


func heal(amount) -> int:
	var heal_amount: int = max(0, int(amount))
	var old_hp: int = _hp
	_hp = int(min(_max_hp, _hp + heal_amount))
	return _hp - old_hp


func gain_block(amount) -> int:
	var gain: int = max(0, int(amount))
	_block += gain
	return gain
