class_name StmBossRoom
extends "res://scripts/stm/rooms/base.gd"

const CombatScript := preload("res://scripts/stm/engine/combat.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	_start_boss_combat(game_state)


func leave(_game_state) -> void:
	_player = null
	_combat = null
	_enemy = null


func handle_combat_result(result: int, game_state) -> void:
	if result != TypesScript.TerminalResult.COMBAT_WIN:
		return
	if game_state == null:
		return
	if is_completed:
		return
	complete(game_state)


func get_player():
	return _player


func get_combat():
	return _combat


func get_enemy():
	return _enemy


func get_room_type() -> String:
	return "boss"


func _start_boss_combat(game_state) -> bool:
	if game_state == null:
		return false
	var fixture = FixedBattleFixtureScript.new()
	if game_state.player == null:
		game_state.player = fixture.create_player()
	else:
		_ensure_player_has_fixture_deck(game_state.player, fixture)
	_player = game_state.player
	_enemy = EnemyScript.new(40, "BossEnemy", 12)
	_combat = CombatScript.new([_enemy], "boss")
	if _combat == null:
		return false
	game_state.current_combat = _combat
	_combat.start(game_state)
	return true


func _ensure_player_has_fixture_deck(player, fixture) -> void:
	if player == null or player.card_manager == null:
		return
	if not player.card_manager.get_pile("deck").is_empty():
		return
	player.card_manager.deck = fixture.create_deck()
