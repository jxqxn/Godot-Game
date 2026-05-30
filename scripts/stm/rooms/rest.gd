class_name StmRestRoom
extends StmRoom

const ChoiceOptionScript := preload("res://scripts/stm/choices/choice_option.gd")
const ChoiceRequestScript := preload("res://scripts/stm/choices/choice_request.gd")

var last_hp_before: int = 0
var last_hp_after: int = 0
var last_heal_amount: int = 0


func enter(game_state) -> void:
	super.enter(game_state)
	last_hp_before = 0
	last_hp_after = 0
	last_heal_amount = 0
	if game_state == null or game_state.player == null:
		is_completed = true
		return
	game_state.set_choice_request(_create_rest_choice_request(game_state))


func get_room_type() -> String:
	return "rest"


func _create_rest_choice_request(game_state):
	return ChoiceRequestScript.new(
		"rest_choice",
		"选择休息行动",
		"rest_choice",
		_create_rest_choice_options(game_state),
		1,
		false,
		{"room": self}
	)


func _create_rest_choice_options(game_state) -> Array:
	return [
		_rest_option(game_state),
		_skip_option(),
	]


func _rest_option(game_state):
	return ChoiceOptionScript.new(
		"rest",
		_rest_heal_preview_text(game_state),
		"",
		{"action": "rest"},
		true
	)


func _skip_option():
	return ChoiceOptionScript.new(
		"skip_rest",
		"跳过",
		"",
		{"action": "skip"},
		true
	)


func _rest_heal_preview_text(game_state) -> String:
	if game_state == null or game_state.player == null:
		return "休息"
	var player = game_state.player
	var heal_amount := int(float(player.max_hp) * 0.3)
	return "休息（恢复 %d 点 HP）" % heal_amount
