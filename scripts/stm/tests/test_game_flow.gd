extends GutTest

const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func _create_minimal_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)


func test_game_flow_starts_at_floor_zero() -> void:
	# Given：一个新创建的 GameFlow。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：查询当前楼层索引。
	var floor_index = flow.get_current_floor_index()
	# Then：初始楼层索引为 0。
	assert_eq(floor_index, 0)


func test_game_flow_enter_combat_room_creates_battle() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	# When：进入当前楼层的战斗房间。
	flow.enter_current_room()
	# Then：game_state 中创建了战斗上下文。
	assert_not_null(game_state.current_combat)
	assert_not_null(game_state.player)
	assert_not_null(flow.get_current_room())


func test_game_flow_complete_room_then_get_next_options() -> void:
	# Given：GameFlow 处于第 0 层，已进入战斗房间。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：查询可选的下一层。
	var options = flow.get_available_next_floors()
	# Then：返回第 1 层作为下一层选项。
	assert_eq(options.size(), 1)
	assert_eq(options[0]["floor_index"], 1)


func test_game_flow_advance_to_next_floor() -> void:
	# Given：GameFlow 处于第 0 层，房间已完成。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：推进到下一层。
	flow.advance_to_next_floor(1)
	# Then：当前楼层索引变为 1。
	assert_eq(flow.get_current_floor_index(), 1)


func test_game_flow_at_boss_floor_sets_flow_completed_on_win() -> void:
	# Given：GameFlow 直接导航到第 6 层 BossRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow._map_manager.navigate_to_floor(6)
	# When：进入 BOSS 房间并直接标记完成。
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# Then：flow_completed 为 true。
	assert_true(flow.is_flow_completed())


func test_game_flow_not_completed_at_non_boss_floor() -> void:
	# Given：GameFlow 处于第 0 层 CombatRoom。
	var game_state = _create_minimal_game_state()
	var flow = GameFlowScript.new(game_state)
	flow.enter_current_room()
	flow.get_current_room().complete(game_state)
	# When：检查 flow_completed。
	var is_completed = flow.is_flow_completed()
	# Then：普通战斗完成不应触发通关。
	assert_false(is_completed)
