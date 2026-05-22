extends RefCounted

var enemy_name: String
var enemy_type: String = ""
var current_intention: String = ""
var intent_damage: int = 0
var max_hp: int = 1
var hp: int = 1
var block: int = 0
var powers: Array = []

func _init(initial_max_hp: int = 1, initial_name: String = "Enemy", initial_damage: int = 0) -> void:
	max_hp = max(1, int(initial_max_hp))
	hp = max_hp
	block = 0
	powers = []
	enemy_name = initial_name
	intent_damage = initial_damage
	current_intention = "attack"

func determine_next_intention() -> String:
	current_intention = "attack"
	return current_intention

func execute_intention(_game_state, _combat) -> Array:
	return []

func is_dead() -> bool:
	return hp <= 0

func take_damage(amount, _source = null, _card = null) -> int:
	var incoming: int = max(0, int(amount))
	var blocked: int = min(block, incoming)
	block -= blocked
	var hp_loss: int = incoming - blocked
	if hp_loss > 0:
		hp = max(0, hp - hp_loss)
	return hp_loss
