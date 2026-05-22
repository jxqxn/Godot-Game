class_name StmCombatState
extends RefCounted

var combat_turn: int = 0
var turn_cards_played: int = 0
var player_energy_spent_this_turn: int = 0
var current_phase: String = "not_started"


func reset_combat_info() -> void:
	combat_turn = 0
	reset_turn_info()
	current_phase = "not_started"


func reset_turn_info() -> void:
	turn_cards_played = 0
	player_energy_spent_this_turn = 0
