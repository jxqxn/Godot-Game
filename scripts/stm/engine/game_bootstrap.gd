class_name StmGameBootstrap
extends RefCounted

const GAME_STATE_PATH := "res://scripts/stm/engine/game_state.gd"
const COMBAT_PATH := "res://scripts/stm/engine/combat.gd"


func create_game(player):
	var game_state_script = load(GAME_STATE_PATH)
	if game_state_script == null:
		return null
	return game_state_script.new(player)


func create_combat(game_state, enemies: Array = [], combat_type: String = "normal"):
	var combat_script = load(COMBAT_PATH)
	if combat_script == null:
		return null
	var combat = combat_script.new(enemies, combat_type)
	game_state.current_combat = combat
	return combat
