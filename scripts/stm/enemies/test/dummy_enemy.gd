class_name StmDummyEnemy
extends StmEnemy

func _init() -> void:
	super(20, "DummyEnemy", 6)

func execute_intention(_game_state, _combat) -> Array:
	return [StmCombatActions.EnemyAttackAction.new(self, intent_damage)]
