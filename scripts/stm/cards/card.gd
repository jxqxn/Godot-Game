class_name StmCard
extends RefCounted

var card_name: String = ""
var card_type = StmTypes.CardType.SKILL
var rarity = StmTypes.RarityType.BASIC
var card_rarity = StmTypes.RarityType.BASIC
var target_type = StmTypes.TargetType.NONE

var cost: int = 0
var base_damage: int = 0
var base_block: int = 0
var base_magic: int = 0

var upgrade_damage: int = 0
var upgrade_block: int = 0
var upgrade_magic: int = 0

var damage: int = 0
var block: int = 0
var magic: int = 0

var upgrade_level: int = 0


func reset_values() -> void:
	damage = base_damage
	block = base_block
	magic = base_magic
	if upgrade_level > 0:
		damage = upgrade_damage if upgrade_damage > 0 else damage
		block = upgrade_block if upgrade_block > 0 else block
		magic = upgrade_magic if upgrade_magic > 0 else magic


func can_play(game_state) -> bool:
	if game_state == null:
		return false
	if game_state.player == null:
		return false
	return int(game_state.player.energy) >= cost


func on_play(_game_state, targets := []) -> Array:
	var actions: Array = []
	if block > 0 and _game_state != null and _game_state.player != null:
		actions.append(StmCombatActions.GainBlockAction.new(_game_state.player, block, _game_state.player, self))
	if damage > 0 and targets.size() > 0:
		var source = null
		if _game_state != null:
			source = _game_state.player
		actions.append(StmCombatActions.AttackAction.new(source, targets[0], damage, self))
	return actions


func play(game_state, _combat = null, targets := []):
	var actions = on_play(game_state, targets)
	return actions


func upgrade() -> void:
	upgrade_level += 1
	reset_values()


func copy():
	var card = get_script().new()
	card.card_name = card_name
	card.card_type = card_type
	card.rarity = rarity
	card.card_rarity = card_rarity
	card.target_type = target_type
	card.cost = cost
	card.base_damage = base_damage
	card.base_block = base_block
	card.base_magic = base_magic
	card.upgrade_damage = upgrade_damage
	card.upgrade_block = upgrade_block
	card.upgrade_magic = upgrade_magic
	card.upgrade_level = upgrade_level
	card.reset_values()
	return card
