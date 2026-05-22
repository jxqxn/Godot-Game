extends RefCounted

var card_manager: StmCardManager
var max_energy: int = 3
var energy: int = 3
var base_draw_count: int = 5
var gold: int = 99
var relics: Array = []
var potions: Array = []
var max_hp: int = 70
var hp: int = 70
var block: int = 0
var powers: Array = []

var draw_count: int:
	get:
		return base_draw_count

func _init(deck: Array = []) -> void:
	max_hp = 70
	hp = 70
	block = 0
	powers = []
	card_manager = StmCardManager.new(deck)

func gain_energy(amount: int) -> void:
	energy = max(0, energy + amount)

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

func gain_block(amount) -> int:
	var gain: int = max(0, int(amount))
	block += gain
	return gain
