class_name StmBossRoom
extends StmCombatRoom

const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func enter(game_state) -> void:
	super.enter(null)
	_start_combat_with_enemy(game_state, EnemyScript.new(40, "BossEnemy", 12), "boss")


func handle_combat_result(result: int, game_state) -> void:
	if result != TypesScript.TerminalResult.COMBAT_WIN:
		return
	if game_state == null:
		return
	if is_completed:
		return
	complete(game_state)


func get_room_type() -> String:
	return "boss"
