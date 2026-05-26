class_name StmCombatRoom
extends "res://scripts/stm/rooms/base.gd"

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")

var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	var fixture = FixedBattleFixtureScript.new()
	var context: Dictionary = fixture.create_context()
	if context.is_empty():
		return
	# 如果 game_state 已有 Player 则复用，否则用 fixture 创建的新 Player
	if game_state != null and game_state.player != null:
		_player = game_state.player
	else:
		_player = context["player"]
	_combat = context["combat"]
	_enemy = context["enemy"]
	if game_state != null:
		game_state.player = _player
		game_state.current_combat = _combat
	# 每次进入战斗房间重置牌堆
	if _player != null and _player.card_manager != null:
		_player.card_manager.reset_for_combat()
	_combat.start(game_state)


func leave(_game_state) -> void:
	_player = null
	_combat = null
	_enemy = null


func get_player():
	return _player


func get_combat():
	return _combat


func get_enemy():
	return _enemy


func get_room_type() -> String:
	return "combat"
