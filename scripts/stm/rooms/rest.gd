class_name StmRestRoom
extends StmRoom


func enter(game_state) -> void:
	super.enter(game_state)
	if game_state == null or game_state.player == null:
		is_completed = true
		return
	var player = game_state.player
	var heal_amount: int = int(float(player.max_hp) * 0.3)
	player.hp = min(player.max_hp, player.hp + heal_amount)
	is_completed = true


func get_room_type() -> String:
	return "rest"
