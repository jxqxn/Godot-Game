extends GutTest

const EventRoomScript := preload("res://scripts/stm/rooms/event_room.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func test_event_room_get_room_type_returns_event() -> void:
	# Given：一个最小 EventRoom。
	var room = EventRoomScript.new()
	# When / Then：房间类型稳定返回 event。
	assert_eq(room.get_room_type(), "event")


func test_event_room_enter_creates_debug_fountain_event_choice() -> void:
	# Given：一个带有 debug_fountain payload 的 EventRoom。
	var room = EventRoomScript.new()
	room.set_room_payload({"event_id": "debug_fountain"})
	var game_state = _create_game_state()
	# When：进入房间。
	room.enter(game_state)
	# Then：GameState 会收到 event_choice，并且房间尚未完成。
	assert_true(game_state.has_choice_request())
	assert_false(room.is_completed)
	var request = game_state.current_choice_request
	assert_eq(request.request_type, "event_choice")
	assert_eq(request.id, "debug_fountain")
	assert_eq(request.title, "清泉")
	assert_eq(request.context.get("room"), room)
	assert_eq(request.context.get("event_id"), "debug_fountain")
	assert_not_null(request.get_option("drink"))
	assert_not_null(request.get_option("leave"))


func test_event_room_enter_defaults_to_debug_fountain_when_payload_missing() -> void:
	# Given：一个没有 event_id payload 的 EventRoom。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	# When：进入房间。
	room.enter(game_state)
	# Then：默认创建 debug_fountain event_choice。
	assert_true(game_state.has_choice_request())
	assert_eq(game_state.current_choice_request.request_type, "event_choice")
	assert_eq(game_state.current_choice_request.context.get("event_id"), "debug_fountain")


func test_event_room_choice_options_have_stable_payloads() -> void:
	# Given：进入 debug_fountain 事件房。
	var room = EventRoomScript.new()
	var game_state = _create_game_state()
	room.enter(game_state)
	# When：读取事件选项。
	var drink = game_state.current_choice_request.get_option("drink")
	var leave = game_state.current_choice_request.get_option("leave")
	# Then：drink / leave payload 只描述选择意图，不直接结算规则。
	assert_eq(drink.label, "饮用泉水（恢复 5 点 HP）")
	assert_eq(drink.payload.get("action"), "heal")
	assert_eq(drink.payload.get("amount"), 5)
	assert_eq(leave.label, "离开")
	assert_eq(leave.payload.get("action"), "leave")


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)
