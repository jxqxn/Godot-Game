class_name StmStrike
extends StmCard

func _init() -> void:
	card_name = "打击"
	card_type = "attack"
	card_rarity = "starter"
	target_type = "enemy_select"
	cost = 1
	base_damage = 6
	upgrade_damage = 9
	reset_values()
