class_name StmCombatActions
extends RefCounted


class AttackAction:
	extends RefCounted

	var source
	var target
	var damage: int

	func _init(p_source, p_target, p_damage: int) -> void:
		source = p_source
		target = p_target
		damage = p_damage

	func execute(_game_state = null):
		if target == null:
			return
		if target.has_method("take_damage"):
			target.take_damage(damage, source)
			return
		if "hp" in target:
			target.hp -= damage


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
		var attack = AttackAction.new(enemy, player, damage)
		attack.execute()


class GainBlockAction:
	extends RefCounted

	var target
	var amount: int

	func _init(p_target, p_amount: int) -> void:
		target = p_target
		amount = p_amount

	func execute(_game_state = null):
		if target == null:
			return
		if target.has_method("gain_block"):
			target.gain_block(amount)
			return
		if "block" in target:
			target.block += amount


class DrawCardsAction:
	extends RefCounted

	var player
	var amount: int

	func _init(p_player, p_amount: int) -> void:
		player = p_player
		amount = p_amount

	func execute(_game_state = null):
		if player == null or player.card_manager == null:
			return
		if player.card_manager.has_method("draw_many"):
			player.card_manager.draw_many(amount)


class DiscardCardAction:
	extends RefCounted

	var player
	var card

	func _init(p_player, p_card) -> void:
		player = p_player
		card = p_card

	func execute(_game_state = null):
		if player == null or player.card_manager == null:
			return
		if player.card_manager.has_method("discard_card"):
			player.card_manager.discard_card(card)


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
			return
		if combat.has_method("play_card"):
			return combat.play_card(game_state, card, targets)
		return null


class EndTurnAction:
	extends RefCounted

	var combat

	func _init(p_combat) -> void:
		combat = p_combat

	func execute(game_state = null):
		if combat == null:
			return
		if combat.has_method("end_turn"):
			return combat.end_turn(game_state)
		return null
