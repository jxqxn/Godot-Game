class_name StmBash
extends StmCard

const VulnerableScript := preload("res://scripts/stm/powers/vulnerable.gd")


func _init() -> void:
	card_name = "痛击"
	card_type = "attack"
	card_rarity = "starter"
	target_type = "enemy_select"
	cost = 2
	play_priority = 20
	base_damage = 8
	base_magic = 2
	upgrade_damage = 10
	upgrade_magic = 3
	reset_values()


func on_play(game_state, targets := []) -> Array:
	var actions := super.on_play(game_state, targets)
	if targets.size() > 0:
		actions.append(StmCombatActions.ApplyPowerAction.new(targets[0], VulnerableScript.new(magic)))
	return actions
