extends Node

const DEBUG_WINDOW_SIZE := Vector2i(1600, 900)


func _ready() -> void:
	call_deferred("_apply_debug_window_size")


func _apply_debug_window_size() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(DEBUG_WINDOW_SIZE)
	var screen_index := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var centered := Vector2i(
		max(0, int((screen_size.x - DEBUG_WINDOW_SIZE.x) / 2)),
		max(0, int((screen_size.y - DEBUG_WINDOW_SIZE.y) / 2))
	)
	DisplayServer.window_set_position(centered)
