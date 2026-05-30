class_name StmEncounterFactory
extends RefCounted

const FixedBattleFixtureScript := preload("res://scripts/stm/debug/fixtures/fixed_battle_fixture.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")


func create_encounter(encounter_id: String) -> Dictionary:
	match encounter_id:
		"debug_dummy":
			return _debug_dummy_encounter()
		"boss_dummy":
			return _boss_dummy_encounter()
		_:
			return {
				"ok": false,
				"code": "UNKNOWN_ENCOUNTER",
				"encounter_id": encounter_id,
				"enemies": [],
				"combat_type": "",
			}


func _debug_dummy_encounter() -> Dictionary:
	var fixture = FixedBattleFixtureScript.new()
	return {
		"ok": true,
		"code": "OK",
		"encounter_id": "debug_dummy",
		"enemies": [fixture.create_enemy()],
		"combat_type": "debug",
		"deck_fixture": fixture,
	}


func _boss_dummy_encounter() -> Dictionary:
	return {
		"ok": true,
		"code": "OK",
		"encounter_id": "boss_dummy",
		"enemies": [EnemyScript.new(40, "BossEnemy", 12)],
		"combat_type": "boss",
		"deck_fixture": FixedBattleFixtureScript.new(),
	}
