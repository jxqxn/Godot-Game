extends Node


func _ready() -> void:
	call_deferred("_apply_debug_window_mode")


func _apply_debug_window_mode() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	var screen_index := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen_index)
	var screen_size := DisplayServer.screen_get_size(screen_index)
	DisplayServer.window_set_position(screen_position)
	DisplayServer.window_set_size(screen_size)
