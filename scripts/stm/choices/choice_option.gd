class_name StmChoiceOption
extends RefCounted

var id: String = ""
var label: String = ""
var detail: String = ""
var payload: Dictionary = {}
var enabled: bool = true


func _init(
	p_id: String = "",
	p_label: String = "",
	p_detail: String = "",
	p_payload: Dictionary = {},
	p_enabled: bool = true
) -> void:
	id = p_id
	label = p_label
	detail = p_detail
	payload = p_payload
	enabled = p_enabled
