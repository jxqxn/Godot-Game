extends GutTest

const EncounterFactoryScript := preload("res://scripts/stm/encounters/encounter_factory.gd")
const CombatRoomScript := preload("res://scripts/stm/rooms/combat.gd")
const BossRoomScript := preload("res://scripts/stm/rooms/boss_room.gd")
const PlayerScript := preload("res://scripts/stm/player/player.gd")
const GameBootstrapScript := preload("res://scripts/stm/engine/game_bootstrap.gd")


func test_encounter_factory_creates_debug_dummy_encounter() -> void:
	# Given：EncounterFactory 支持当前普通 debug combat 遭遇。
	var factory = EncounterFactoryScript.new()
	# When：创建 debug_dummy。
	var encounter: Dictionary = factory.create_encounter("debug_dummy")
	# Then：返回 DummyEnemy 和 debug combat_type。
	assert_true(encounter.get("ok", false))
	assert_eq(encounter.get("combat_type", ""), "debug")
	assert_eq(encounter.get("enemies", []).size(), 1)
	assert_eq(encounter.get("enemies", [])[0].get("enemy_name"), "DummyEnemy")


func test_encounter_factory_creates_boss_dummy_encounter() -> void:
	# Given：EncounterFactory 支持当前 Boss 遭遇。
	var factory = EncounterFactoryScript.new()
	# When：创建 boss_dummy。
	var encounter: Dictionary = factory.create_encounter("boss_dummy")
	# Then：返回 BossEnemy 和 boss combat_type。
	assert_true(encounter.get("ok", false))
	assert_eq(encounter.get("combat_type", ""), "boss")
	assert_eq(encounter.get("enemies", []).size(), 1)
	assert_eq(encounter.get("enemies", [])[0].get("enemy_name"), "BossEnemy")


func test_encounter_factory_unknown_id_returns_failure_config() -> void:
	# Given：未知 encounter_id。
	var factory = EncounterFactoryScript.new()
	# When：创建未知遭遇。
	var encounter: Dictionary = factory.create_encounter("missing")
	# Then：返回失败配置，不抛错。
	assert_false(encounter.get("ok", true))
	assert_eq(encounter.get("code", ""), "UNKNOWN_ENCOUNTER")
	assert_eq(encounter.get("enemies", []).size(), 0)


func test_combat_room_uses_payload_encounter_id_to_start_debug_combat() -> void:
	# Given：CombatRoom 收到 debug_dummy payload。
	var room = CombatRoomScript.new()
	room.set_room_payload({"encounter_id": "debug_dummy"})
	var game_state = _create_game_state()
	# When：进入房间。
	room.enter(game_state)
	# Then：启动 DummyEnemy debug 战斗。
	assert_not_null(room.get_combat())
	assert_not_null(game_state.current_combat)
	assert_eq(room.get_enemy().get("enemy_name"), "DummyEnemy")
	assert_eq(room.get_combat().combat_type, "debug")


func test_boss_room_uses_payload_encounter_id_to_start_boss_combat() -> void:
	# Given：BossRoom 收到 boss_dummy payload。
	var room = BossRoomScript.new()
	room.set_room_payload({"encounter_id": "boss_dummy"})
	var game_state = _create_game_state()
	# When：进入房间。
	room.enter(game_state)
	# Then：启动 BossEnemy boss 战斗。
	assert_not_null(room.get_combat())
	assert_not_null(game_state.current_combat)
	assert_eq(room.get_enemy().get("enemy_name"), "BossEnemy")
	assert_eq(room.get_combat().combat_type, "boss")


func _create_game_state():
	var bootstrap = GameBootstrapScript.new()
	var player = PlayerScript.new([])
	return bootstrap.create_game(player)
