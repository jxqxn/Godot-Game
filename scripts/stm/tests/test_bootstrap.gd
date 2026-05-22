class_name StmTestBootstrap
extends RefCounted

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")


func create_test_game():
	var deck: Array = [StrikeScript.new(), DefendScript.new(), StrikeScript.new(), DefendScript.new()]
	var player = PlayerScript.new(deck)
	var bootstrap = GameBootstrapScript.new()
	return bootstrap.create_game(player)


func create_test_combat(game_state):
	var enemy = DummyEnemyScript.new()
	var bootstrap = GameBootstrapScript.new()
	return bootstrap.create_combat(game_state, [enemy], "normal")
