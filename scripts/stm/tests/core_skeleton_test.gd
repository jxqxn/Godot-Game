extends GutTest

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")

func _find_card_by_name(cards: Array, card_name: String):
	for card in cards:
		if card.card_name == card_name:
			return card
	return null

func test_reset_for_combat_moves_deck_copies_to_draw_pile() -> void:
	# Given：一个带有测试起始牌组的游戏状态。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var card_manager = game_state.player.card_manager
	# When：重置玩家牌堆进入战斗。
	card_manager.reset_for_combat()
	# Then：卡组保留原始牌，抽牌堆获得战斗副本，手牌和弃牌堆为空。
	assert_eq(card_manager.get_pile("deck").size(), 4)
	assert_eq(card_manager.get_pile("draw_pile").size(), 4)
	assert_eq(card_manager.get_pile("hand").size(), 0)
	assert_eq(card_manager.get_pile("discard_pile").size(), 0)
	assert_ne(card_manager.get_pile("deck")[0], card_manager.get_pile("draw_pile")[0])

func test_draw_many_moves_cards_from_draw_pile_to_hand() -> void:
	# Given：一个已经重置到战斗状态的牌堆管理器。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var card_manager = game_state.player.card_manager
	card_manager.reset_for_combat()
	# When：抽取两张牌。
	var drawn = card_manager.draw_many(2)
	# Then：两张牌从抽牌堆进入手牌。
	assert_eq(drawn.size(), 2)
	assert_eq(card_manager.get_pile("hand").size(), 2)
	assert_eq(card_manager.get_pile("draw_pile").size(), 2)

func test_strike_spends_energy_damages_enemy_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Strike。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Strike")
	var starting_energy = game_state.player.energy
	# When：玩家对 DummyEnemy 打出 Strike。
	var result = combat.play_card(game_state, strike, [enemy])
	# Then：玩家消耗 1 点能量，敌人受到 6 点伤害，Strike 进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(enemy.hp, enemy.max_hp - 6)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(strike))

func test_defend_spends_energy_grants_block_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有 Defend。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Defend")
	var starting_energy = game_state.player.energy
	# When：玩家打出 Defend。
	var result = combat.play_card(game_state, defend, [])
	# Then：玩家消耗 1 点能量，获得 5 点格挡，Defend 进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(game_state.player.block, 5)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(defend))

func test_end_turn_discards_hand_and_enemy_damage_uses_block() -> void:
	# Given：玩家已打出 Defend 并保留 5 点格挡，手牌中还有其他牌。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Defend")
	combat.play_card(game_state, defend, [])
	var starting_hp = game_state.player.hp
	# When：玩家结束回合，DummyEnemy 执行 6 点攻击。
	var result = combat.end_turn(game_state)
	# Then：剩余手牌进入弃牌堆，格挡抵消 5 点伤害，玩家只损失 1 点 HP。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.card_manager.get_pile("hand").size(), 0)
	assert_eq(game_state.player.hp, starting_hp - 1)
	assert_eq(game_state.player.block, 0)
	assert_eq(combat.combat_state.current_phase, "player_start")

func test_combat_reports_win_when_all_enemies_reach_zero_hp() -> void:
	# Given：DummyEnemy 只剩 6 点 HP，玩家手牌中有 Strike。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	enemy.hp = 6
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Strike")
	# When：玩家对 DummyEnemy 打出 Strike。
	var result = combat.play_card(game_state, strike, [enemy])
	# Then：战斗返回胜利结果。
	assert_eq(result, TypesScript.TerminalResult.COMBAT_WIN)
	assert_true(enemy.is_dead())
