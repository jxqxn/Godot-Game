class_name StmDefend
extends StmCard

func _init() -> void:
	card_name = "防御"
	card_type = "skill"
	card_rarity = "starter"
	target_type = "self"
	cost = 1
	play_priority = 5
	base_block = 5
	upgrade_block = 8
	reset_values()
