class_name StmFixedBattleFixture
extends RefCounted

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")

const FIXTURE_NAME := "基础测试战斗"
const COMBAT_TYPE := "debug"


func create_context() -> Dictionary:
	var player = create_player()
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_game(player)
	if game_state == null:
		return {}
	var enemy = create_enemy()
	var combat = create_combat(game_state, enemy)
	if combat == null:
		return {}
	return {
		"name": FIXTURE_NAME,
		"game_state": game_state,
		"combat": combat,
		"player": player,
		"enemy": enemy,
	}


func create_player():
	return PlayerScript.new(create_deck())


func create_enemy():
	return DummyEnemyScript.new()


func create_combat(game_state, enemy = null):
	if game_state == null:
		return null
	var combat_enemy = enemy if enemy != null else create_enemy()
	var bootstrap = GameBootstrapScript.new()
	return bootstrap.create_combat(game_state, [combat_enemy], COMBAT_TYPE)


func create_deck() -> Array:
	return [
		StrikeScript.new(),
		DefendScript.new(),
		StrikeScript.new(),
		DefendScript.new(),
		BashScript.new(),
		InflameScript.new(),
		ShrugItOffScript.new(),
	]
