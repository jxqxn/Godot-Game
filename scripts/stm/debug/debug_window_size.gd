extends Node


func _ready() -> void:
	call_deferred("_apply_debug_window_mode")


func _apply_debug_window_mode() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
