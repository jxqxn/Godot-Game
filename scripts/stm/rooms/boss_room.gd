class_name StmBossRoom
extends StmCombatRoom

const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")


func enter(game_state) -> void:
	is_completed = false
	if game_state == null or game_state.player == null:
		return
	_player = game_state.player
	var boss_enemy = EnemyScript.new(40, "BossEnemy", 12)
	var combat_script = load("res://scripts/stm/engine/combat.gd")
	if combat_script != null:
		_combat = combat_script.new([boss_enemy], "boss")
	_enemy = boss_enemy
	game_state.player = _player
	game_state.current_combat = _combat
	# 每次进入 Boss 房间重置牌堆
	if _player != null and _player.card_manager != null:
		_player.card_manager.reset_for_combat()
	if _combat != null:
		_combat.start(game_state)


func get_room_type() -> String:
	return "boss"
