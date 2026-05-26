class_name StmCombatRoom
extends "res://scripts/stm/rooms/base.gd"

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const CombatScript := preload("res://scripts/stm/engine/combat.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	if game_state == null:
		return
	var fixture = FixedBattleFixtureScript.new()
	_start_combat_with_enemy(game_state, fixture.create_enemy(), "debug", fixture)


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


func _start_combat_with_enemy(game_state, battle_enemy, combat_type: String = "debug", fixture = null) -> bool:
	if game_state == null or battle_enemy == null:
		return false
	var deck_fixture = fixture if fixture != null else FixedBattleFixtureScript.new()
	if game_state.player == null:
		game_state.player = deck_fixture.create_player()
	else:
		_ensure_player_has_fixture_deck(game_state.player, deck_fixture)
	_player = game_state.player
	_enemy = battle_enemy
	_combat = CombatScript.new([_enemy], combat_type)
	if _combat == null:
		return false
	game_state.current_combat = _combat
	# Combat.start() 是唯一的战斗初始化入口，避免重复 reset 牌堆和推进随机状态。
	_combat.start(game_state)
	return true


func _ensure_player_has_fixture_deck(player, fixture) -> void:
	if player == null or player.card_manager == null:
		return
	if not player.card_manager.get_pile("deck").is_empty():
		return
	player.card_manager.deck = fixture.create_deck()
