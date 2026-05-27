class_name StmShrugItOff
extends StmCard


func _init() -> void:
	card_name = "耸肩无视"
	card_type = "skill"
	card_rarity = "common"
	target_type = "self"
	cost = 1
	play_priority = 15
	base_block = 8
	base_magic = 1
	upgrade_block = 11
	reset_values()


func on_play(game_state, targets := []) -> Array:
	var actions := super.on_play(game_state, targets)
	if game_state != null and game_state.player != null:
		actions.append(StmCombatActions.DrawCardsAction.new(game_state.player, magic))
	return actions
