class_name StmEnemy
extends "res://scripts/stm/entities/creature.gd"

var enemy_name: String
var enemy_type: String = ""
var current_intention: String = ""
var intent_damage: int = 0
func _init(initial_max_hp: int = 1, initial_name: String = "Enemy", initial_damage: int = 0) -> void:
	super(max(1, int(initial_max_hp)))
	enemy_name = initial_name
	intent_damage = initial_damage
	current_intention = "attack"

func determine_next_intention() -> String:
	current_intention = "attack"
	return current_intention

func execute_intention(_game_state, _combat) -> Array:
	return []

func is_dead() -> bool:
	return super.is_dead()

func take_damage(amount, _source = null, _card = null) -> int:
	return super.take_damage(amount, _source, _card)
