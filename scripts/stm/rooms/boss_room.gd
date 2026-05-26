class_name StmBossRoom
extends StmCombatRoom

const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")


func enter(game_state) -> void:
	is_completed = false
	if game_state == null or game_state.player == null:
		return
	_player = game_state.player
	_enemy = EnemyScript.new(40, "BossEnemy", 12)
	var combat_script = load("res://scripts/stm/engine/combat.gd")
	if combat_script != null:
		_combat = combat_script.new([_enemy], "boss")
	game_state.player = _player
	game_state.current_combat = _combat
	# Combat.start() 是唯一的战斗初始化入口，避免重复 reset 牌堆和推进随机状态。
	if _combat != null:
		_combat.start(game_state)


func get_room_type() -> String:
	return "boss"
