class_name StmFixedBattleFixture
extends RefCounted

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")

const FIXTURE_NAME := "基础测试战斗"
const COMBAT_TYPE := "debug"


func create_context() -> Dictionary:
	var deck: Array = create_deck()
	var player = PlayerScript.new(deck)
	var enemy = DummyEnemyScript.new()
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_game(player)
	if game_state == null:
		return {}
	var combat = bootstrap.create_combat(game_state, [enemy], COMBAT_TYPE)
	if combat == null:
		return {}
	return {
		"name": FIXTURE_NAME,
		"game_state": game_state,
		"combat": combat,
		"player": player,
		"enemy": enemy,
	}


func create_deck() -> Array:
	return [
		StrikeScript.new(),
		DefendScript.new(),
		StrikeScript.new(),
		DefendScript.new(),
	]
