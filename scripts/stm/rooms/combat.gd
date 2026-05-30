class_name StmCombatRoom
extends "res://scripts/stm/rooms/base.gd"

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const EncounterFactoryScript := preload("res://scripts/stm/encounters/encounter_factory.gd")
const CombatScript := preload("res://scripts/stm/engine/combat.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")

var _encounter_factory = EncounterFactoryScript.new()
var _player = null
var _combat = null
var _enemy = null


func enter(game_state) -> void:
	super.enter(game_state)
	if game_state == null:
		return
	var encounter_id := str(room_payload.get("encounter_id", "debug_dummy"))
	var encounter: Dictionary = _encounter_factory.create_encounter(encounter_id)
	if not bool(encounter.get("ok", false)):
		return
	var enemies: Array = encounter.get("enemies", [])
	if enemies.is_empty():
		return
	_start_combat_with_enemy(game_state, enemies[0], str(encounter.get("combat_type", "debug")), encounter.get("deck_fixture"))


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
	if game_state.current_choice_request != null:
		var request_type := str(game_state.current_choice_request.get("request_type"))
		if request_type == "card_reward":
			return
	game_state.set_choice_request(_create_card_reward_request())


func get_player():
	return _player


func get_combat():
	return _combat


func get_enemy():
	return _enemy


func get_room_type() -> String:
	return "combat"


func _create_card_reward_request():
	return ChoiceRequestScript.new(
		"combat_card_reward",
		"选择一张奖励卡牌",
		"card_reward",
		_create_card_reward_options(),
		1,
		false,
		{"room": self}
	)


func _create_card_reward_options() -> Array:
	return [
		_reward_card_option("take_strike", StrikeScript.new()),
		_reward_card_option("take_defend", DefendScript.new()),
		_reward_card_option("take_bash", BashScript.new()),
		_skip_reward_option(),
	]


func _reward_card_option(option_id: String, card):
	return ChoiceOptionScript.new(
		option_id,
		_card_reward_label(card),
		"",
		{"action": "take_card", "card": card},
		true
	)


func _skip_reward_option():
	return ChoiceOptionScript.new(
		"skip_reward",
		"跳过奖励",
		"",
		{"action": "skip", "card": null},
		true
	)


func _card_reward_label(card) -> String:
	if card == null:
		return "未知"
	var card_name = card.get("card_name")
	var cost = card.get("cost")
	if cost == null:
		return str(card_name) if card_name != null else "未知"
	return "%s（%d）" % [str(card_name), int(cost)]


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
