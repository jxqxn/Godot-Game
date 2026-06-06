class_name StmEventRoom
extends "res://scripts/stm/rooms/base.gd"

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")
const PressureEncounterStateScript := preload("res://scripts/stm/encounters/pressure/pressure_encounter_state.gd")

var last_hp_before: int = 0
var last_hp_after: int = 0
var last_event_action: String = ""


func enter(game_state) -> void:
	super.enter(game_state)
	last_hp_before = 0
	last_hp_after = 0
	last_event_action = ""
	if game_state == null:
		return
	var event_id := str(room_payload.get("event_id", "debug_fountain"))
	if event_id == "debug_pressure_encounter":
		var pressure_encounter = PressureEncounterStateScript.new()
		pressure_encounter.initialize(event_id)
		game_state.current_pressure_encounter = pressure_encounter
		game_state.set_choice_request(pressure_encounter.build_choice_request({"room": self, "event_id": event_id}))
		return
	game_state.current_pressure_encounter = null
	game_state.set_choice_request(_create_event_choice_request(event_id))


func get_room_type() -> String:
	return "event"


func _create_event_choice_request(event_id: String):
	match event_id:
		"debug_fountain":
			return ChoiceRequestScript.new(
				"debug_fountain",
				"清泉",
				"event_choice",
				_create_debug_fountain_options(),
				1,
				false,
				{"room": self, "event_id": "debug_fountain"}
			)
		_:
			return ChoiceRequestScript.new(
				"debug_fountain",
				"清泉",
				"event_choice",
				_create_debug_fountain_options(),
				1,
				false,
				{"room": self, "event_id": "debug_fountain"}
			)


func _create_debug_fountain_options() -> Array:
	return [
		ChoiceOptionScript.new("drink", "饮用泉水（恢复 5 点 HP）", "", {"action": "heal", "amount": 5}, true),
		ChoiceOptionScript.new("leave", "离开", "", {"action": "leave"}, true),
	]
