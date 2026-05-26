extends GutTest

const BaseRoomScript := preload("res://scripts/stm/rooms/base.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


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
