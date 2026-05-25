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


func add_power(power) -> void:
	if power == null:
		return
	var power_id_text := _get_power_id_text(power)
	if power_id_text.is_empty():
		return
	var existing = get_power(power_id_text)
	if existing != null:
		existing.stack_with(power)
		existing.owner = self
		return
	power.owner = self
	powers.append(power)


func get_power(power_id_text: String):
	for power in powers:
		if power != null and _get_power_id_text(power) == power_id_text:
			return power
	return null


func has_power(power_id_text: String) -> bool:
	return get_power(power_id_text) != null


func remove_power(power_or_id) -> bool:
	var power_id_text := str(power_or_id)
	if typeof(power_or_id) == TYPE_OBJECT and power_or_id != null:
		var object_power_id := _get_power_id_text(power_or_id)
		if not object_power_id.is_empty():
			power_id_text = object_power_id
	for index in range(powers.size() - 1, -1, -1):
		var power = powers[index]
		if power != null and _get_power_id_text(power) == power_id_text:
			powers.remove_at(index)
			return true
	return false


func power_summary_text() -> String:
	_prune_expired_powers()
	if powers.is_empty():
		return "无"
	var parts := PackedStringArray()
	for power in powers:
		if power != null and power.has_method("summary_text"):
			parts.append(power.summary_text())
	if parts.is_empty():
		return "无"
	return ", ".join(parts)


func modify_damage_dealt(value: int, target = null, card = null) -> int:
	var modified: int = max(0, int(value))
	for power in powers:
		if power != null and power.has_method("modify_damage_dealt"):
			modified = max(0, int(power.modify_damage_dealt(modified, target, card)))
	return modified


func modify_damage_taken(value: int, source = null, card = null) -> int:
	var modified: int = max(0, int(value))
	for power in powers:
		if power != null and power.has_method("modify_damage_taken"):
			modified = max(0, int(power.modify_damage_taken(modified, source, card)))
	return modified


func modify_block_gained(value: int, source = null, card = null) -> int:
	var modified: int = max(0, int(value))
	for power in powers:
		if power != null and power.has_method("modify_block_gained"):
			modified = max(0, int(power.modify_block_gained(modified, source, card)))
	return modified


func notify_turn_start() -> void:
	for power in powers:
		if power != null and power.has_method("on_turn_start"):
			power.on_turn_start()
	_prune_expired_powers()


func notify_turn_end() -> void:
	for power in powers:
		if power != null and power.has_method("on_turn_end"):
			power.on_turn_end()
	_prune_expired_powers()


func _prune_expired_powers() -> void:
	for index in range(powers.size() - 1, -1, -1):
		var power = powers[index]
		if power == null:
			powers.remove_at(index)
		elif power.has_method("is_expired") and power.is_expired():
			powers.remove_at(index)


func _get_power_id_text(power) -> String:
	if power == null:
		return ""
	var value = power.get("power_id")
	if value == null:
		return ""
	return str(value)
