extends GutTest

const RoomFactoryScript := preload("res://scripts/stm/rooms/room_factory.gd")
const MapNodeScript := preload("res://scripts/stm/map/map_node.gd")
const GameFlowScript := preload("res://scripts/stm/engine/game_flow.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func test_room_factory_creates_combat_room_from_combat_node() -> void:
	# Given：一个 combat MapNode。
	var factory = RoomFactoryScript.new()
	var node = MapNodeScript.new(0, 0, "combat", [], {"encounter_id": "debug_dummy"})
	# When：通过 RoomFactory 创建房间。
	var room = factory.create_room(node)
	# Then：返回 CombatRoom。
	assert_not_null(room)
	assert_eq(room.get_room_type(), "combat")


func test_room_factory_creates_rest_room_from_rest_node() -> void:
	# Given：一个 rest MapNode。
	var factory = RoomFactoryScript.new()
	var node = MapNodeScript.new(3, 0, "rest")
	# When：通过 RoomFactory 创建房间。
	var room = factory.create_room(node)
	# Then：返回 RestRoom。
	assert_not_null(room)
	assert_eq(room.get_room_type(), "rest")


func test_room_factory_creates_boss_room_from_boss_node() -> void:
	# Given：一个 boss MapNode。
	var factory = RoomFactoryScript.new()
	var node = MapNodeScript.new(6, 0, "boss", [], {"encounter_id": "boss_dummy"})
	# When：通过 RoomFactory 创建房间。
	var room = factory.create_room(node)
	# Then：返回 BossRoom。
	assert_not_null(room)
	assert_eq(room.get_room_type(), "boss")


func test_room_factory_returns_null_for_unknown_room_type() -> void:
	# Given：未知 room_type。
	var factory = RoomFactoryScript.new()
	var node = MapNodeScript.new(0, 0, "mystery")
	# When：创建房间。
	var room = factory.create_room(node)
	# Then：不会抛错，返回 null。
	assert_null(room)


func test_room_factory_passes_payload_to_room_when_supported() -> void:
	# Given：combat node 带有 encounter payload。
	var factory = RoomFactoryScript.new()
	var node = MapNodeScript.new(0, 0, "combat", [], {"encounter_id": "debug_dummy"})
	# When：创建房间。
	var room = factory.create_room(node)
	# Then：支持 set_room_payload 的 room 能收到 payload。
	assert_not_null(room)
	assert_true(room.has_method("set_room_payload"))
	assert_eq(room.get("room_payload").get("encounter_id"), "debug_dummy")


func test_game_flow_uses_room_factory_for_current_node_room_creation() -> void:
	# Given：GameFlow 位于第 1 层 combat node，MapData 显式声明 debug_dummy encounter。
	var flow = GameFlowScript.new(_create_game_state())
	# When：进入当前房间。
	var entered = flow.enter_current_room()
	# Then：外部行为保持不变：创建 combat room 和 combat context，并把 MapData payload 传入 room。
	assert_true(entered)
	assert_not_null(flow.get_current_room())
	assert_eq(flow.get_current_room().get_room_type(), "combat")
	assert_eq(flow.get_current_room().get("room_payload").get("encounter_id"), "debug_dummy")
	assert_not_null(flow.get_game_state().current_combat)


func test_game_flow_uses_room_factory_for_rest_and_boss_nodes() -> void:
	# Given：GameFlow 通过 debug 导航到 rest / boss 节点。
	var rest_flow = GameFlowScript.new(_create_game_state())
	var boss_flow = GameFlowScript.new(_create_game_state())
	assert_true(rest_flow.debug_navigate_to_node_for_test(3, 0))
	assert_true(boss_flow.debug_navigate_to_node_for_test(6, 0))
	# When：进入当前节点房间。
	assert_true(rest_flow.enter_current_room())
	assert_true(boss_flow.enter_current_room())
	# Then：外部行为保持不变，Boss 节点 payload 显式传入 BossRoom。
	assert_eq(rest_flow.get_current_room().get_room_type(), "rest")
	assert_eq(boss_flow.get_current_room().get_room_type(), "boss")
	assert_eq(boss_flow.get_current_room().get("room_payload").get("encounter_id"), "boss_dummy")


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)
