extends GutTest

const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
const ActionQueueScript := preload("res://scripts/stm/actions/action_queue.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const CreatureScript := preload("res://scripts/stm/entities/creature.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")

class LabeledAction:
	extends RefCounted

	var label: String
	var sink: Array

	func _init(p_label: String, p_sink: Array) -> void:
		label = p_label
		sink = p_sink

	func execute(_game_state) -> int:
		sink.append(label)
		return TypesScript.TerminalResult.NONE

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


func test_action_queue_and_game_state_support_to_front_order() -> void:
	# Given：一个 ActionQueue 与 GameState，并准备 A/B/C 三个带标签的动作。
	var queue = ActionQueueScript.new()
	var game_state = GameStateScript.new()
	var executed: Array = []
	var action_a = _labeled_action("A", executed)
	var action_b = _labeled_action("B", executed)
	var action_c = _labeled_action("C", executed)
	# When：先入队 A/B，再将 C 以前插方式加入并执行全部动作。
	queue.add_action(action_a)
	queue.add_action(action_b)
	queue.add_action(action_c, true)
	queue.execute_all(game_state)
	# Then：执行顺序应为 C -> A -> B；GameState 的 to_front 透传也应满足同样顺序。
	assert_eq(executed, ["C", "A", "B"])
	executed.clear()
	game_state.add_actions([action_a, action_b], false)
	game_state.add_action(action_c, true)
	game_state.drive_actions()
	assert_eq(executed, ["C", "A", "B"])


func test_player_and_dummy_enemy_use_shared_inheritance() -> void:
	# Given：创建测试玩家与测试敌人实例。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var enemy = bootstrap.create_test_combat(game_state).enemies[0]
	# When：检查类型与脚本继承路径。
	var player = game_state.player
	var enemy_script_path = enemy.get_script().resource_path
	# Then：玩家应为 StmCreature；DummyEnemy 应为 StmEnemy 的子类并共享 Creature 行为。
	assert_true(player is CreatureScript)
	assert_true(enemy is EnemyScript)
	assert_true(enemy is CreatureScript)
	assert_eq(enemy_script_path, "res://scripts/stm/enemies/test/dummy_enemy.gd")


func test_combat_public_api_drives_state_changes_via_action_queue() -> void:
	# Given：开始一场战斗并定位手牌中的 Strike/Defend。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Strike")
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "Defend")
	var start_hp = game_state.player.hp
	# When：连续打出 Strike、Defend，然后结束回合。
	var strike_result = combat.play_card(game_state, strike, [enemy])
	var defend_result = combat.play_card(game_state, defend, [])
	var end_result = combat.end_turn(game_state)
	# Then：公共 API 结果不变，且执行后队列为空并回到玩家回合开始阶段。
	assert_eq(strike_result, TypesScript.TerminalResult.NONE)
	assert_eq(defend_result, TypesScript.TerminalResult.NONE)
	assert_eq(end_result, TypesScript.TerminalResult.NONE)
	assert_eq(enemy.hp, enemy.max_hp - 6)
	assert_eq(game_state.player.hp, start_hp - 1)
	assert_true(game_state.action_queue.is_empty())
	assert_eq(combat.combat_state.current_phase, "player_start")


func _labeled_action(label: String, sink: Array):
	return LabeledAction.new(label, sink)
