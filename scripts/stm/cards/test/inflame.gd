class_name StmInflame
extends StmCard

const StrengthScript := preload("res://scripts/stm/powers/strength.gd")


func _init() -> void:
	card_name = "燃烧"
	card_type = "power"
	card_rarity = "uncommon"
	target_type = "self"
	cost = 1
	play_priority = 30
	base_magic = 2
	upgrade_magic = 3
	reset_values()


func on_play(game_state, _targets := []) -> Array:
	if game_state == null or game_state.player == null:
		return []
	return [StmCombatActions.ApplyPowerAction.new(game_state.player, StrengthScript.new(magic))]
