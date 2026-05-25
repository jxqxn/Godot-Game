extends GutTest

const GameBootstrapScript := preload("res://scripts/stm/tests/test_bootstrap.gd")
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


class RecordingActionQueue:
	extends RefCounted

	var added_actions: Array = []
	var executed_actions: Array = []

	func add_action(action, _to_front: bool = false) -> void:
		if action == null:
			return
		added_actions.append(action)

	func drive(game_state):
		for action in added_actions:
			executed_actions.append(action)
			if action.has_method("execute"):
				action.execute(game_state)
		return TypesScript.TerminalResult.NONE

	func is_empty() -> bool:
		return added_actions.is_empty()


class TerminalAction:
	extends RefCounted

	var terminal_result: int

	func _init(p_terminal_result: int) -> void:
		terminal_result = p_terminal_result

	func execute(_game_state) -> int:
		return terminal_result


class TerminalCard:
	extends RefCounted

	var cost: int = 1
	var card_name: String = "TerminalCard"

	func play(_game_state, _combat, _targets: Array = []) -> Array:
		return [TerminalAction.new(TypesScript.TerminalResult.COMBAT_WIN)]


class IntentionEnemy:
	extends EnemyScript

	var determine_called: bool = false
	var execute_called: bool = false

	func _init() -> void:
		super(20, "IntentionEnemy", 9)
		intent_damage = 9

	func determine_next_intention() -> String:
		determine_called = true
		current_intention = "attack"
		return current_intention

	func execute_intention(game_state, _combat) -> Array:
		execute_called = true
		return [StmCombatActions.EnemyAttackAction.new(self, game_state.player, 4)]


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
	# Given：一场已开始的测试战斗，玩家手牌中有打击。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "打击")
	var starting_energy = game_state.player.energy
	# When：玩家对 DummyEnemy 打出打击。
	var result = combat.play_card(game_state, strike, [enemy])
	# Then：玩家消耗 1 点能量，敌人受到 6 点伤害，打击进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(enemy.hp, enemy.max_hp - 6)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(strike))

func test_defend_spends_energy_grants_block_and_discards() -> void:
	# Given：一场已开始的测试战斗，玩家手牌中有防御。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "防御")
	var starting_energy = game_state.player.energy
	# When：玩家打出防御。
	var result = combat.play_card(game_state, defend, [])
	# Then：玩家消耗 1 点能量，获得 5 点格挡，防御进入弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy - 1)
	assert_eq(game_state.player.block, 5)
	assert_true(game_state.player.card_manager.get_pile("discard_pile").has(defend))

func test_end_turn_discards_hand_enemy_damage_uses_block_and_starts_next_player_turn() -> void:
	# Given：玩家已打出防御并保留 5 点格挡，手牌中还有其他牌。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "防御")
	combat.play_card(game_state, defend, [])
	var starting_hp = game_state.player.hp
	# When：玩家结束回合，DummyEnemy 执行 6 点攻击。
	var result = combat.end_turn(game_state)
	# Then：剩余手牌先进入弃牌堆，格挡抵消 5 点伤害，玩家只损失 1 点 HP，并开始下一玩家回合。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.hp, starting_hp - 1)
	assert_eq(game_state.player.block, 0)
	assert_eq(game_state.player.energy, game_state.player.max_energy)
	assert_true(game_state.player.card_manager.get_pile("hand").size() > 0)
	assert_eq(combat.combat_state.current_phase, "player_start")

func test_combat_reports_win_when_all_enemies_reach_zero_hp() -> void:
	# Given：DummyEnemy 只剩 6 点 HP，玩家手牌中有打击。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	enemy.hp = 6
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "打击")
	# When：玩家对 DummyEnemy 打出打击。
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
	# Given：开始一场战斗并定位手牌中的打击/防御。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "打击")
	var defend = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "防御")
	var start_hp = game_state.player.hp
	# When：连续打出打击、防御，然后结束回合。
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
	assert_true(game_state.player.card_manager.get_pile("hand").size() > 0)
	assert_eq(combat.combat_state.current_phase, "player_start")


func test_combat_start_uses_draw_cards_action_queue_path() -> void:
	# Given: 一个测试战斗，且 game_state.action_queue 被可记录替身替换。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	var recording_queue = RecordingActionQueue.new()
	game_state.action_queue = recording_queue
	# When: 调用公共入口 combat.start(game_state)。
	combat.start(game_state)
	# Then: 应通过 DrawCardsAction 入队并执行，且手牌数量仍等于抽牌数。
	var contains_draw_action := false
	for action in recording_queue.added_actions:
		if action is StmCombatActions.DrawCardsAction:
			contains_draw_action = true
			break
	assert_true(contains_draw_action)
	var executed_draw_action := false
	for action in recording_queue.executed_actions:
		if action is StmCombatActions.DrawCardsAction:
			executed_draw_action = true
			break
	assert_true(executed_draw_action)
	var expected_hand_size = min(game_state.player.draw_count, game_state.player.card_manager.get_pile("draw_pile").size() + game_state.player.card_manager.get_pile("hand").size())
	assert_eq(game_state.player.card_manager.get_pile("hand").size(), expected_hand_size)


func test_card_play_only_returns_actions_without_driving_queue() -> void:
	# Given：已开始战斗，手牌中有打击，记录玩家格挡、敌人血量与队列长度。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var enemy = combat.enemies[0]
	var strike = _find_card_by_name(game_state.player.card_manager.get_pile("hand"), "打击")
	var start_enemy_hp = enemy.hp
	var start_block = game_state.player.block
	var start_queue_size = game_state.action_queue.queue.size()
	# When: 直接调用 card.play(game_state, combat, [enemy])。
	var actions = strike.play(game_state, combat, [enemy])
	# Then: 卡牌层只返回动作，不应主动驱动调度或改变战斗状态。
	assert_true(actions.size() > 0)
	assert_eq(enemy.hp, start_enemy_hp)
	assert_eq(game_state.player.block, start_block)
	assert_eq(game_state.action_queue.queue.size(), start_queue_size)


func test_play_card_action_result_is_not_swallowed_by_nested_drive() -> void:
	# Given: 一场已开始的战斗，手牌中放入会返回 COMBAT_WIN 终局动作的测试卡。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var card = TerminalCard.new()
	game_state.player.card_manager.get_pile("hand").append(card)
	# When: 通过 Combat 公共入口打出该卡。
	var result = combat.play_card(game_state, card, [])
	# Then: 返回值应传播为 COMBAT_WIN，不应被吞掉。
	assert_eq(result, TypesScript.TerminalResult.COMBAT_WIN)


func test_move_to_invalid_pile_keeps_card_in_source_pile() -> void:
	# Given: 手牌中有一张卡，且目标牌堆名称非法。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var card_manager = game_state.player.card_manager
	card_manager.reset_for_combat()
	var card = card_manager.draw_one()
	assert_true(card_manager.get_pile("hand").has(card))
	# When: 调用 move_to(card, "bad_pile")。
	var moved = card_manager.move_to(card, "bad_pile")
	# Then: 返回 false 且卡牌仍留在原始手牌堆，不会丢失。
	assert_false(moved)
	assert_true(card_manager.get_pile("hand").has(card))


func test_execute_enemy_turn_uses_enemy_intention_actions() -> void:
	# Given: 一个覆盖 execute_intention 的测试敌人，其 intent_damage 与返回动作伤害不同。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var enemy = IntentionEnemy.new()
	var combat_script = load("res://scripts/stm/engine/combat.gd")
	var combat = combat_script.new([enemy], "normal")
	combat.start(game_state)
	game_state.player.block = 0
	var start_hp = game_state.player.hp
	# When: 执行敌人回合。
	combat.execute_enemy_turn(game_state)
	# Then: 应调用 determine_next_intention/execute_intention，并以返回动作结算 4 点伤害。
	assert_true(enemy.determine_called)
	assert_true(enemy.execute_called)
	assert_eq(game_state.player.hp, start_hp - 4)


func test_production_bootstrap_is_generic_without_test_fixture_paths() -> void:
	# Given: 生产 bootstrap 脚本源码文本。
	var bootstrap_path = "res://scripts/stm/engine/game_bootstrap.gd"
	var content = FileAccess.get_file_as_string(bootstrap_path)
	# When: 检查是否包含测试目录硬编码。
	var has_test_card_path = content.find("cards/test") >= 0
	var has_test_enemy_path = content.find("enemies/test") >= 0
	# Then: 生产 bootstrap 不应硬编码测试夹具路径。
	assert_false(has_test_card_path)
	assert_false(has_test_enemy_path)


func _labeled_action(label: String, sink: Array):
	return LabeledAction.new(label, sink)
