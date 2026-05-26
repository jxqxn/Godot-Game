class_name StmRestRoom
extends StmRoom

var last_hp_before: int = 0
var last_hp_after: int = 0
var last_heal_amount: int = 0


func enter(game_state) -> void:
	super.enter(game_state)
	last_hp_before = 0
	last_hp_after = 0
	last_heal_amount = 0
	if game_state == null or game_state.player == null:
		is_completed = true
		return
	var player = game_state.player
	last_hp_before = int(player.hp)
	var heal_amount: int = int(float(player.max_hp) * 0.3)
	player.hp = min(player.max_hp, player.hp + heal_amount)
	last_hp_after = int(player.hp)
	last_heal_amount = max(0, last_hp_after - last_hp_before)
	is_completed = true


func get_room_type() -> String:
	return "rest"
