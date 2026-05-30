extends "res://scripts/stm/debug/battle_debug_scene.gd"


func _on_enter_room_pressed() -> void:
	if game_flow == null:
		status_message = "流程尚未初始化"
		_append_log(status_message)
		_refresh_display()
		return
	if not game_flow.enter_current_room():
		status_message = "进入房间失败"
		_append_log(status_message)
		_refresh_display()
		return
	var room = game_flow.get_current_room()
	if room == null:
		status_message = "进入房间失败"
		_append_log(status_message)
		_refresh_display()
		return
	var room_type = room.get_room_type()
	if room_type == "rest":
		map_panel.visible = false
		combat = null
		enemy = null
		if _has_active_choice_request():
			status_message = "选择休息行动"
			_append_log("进入休息房", "进入休息房：请选择休息行动。")
			_refresh_display()
			return
		if room.is_completed:
			_on_room_completed()
			return
		status_message = "进入休息房失败"
		_append_log(status_message)
		_refresh_display()
		return
	map_panel.visible = false
	enemy = room.get_enemy() if room.has_method("get_enemy") else null
	combat = room.get_combat() if room.has_method("get_combat") else null
	status_message = "等待行动"
	_append_log("战斗开始", "战斗开始：玩家进入%s。" % _get_room_type_cn(room_type))
	_refresh_display()
