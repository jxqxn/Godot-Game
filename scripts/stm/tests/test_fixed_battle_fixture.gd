extends GutTest

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")


func test_fixed_battle_fixture_creates_named_debug_battle() -> void:
	# Given：策划需要一个固定测试战斗样例。
	var fixture = FixedBattleFixtureScript.new()
	# When：创建固定战斗夹具并请求战斗上下文。
	var context: Dictionary = fixture.create_context()
	# Then：返回样例名称、游戏状态、战斗对象、玩家和 DummyEnemy。
	assert_eq(context.get("name", ""), "基础测试战斗")
	assert_not_null(context.get("game_state"))
	assert_not_null(context.get("combat"))
	assert_not_null(context.get("player"))
	assert_not_null(context.get("enemy"))
	assert_true(context["game_state"].player == context["player"])
	assert_eq(context["combat"].enemies.size(), 1)
	assert_true(context["combat"].enemies[0] == context["enemy"])
	assert_eq(context["combat"].combat_type, "debug")
	assert_eq(context["player"].hp, 70)
	assert_eq(context["player"].max_hp, 70)
	assert_eq(context["player"].energy, 3)
	assert_eq(context["player"].max_energy, 3)
	assert_eq(context["enemy"].enemy_name, "DummyEnemy")
	assert_eq(context["enemy"].hp, 20)
	assert_eq(context["enemy"].max_hp, 20)
	var deck: Array = context["player"].card_manager.get_pile("deck")
	assert_eq(deck.size(), 4)
	assert_eq(deck[0].card_name, "Strike")
	assert_eq(deck[1].card_name, "Defend")
	assert_eq(deck[2].card_name, "Strike")
	assert_eq(deck[3].card_name, "Defend")


func test_fixed_battle_fixture_creates_fresh_instances_each_time() -> void:
	# Given：策划多次重开同一个固定测试战斗。
	var fixture = FixedBattleFixtureScript.new()
	# When：连续两次创建 fixture 战斗上下文。
	var first: Dictionary = fixture.create_context()
	var second: Dictionary = fixture.create_context()
	# Then：两次返回的玩家、敌人、卡牌和战斗对象不是同一批实例。
	assert_false(first["player"] == second["player"])
	assert_false(first["enemy"] == second["enemy"])
	assert_false(first["combat"] == second["combat"])
	assert_false(first["game_state"] == second["game_state"])
	var first_deck: Array = first["player"].card_manager.get_pile("deck")
	var second_deck: Array = second["player"].card_manager.get_pile("deck")
	assert_eq(first_deck.size(), 4)
	assert_eq(second_deck.size(), 4)
	assert_false(first_deck[0] == second_deck[0])
	assert_false(first_deck[1] == second_deck[1])
	assert_false(first_deck[2] == second_deck[2])
	assert_false(first_deck[3] == second_deck[3])
