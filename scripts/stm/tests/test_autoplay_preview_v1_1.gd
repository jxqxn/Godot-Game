extends GutTest

const PlayerScript := preload("res://scripts/stm/player/player.gd")
const DummyEnemyScript := preload("res://scripts/stm/enemies/test/dummy_enemy.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")


class RejectingCard:
	extends StmCard

	func _init() -> void:
		card_name = "拒绝出牌"
		cost = 0
		play_priority = 40

	func can_play(_game_state) -> bool:
		return false


func test_preview_reports_no_combat_before_battle_starts() -> void:
	# Given：存在玩家，但 game_state 尚未进入战斗。
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var combat = StmCombat.new([])
	# When：读取自动出牌预览。
	var preview: Dictionary = combat.get_auto_play_preview(game_state)
	# Then：预览安全失败，并解释为战斗尚未开始。
	assert_false(preview.ok)
	assert_eq(preview.blocked_reason_code, "NO_COMBAT")
	assert_true(str(preview.blocked_reason_text).contains("战斗尚未开始"))


func test_preview_reports_no_combat_when_called_on_non_current_combat() -> void:
	# Given：game_state 当前战斗是 current_combat，但外部错误地拿 old_combat 查询。
	var player = PlayerScript.new([])
	var game_state = StmGameState.new(player)
	var current_combat = StmCombat.new([DummyEnemyScript.new()])
	var old_combat = StmCombat.new([])
	game_state.current_combat = current_combat
	# When：从非当前 combat 读取自动出牌预览。
	var preview: Dictionary = old_combat.get_auto_play_preview(game_state)
	# Then：预览拒绝使用旧 combat 上下文。
	assert_false(preview.ok)
	assert_eq(preview.blocked_reason_code, "NO_COMBAT")
	assert_true(str(preview.blocked_reason_text).contains("战斗尚未开始"))


func test_preview_reports_no_player_when_player_is_missing() -> void:
	# Given：game_state 已指向当前战斗，但没有玩家。
	var game_state = StmGameState.new(null)
	var combat = StmCombat.new([])
	game_state.current_combat = combat
	# When：读取自动出牌预览。
	var preview: Dictionary = combat.get_auto_play_preview(game_state)
	# Then：预览安全失败，并解释为玩家不存在。
	assert_false(preview.ok)
	assert_eq(preview.blocked_reason_code, "NO_PLAYER")
	assert_true(str(preview.blocked_reason_text).contains("玩家不存在"))


func test_preview_reports_empty_hand_when_no_cards_are_in_hand() -> void:
	# Given：战斗中玩家手牌为空。
	var context := _active_context([])
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览安全失败，并解释为没有手牌。
	assert_false(preview.ok)
	assert_eq(preview.blocked_reason_code, "EMPTY_HAND")
	assert_true(str(preview.blocked_reason_text).contains("没有手牌"))


func test_preview_selects_highest_priority_playable_card_with_legal_target() -> void:
	# Given：防御和打击都可打，打击优先级更高且有合法敌人目标。
	var strike = StrikeScript.new()
	var defend = DefendScript.new()
	var context := _active_context([defend, strike], 3)
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览选择最高优先级且可打的打击。
	assert_true(preview.ok)
	assert_eq(preview.selected_card, strike)
	assert_true(str(preview.selected_reason).contains("打击"))
	assert_eq(preview.skipped.size(), 0)


func test_preview_skips_expensive_high_priority_card_and_records_reason() -> void:
	# Given：痛击优先级更高但费用不足，打击可打。
	var strike = StrikeScript.new()
	var bash = BashScript.new()
	var context := _active_context([strike, bash], 1)
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览跳过痛击并选择打击，跳过原因是能量不足。
	assert_true(preview.ok)
	assert_eq(preview.selected_card, strike)
	assert_eq(preview.skipped.size(), 1)
	assert_eq(preview.skipped[0].card, bash)
	assert_eq(preview.skipped[0].reason_code, "NOT_ENOUGH_ENERGY")
	assert_true(str(preview.skipped[0].reason_text).contains("能量不足"))


func test_preview_records_can_play_rejected_reason() -> void:
	# Given：最高优先级牌由 can_play() 自身拒绝，下一张打击仍可打。
	var strike = StrikeScript.new()
	var rejecting = RejectingCard.new()
	var context := _active_context([strike, rejecting], 3)
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览跳过拒绝牌并记录 CAN_PLAY_REJECTED。
	assert_true(preview.ok)
	assert_eq(preview.selected_card, strike)
	assert_eq(preview.skipped.size(), 1)
	assert_eq(preview.skipped[0].card, rejecting)
	assert_eq(preview.skipped[0].reason_code, "CAN_PLAY_REJECTED")
	assert_true(str(preview.skipped[0].reason_text).contains("卡牌规则限制"))


func test_preview_records_not_in_hand_reason_for_stale_card() -> void:
	# Given：一张旧引用卡牌已经不在手牌中。
	var context := _active_context([], 3)
	var stale_card = StrikeScript.new()
	# When：直接询问该卡牌的自动出牌阻塞原因。
	var reason: Dictionary = context.combat._card_auto_play_block_reason(context.game_state, stale_card)
	# Then：规则层说明它不在当前手牌中。
	assert_eq(reason.code, "NOT_IN_HAND")
	assert_true(str(reason.text).contains("不在手牌中"))


func test_preview_skips_enemy_target_card_when_no_enemy_is_alive() -> void:
	# Given：敌方目标牌优先级更高，但当前没有存活敌人；自身目标牌仍可打。
	var strike = StrikeScript.new()
	var defend = DefendScript.new()
	var context := _active_context([defend, strike], 3, [])
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览跳过打击并选择防御，跳过原因是没有合法目标。
	assert_true(preview.ok)
	assert_eq(preview.selected_card, defend)
	assert_eq(preview.skipped.size(), 1)
	assert_eq(preview.skipped[0].card, strike)
	assert_eq(preview.skipped[0].reason_code, "NO_LEGAL_TARGET")
	assert_true(str(preview.skipped[0].reason_text).contains("没有可选敌人"))


func test_preview_has_no_combat_side_effects() -> void:
	# Given：战斗中有可打手牌、敌人、能量和格挡状态。
	var strike = StrikeScript.new()
	var defend = DefendScript.new()
	var enemy = DummyEnemyScript.new()
	var context := _active_context([defend, strike], 3, [enemy])
	context.game_state.player.block = 4
	var before_energy: int = context.game_state.player.energy
	var before_hand: Array = context.game_state.player.card_manager.hand.duplicate()
	var before_discard: Array = context.game_state.player.card_manager.discard_pile.duplicate()
	var before_enemy_hp: int = enemy.hp
	var before_block: int = context.game_state.player.block
	# When：读取自动出牌预览。
	var preview: Dictionary = context.combat.get_auto_play_preview(context.game_state)
	# Then：预览可读，但不会产生战斗副作用。
	assert_true(preview.ok)
	assert_eq(context.game_state.player.energy, before_energy)
	assert_eq(context.game_state.player.card_manager.hand, before_hand)
	assert_eq(context.game_state.player.card_manager.discard_pile, before_discard)
	assert_eq(enemy.hp, before_enemy_hp)
	assert_eq(context.game_state.player.block, before_block)


func _active_context(cards: Array, energy: int = 3, enemies = null) -> Dictionary:
	var player = PlayerScript.new([])
	player.energy = energy
	player.card_manager.hand = cards
	var game_state = StmGameState.new(player)
	var combat_enemies: Array = enemies if enemies != null else [DummyEnemyScript.new()]
	var combat = StmCombat.new(combat_enemies)
	game_state.current_combat = combat
	return {"game_state": game_state, "combat": combat}
