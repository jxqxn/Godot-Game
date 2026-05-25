class_name StmCombatActions
extends RefCounted


class AttackAction:
	extends RefCounted

	var source
	var target
	var damage: int
	var card

	func _init(p_source, p_target, p_damage: int, p_card = null) -> void:
		source = p_source
		target = p_target
		damage = p_damage
		card = p_card

	func execute(_game_state = null):
		if target == null:
			return StmTypes.TerminalResult.NONE
		var final_damage: int = int(damage)
		if source != null and source.has_method("modify_damage_dealt"):
			final_damage = int(source.modify_damage_dealt(final_damage, target, card))
		if target != null and target.has_method("modify_damage_taken"):
			final_damage = int(target.modify_damage_taken(final_damage, source, card))
		final_damage = max(0, int(final_damage))
		if target.has_method("take_damage"):
			target.take_damage(final_damage, source, card)
		elif "hp" in target:
			target.hp -= final_damage
		return StmTypes.TerminalResult.NONE


class EnemyAttackAction:
	extends RefCounted

	var enemy
	var player
	var damage: int

	func _init(p_enemy, p_player, p_damage: int) -> void:
		enemy = p_enemy
		player = p_player
		damage = p_damage

	func execute(_game_state = null):
		var attack = AttackAction.new(enemy, player, damage, null)
		return attack.execute()


class GainBlockAction:
	extends RefCounted

	var target
	var amount: int

	func _init(p_target, p_amount: int) -> void:
		target = p_target
		amount = p_amount

	func execute(_game_state = null):
		if target == null:
			return StmTypes.TerminalResult.NONE
		if target.has_method("gain_block"):
			target.gain_block(amount)
		elif "block" in target:
			target.block += amount
		return StmTypes.TerminalResult.NONE


class ApplyPowerAction:
	extends RefCounted

	var target
	var power

	func _init(p_target, p_power) -> void:
		target = p_target
		power = p_power

	func execute(_game_state = null):
		if target == null:
			return StmTypes.TerminalResult.NONE
		if target.has_method("add_power"):
			target.add_power(power)
		return StmTypes.TerminalResult.NONE


class DrawCardsAction:
	extends RefCounted

	var player
	var amount: int

	func _init(p_player, p_amount: int) -> void:
		player = p_player
		amount = p_amount

	func execute(_game_state = null):
		if player == null or player.card_manager == null:
			return StmTypes.TerminalResult.NONE
		if player.card_manager.has_method("draw_many"):
			player.card_manager.draw_many(amount)
		return StmTypes.TerminalResult.NONE


class DiscardCardAction:
	extends RefCounted

	var player
	var card

	func _init(p_player, p_card) -> void:
		player = p_player
		card = p_card

	func execute(_game_state = null):
		if player == null or player.card_manager == null:
			return StmTypes.TerminalResult.NONE
		if player.card_manager.has_method("discard_card"):
			player.card_manager.discard_card(card)
		return StmTypes.TerminalResult.NONE


class PlayCardAction:
	extends RefCounted

	var combat
	var card
	var targets: Array

	func _init(p_combat, p_card, p_targets: Array = []) -> void:
		combat = p_combat
		card = p_card
		targets = p_targets

	func execute(game_state = null):
		if combat == null:
			return StmTypes.TerminalResult.NONE
		if combat.has_method("_execute_play_card"):
			return combat._execute_play_card(game_state, card, targets)
		return StmTypes.TerminalResult.NONE


class EndTurnAction:
	extends RefCounted

	var combat

	func _init(p_combat) -> void:
		combat = p_combat

	func execute(game_state = null):
		if combat == null:
			return StmTypes.TerminalResult.NONE
		if combat.has_method("_execute_end_turn"):
			return combat._execute_end_turn(game_state)
		return StmTypes.TerminalResult.NONE
