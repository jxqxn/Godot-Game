extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func test_game_flow_enters_event_room_and_advances_after_choice() -> void:
	# Given：GameFlow 注入一个最小 event → rest 测试地图。
	var flow = GameFlowScript.new(_create_game_state())
	assert_true(flow.debug_set_map_floors_for_test(_event_test_floors()))
	# When：进入当前 event 房间。
	assert_true(flow.enter_current_room())
	# Then：通过 RoomFactory 创建 EventRoom，并发出 event_choice。
	assert_not_null(flow.get_current_room())
	assert_eq(flow.get_current_room().get_room_type(), "event")
	assert_true(flow.get_game_state().has_choice_request())
	assert_eq(flow.get_game_state().current_choice_request.request_type, "event_choice")
	assert_false(flow.advance_to_next_node(1, 0))
	# When：通过 GameState 公共入口提交事件选择。
	var result: Dictionary = flow.get_game_state().submit_choice("drink")
	# Then：房间完成后，GameFlow 可以推进到下一个节点。
	assert_true(bool(result.get("ok", false)))
	assert_true(flow.get_current_room().is_completed)
	assert_true(flow.advance_to_next_node(1, 0))
	assert_eq(flow.get_current_floor_index(), 1)
	assert_eq(flow.get_current_node_index(), 0)


func test_game_flow_rejects_test_map_injection_after_room_entered() -> void:
	# Given：GameFlow 已经进入当前房间。
	var flow = GameFlowScript.new(_create_game_state())
	assert_true(flow.enter_current_room())
	# When / Then：测试地图注入入口拒绝在房间中途改图。
	assert_false(flow.debug_set_map_floors_for_test(_event_test_floors()))


func _event_test_floors() -> Array:
	return [
		{
			"name": "测试第 1 层",
			"nodes": [
				{"type": "event", "room_payload": {"event_id": "debug_fountain"}, "next_nodes": [{"floor_index": 1, "node_index": 0}]}
			]
		},
		{
			"name": "测试第 2 层",
			"nodes": [
				{"type": "rest", "room_payload": {}, "next_nodes": []}
			]
		}
	]


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)
