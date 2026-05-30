extends GutTest

const BaseRoomScript := preload("res://scripts/stm/rooms/base.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


func _create_minimal_game_state():
	return GameStateScript.new(PlayerScript.new([]))


func test_base_room_marks_entered_and_completed() -> void:
	# Given：一个基础房间。
	var room = BaseRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入并完成房间。
	room.enter(game_state)
	room.complete(game_state)
	# Then：基础状态被记录。
	assert_true(room.is_entered)
	assert_true(room.is_completed)


func test_base_room_get_room_type_returns_base() -> void:
	# Given：一个基础房间。
	var room = BaseRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "base"。
	assert_eq(room_type, "base")


func test_combat_room_starts_combat_on_enter() -> void:
	# Given：一个 CombatRoom 和一个 GameState。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入战斗房间。
	room.enter(game_state)
	# Then：战斗上下文创建，敌人存在，玩家有初始手牌。
	assert_not_null(game_state.current_combat)
	assert_not_null(room.get_combat())
	assert_not_null(room.get_enemy())
	assert_true(game_state.player.card_manager.get_pile("hand").size() > 0)


func test_combat_room_does_not_complete_without_combat_win() -> void:
	# Given：一个已经进入的 CombatRoom。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：传入非胜利战斗结果。
	room.handle_combat_result(TypesScript.TerminalResult.NONE, game_state)
	# Then：房间仍未完成。
	assert_false(room.is_completed)


func test_combat_room_creates_card_reward_after_combat_win_and_completes_after_choice() -> void:
	# Given：一个已经进入的 CombatRoom。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：传入战斗胜利结果。
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	# Then：普通战斗先等待奖励选择，不立即完成。
	assert_false(room.is_completed)
	assert_true(game_state.has_choice_request())
	assert_eq(game_state.current_choice_request.request_type, "card_reward")
	# When：跳过奖励。
	var skip_option = _option_with_action(game_state.current_choice_request, "skip")
	assert_not_null(skip_option)
	game_state.submit_choice(skip_option.id)
	# Then：选择处理后房间完成。
	assert_true(room.is_completed)
	assert_false(game_state.has_choice_request())


func test_combat_room_get_room_type_returns_combat() -> void:
	# Given：一个 CombatRoom。
	var room = CombatRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "combat"。
	assert_eq(room_type, "combat")


func test_rest_room_restores_thirty_percent_max_hp() -> void:
	# Given：玩家 HP 低于最大值，进入休息房间。
	var player = PlayerScript.new([])
	player.hp = 40
	var game_state = GameStateScript.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房间。
	room.enter(game_state)
	# Then：玩家恢复 30% 最大 HP（70 × 0.3 = 21），HP 变为 61，并记录实际恢复量。
	assert_eq(player.hp, 61)
	assert_eq(room.last_hp_before, 40)
	assert_eq(room.last_hp_after, 61)
	assert_eq(room.last_heal_amount, 21)
	assert_true(room.is_completed)


func test_rest_room_does_not_exceed_max_hp() -> void:
	# Given：玩家 HP 接近满值。
	var player = PlayerScript.new([])
	player.hp = 65
	var game_state = GameStateScript.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房间。
	room.enter(game_state)
	# Then：HP 不会超过最大值 70，实际恢复量为 5。
	assert_eq(player.hp, 70)
	assert_eq(room.last_heal_amount, 5)


func test_rest_room_get_room_type_returns_rest() -> void:
	# Given：一个 RestRoom。
	var room = RestRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "rest"。
	assert_eq(room_type, "rest")


func test_boss_room_extends_combat_room() -> void:
	# Given：一个 BossRoom。
	var room = BossRoomScript.new()
	# When：检查继承链。
	var is_combat_room = room is CombatRoomScript
	var is_base_room = room is BaseRoomScript
	# Then：BossRoom 是 CombatRoom 的子类，也是 Room 的子类。
	assert_true(is_combat_room)
	assert_true(is_base_room)


func test_boss_room_get_room_type_returns_boss() -> void:
	# Given：一个 BossRoom。
	var room = BossRoomScript.new()
	# When：查询房间类型。
	var room_type = room.get_room_type()
	# Then：返回 "boss"。
	assert_eq(room_type, "boss")


func test_boss_room_creates_stronger_enemy() -> void:
	# Given：一个 BossRoom 实例和一个 GameState。
	var room = BossRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入 BOSS 房间。
	room.enter(game_state)
	var enemy = room.get_enemy()
	# Then：敌人名称包含 Boss，HP 为 40，攻击力为 12。
	assert_not_null(enemy)
	assert_eq(enemy.enemy_name, "BossEnemy")
	assert_eq(enemy.max_hp, 40)
	assert_eq(enemy.hp, 40)
	assert_eq(enemy.intent_damage, 12)


func test_boss_room_marks_completed_only_after_combat_win() -> void:
	# Given：一个已经进入的 BossRoom。
	var room = BossRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：先传入非胜利结果，再传入胜利结果。
	room.handle_combat_result(TypesScript.TerminalResult.NONE, game_state)
	# Then：非胜利不会完成，胜利才会完成。
	assert_false(room.is_completed)
	room.handle_combat_result(TypesScript.TerminalResult.COMBAT_WIN, game_state)
	assert_true(room.is_completed)


func _option_with_action(request, action: String):
	for option in request.options:
		if option != null and option.payload.get("action") == action:
			return option
	return null
