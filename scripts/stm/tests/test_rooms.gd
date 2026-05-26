extends GutTest

const BaseRoomScript := preload("res://scripts/stm/rooms/base.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")
const RestRoomScript := preload("res://scripts/stm/rooms/rest.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	var game_state = bootstrap.create_game(player)
	return game_state


func test_room_enter_sets_is_completed_false() -> void:
	# Given：一个房间实例。
	var room = BaseRoomScript.new()
	# When：调用 enter() 进入房间。
	room.enter(null)
	# Then：is_completed 为 false。
	assert_false(room.is_completed)


func test_room_leave_after_enter_does_not_crash() -> void:
	# Given：一个已进入但未完成的房间。
	var room = BaseRoomScript.new()
	room.enter(null)
	# When：调用 leave() 退出房间。
	room.leave(null)
	# Then：不崩溃，方法正常返回。
	assert_not_null(room)


func test_combat_room_enter_creates_battle_context() -> void:
	# Given：一个 CombatRoom 实例和一个 GameState。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	# When：进入战斗房间。
	room.enter(game_state)
	# Then：战斗上下文已创建（game_state 持有 player 和 combat）。
	assert_not_null(game_state.player)
	assert_not_null(game_state.current_combat)
	assert_not_null(room.get_player())


func test_combat_room_complete_sets_is_completed() -> void:
	# Given：一个已经进入的 CombatRoom。
	var room = CombatRoomScript.new()
	var game_state = _create_minimal_game_state()
	room.enter(game_state)
	# When：调用 complete()。
	room.complete(game_state)
	# Then：is_completed 为 true。
	assert_true(room.is_completed)


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
	# Then：玩家恢复 30% 最大 HP（70 × 0.3 = 21），HP 变为 61。
	assert_eq(player.hp, 61)
	assert_true(room.is_completed)


func test_rest_room_does_not_exceed_max_hp() -> void:
	# Given：玩家 HP 接近满值。
	var player = PlayerScript.new([])
	player.hp = 65
	var game_state = GameStateScript.new(player)
	var room = RestRoomScript.new()
	# When：进入休息房间。
	room.enter(game_state)
	# Then：HP 不会超过最大值 70。
	assert_eq(player.hp, 70)


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
