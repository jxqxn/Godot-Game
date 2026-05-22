class_name StmDummyEnemy
extends "res://scripts/stm/enemies/enemy.gd"

func _init() -> void:
	super(20, "DummyEnemy", 6)
	intent_damage = 6

func execute_intention(_game_state, _combat) -> Array:
	return [StmCombatActions.EnemyAttackAction.new(self, _game_state.player, intent_damage)]
