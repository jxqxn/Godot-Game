extends GutTest

const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")


func test_card_priority_defaults_to_zero_and_is_copied() -> void:
	# Given：一张基础卡牌。
	var card = StmCard.new()
	# Then：默认优先级为 0，避免破坏既有卡牌。
	assert_eq(card.play_priority, 0)
	# When：修改优先级并复制。
	card.play_priority = 12
	var copied = card.copy()
	# Then：复制牌保留优先级。
	assert_eq(copied.play_priority, 12)


func test_test_cards_define_fixed_play_priorities() -> void:
	# Given/Then：当前测试卡拥有固定优先级，用于排序和自动出牌验证。
	assert_eq(DefendScript.new().play_priority, 5)
	assert_eq(StrikeScript.new().play_priority, 10)
	assert_eq(ShrugItOffScript.new().play_priority, 15)
	assert_eq(BashScript.new().play_priority, 20)
	assert_eq(InflameScript.new().play_priority, 30)


func test_card_manager_returns_sorted_hand_copy_without_mutating_hand() -> void:
	# Given：手牌原始顺序与优先级顺序不同。
	var low = _priority_card("低", 1, 0)
	var high = _priority_card("高", 30, 0)
	var mid = _priority_card("中", 10, 0)
	var manager = StmCardManager.new()
	manager.hand = [high, low, mid]
	# When：读取按优先级排序的手牌视图。
	var sorted: Array = manager.get_hand_sorted_by_priority()
	# Then：返回低到高排序副本，原始 hand 不被修改。
	assert_eq(_card_names(sorted), ["低", "中", "高"])
	assert_eq(_card_names(manager.hand), ["高", "低", "中"])
	assert_ne(sorted, manager.hand)


func test_card_manager_priority_sort_is_stable_for_equal_priority() -> void:
	# Given：多张牌优先级相同。
	var first = _priority_card("第一", 10, 0)
	var second = _priority_card("第二", 10, 0)
	var third = _priority_card("第三", 10, 0)
	var manager = StmCardManager.new()
	manager.hand = [first, second, third]
	# When：读取排序视图。
	var sorted: Array = manager.get_hand_sorted_by_priority()
	# Then：相同优先级保持原始相对顺序。
	assert_eq(_card_names(sorted), ["第一", "第二", "第三"])


func test_card_manager_priority_sort_preserves_duplicate_reference_positions() -> void:
	# Given：同一个卡牌对象因错误数据重复出现在 hand 中。
	var repeated = _priority_card("重复", 10, 0)
	var low = _priority_card("低", 1, 0)
	var manager = StmCardManager.new()
	manager.hand = [repeated, low, repeated]
	# When：读取排序视图。
	var sorted: Array = manager.get_hand_sorted_by_priority()
	# Then：排序仍按原始位置稳定返回两个重复引用，而不是因为 hand.find() 都指向第一个位置导致不稳定。
	assert_eq(sorted, [low, repeated, repeated])
	assert_eq(manager.hand, [repeated, low, repeated])


func test_find_highest_priority_playable_card_returns_highest_playable() -> void:
	# Given：三张牌都能支付，其中最高优先级为“高”。
	var low = _priority_card("低", 1, 0)
	var high = _priority_card("高", 30, 1)
	var mid = _priority_card("中", 10, 1)
	var manager = StmCardManager.new()
	manager.hand = [mid, high, low]
	var game_state = _game_state_with_energy(3)
	# When：查找最高优先级可打牌。
	var selected = manager.find_highest_priority_playable_card(game_state)
	# Then：返回最高优先级且 can_play 为 true 的牌。
	assert_eq(selected, high)


func test_find_highest_priority_playable_card_skips_unplayable_expensive_card() -> void:
	# Given：最高优先级牌费用不足，下一张可打。
	var expensive = _priority_card("费用不足", 30, 3)
	var playable = _priority_card("可打", 10, 1)
	var manager = StmCardManager.new()
	manager.hand = [playable, expensive]
	var game_state = _game_state_with_energy(1)
	# When：查找最高优先级可打牌。
	var selected = manager.find_highest_priority_playable_card(game_state)
	# Then：跳过费用不足的牌，返回下一张可打牌。
	assert_eq(selected, playable)


func test_find_highest_priority_playable_card_returns_null_when_none_playable() -> void:
	# Given：所有手牌都费用不足。
	var first = _priority_card("第一", 10, 2)
	var second = _priority_card("第二", 20, 3)
	var manager = StmCardManager.new()
	manager.hand = [first, second]
	var game_state = _game_state_with_energy(1)
	# When：查找最高优先级可打牌。
	var selected = manager.find_highest_priority_playable_card(game_state)
	# Then：没有可打牌时返回 null。
	assert_null(selected)


func _priority_card(card_name: String, priority: int, cost: int) -> StmCard:
	var card = StmCard.new()
	card.card_name = card_name
	card.play_priority = priority
	card.cost = cost
	return card


func _game_state_with_energy(energy: int) -> StmGameState:
	var player = PlayerScript.new([])
	player.energy = energy
	var game_state = StmGameState.new(player)
	return game_state


func _card_names(cards: Array) -> Array:
	var names: Array = []
	for card in cards:
		names.append(str(card.card_name))
	return names
