class_name StmBossRoom
extends StmCombatRoom

const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")


func enter(game_state) -> void:
	super.enter(null)
	_start_combat_with_enemy(game_state, EnemyScript.new(40, "BossEnemy", 12), "boss")


func get_room_type() -> String:
	return "boss"
