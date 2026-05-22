class_name StmPlayer
extends "res://scripts/stm/entities/creature.gd"

var card_manager: StmCardManager
var max_energy: int = 3
var energy: int = 3
var base_draw_count: int = 5
var gold: int = 99
var relics: Array = []
var potions: Array = []
var draw_count: int:
	get:
		return base_draw_count

func _init(deck: Array = []) -> void:
	super(70)
	card_manager = StmCardManager.new(deck)

func gain_energy(amount: int) -> void:
	energy = max(0, energy + amount)

func is_dead() -> bool:
	return super.is_dead()

func take_damage(amount, _source = null, _card = null) -> int:
	return super.take_damage(amount, _source, _card)

func gain_block(amount) -> int:
	return super.gain_block(amount)
