class_name StmChoiceRequest
extends RefCounted

var id: String = ""
var title: String = ""
var request_type: String = ""
var options: Array = []
var max_select: int = 1
var must_select: bool = true
var context: Dictionary = {}


func _init(
	p_id: String = "",
	p_title: String = "",
	p_request_type: String = "",
	p_options: Array = [],
	p_max_select: int = 1,
	p_must_select: bool = true,
	p_context: Dictionary = {}
) -> void:
	id = p_id
	title = p_title
	request_type = p_request_type
	options = p_options.duplicate()
	max_select = p_max_select
	must_select = p_must_select
	context = p_context


func get_option(option_id: String):
	for option in options:
		if option != null and option.get("id") == option_id:
			return option
	return null


func has_option(option_id: String) -> bool:
	return get_option(option_id) != null


func enabled_options() -> Array:
	var result: Array = []
	for option in options:
		if option != null and bool(option.get("enabled")):
			result.append(option)
	return result
