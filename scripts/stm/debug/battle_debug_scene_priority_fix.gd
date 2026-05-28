extends "res://scripts/stm/debug/battle_debug_scene.gd"


func _play_card_from_hand(card) -> void:
	if game_state == null or combat == null or game_state.player == null:
		status_message = "战斗尚未开始"
		_append_log("出牌失败")
		_refresh_display()
		return
	if not _can_play_card_from_hand(card):
		status_message = "无法打出%s" % _card_display_name(card)
		_append_log(status_message)
		_refresh_display()
		return
	var targets: Array = []
	if _card_targets_enemy(card):
		var target = _first_alive_enemy()
		if target == null:
			status_message = "没有可选敌人"
			_append_log(status_message)
			_refresh_display()
			return
		targets.append(target)
	elif _card_targets_self(card):
		targets.append(game_state.player)
	var before_player := _player_snapshot()
	var before_enemy_hp := _enemy_hp_value()
	var result = combat.play_card(game_state, card, targets)
	status_message = _result_message(result, "已打出%s" % _card_display_name(card))
	_append_card_log(card, before_player, before_enemy_hp, result)
	if result == TypesScript.TerminalResult.COMBAT_WIN:
		_finish_combat_result(result)
		return
	_refresh_display()


func _can_play_card_from_hand(card) -> bool:
	if game_state == null or combat == null or game_state.player == null or game_state.player.card_manager == null:
		return false
	if not game_state.player.card_manager.get_pile("hand").has(card):
		return false
	if card != null and card.has_method("can_play") and not card.can_play(game_state):
		return false
	if _card_targets_enemy(card) and _first_alive_enemy() == null:
		return false
	if _card_targets_self(card) and game_state.player == null:
		return false
	return true


func _pile_text(title: String, pile_name: String) -> String:
	if game_state == null or game_state.player == null:
		return "%s（0）：无" % title
	var pile: Array = []
	if pile_name == "hand" and game_state.player.card_manager.has_method("get_hand_sorted_by_priority"):
		pile = game_state.player.card_manager.get_hand_sorted_by_priority()
	else:
		pile = game_state.player.card_manager.get_pile(pile_name)
	if pile.is_empty():
		return "%s（0）：无" % title
	var names := PackedStringArray()
	for card in pile:
		names.append(_card_display_name(card))
	return "%s（%d）：%s" % [title, pile.size(), ", ".join(names)]


func _card_targets_enemy(card) -> bool:
	var target_kind := _card_target_kind(card)
	return target_kind == "enemy" or target_kind == "all_enemies"


func _card_targets_self(card) -> bool:
	return _card_target_kind(card) == "self"


func _card_target_kind(card) -> String:
	if card == null:
		return "none"
	var raw_target = card.get("target_type")
	if raw_target == null:
		return "none"
	if typeof(raw_target) == TYPE_INT:
		match int(raw_target):
			StmTypes.TargetType.SELF:
				return "self"
			StmTypes.TargetType.ENEMY:
				return "enemy"
			StmTypes.TargetType.ALL_ENEMIES:
				return "all_enemies"
			StmTypes.TargetType.ALL:
				return "all"
			_:
				return "none"
	var target_text := str(raw_target).to_lower()
	match target_text:
		"self", "targettype.self":
			return "self"
		"enemy", "enemy_select", "targettype.enemy":
			return "enemy"
		"all_enemies", "all_enemy", "targettype.all_enemies":
			return "all_enemies"
		"all", "targettype.all":
			return "all"
		_:
			return "none"
