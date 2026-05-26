class_name StmCombatRoom
extends "res://scripts/stm/rooms/base.gd"

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	if game_state == null:
		return
	var fixture = FixedBattleFixtureScript.new()
	if game_state.player == null:
		game_state.player = fixture.create_player()
	_player = game_state.player
	_enemy = fixture.create_enemy()
	_combat = fixture.create_combat(game_state, _enemy)
	if _combat == null:
		return
	game_state.current_combat = _combat
	# Combat.start() 是唯一的战斗初始化入口，避免重复 reset 牌堆和推进随机状态。
	_combat.start(game_state)


func leave(_game_state) -> void:
	_player = null
	_combat = null
	_enemy = null


func handle_combat_result(result: int, game_state) -> void:
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		complete(game_state)


func get_player():
	return _player


func get_combat():
	return _combat


func get_enemy():
	return _enemy


func get_room_type() -> String:
	return "combat"
