extends RefCounted

var enemy_name: String = "DummyEnemy"
var enemy_type: String = ""
var current_intention: String = "attack"
var intent_damage: int = 6
var max_hp: int = 20
var hp: int = 20
var block: int = 0

func _init() -> void:
	max_hp = 20
	hp = 20
	block = 0
	intent_damage = 6

func execute_intention(_game_state, _combat) -> Array:
	return [StmCombatActions.EnemyAttackAction.new(self, _game_state.player, intent_damage)]

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
