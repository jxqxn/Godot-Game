class_name StmCombat
extends RefCounted

var enemies: Array = []
var combat_type: String = "normal"
var combat_state: StmCombatState = StmCombatState.new()


func _init(p_enemies: Array = [], p_combat_type: String = "normal") -> void:
	enemies = p_enemies.duplicate()
	combat_type = p_combat_type


func start(game_state) -> void:
	game_state.current_combat = self
	combat_state.reset_combat_info()
	if game_state.player != null and game_state.player.card_manager != null:
		game_state.player.card_manager.reset_for_combat()
	start_player_turn(game_state)


func start_player_turn(game_state) -> void:
	combat_state.combat_turn += 1
	combat_state.reset_turn_info()
	combat_state.current_phase = "player_start"
	if game_state.player == null:
		return
	game_state.player.energy = game_state.player.max_energy
	if game_state.player.card_manager != null:
		game_state.player.card_manager.draw_many(game_state.player.draw_count)


func play_card(game_state, card, targets: Array = []):
	if game_state.player == null or card == null:
		return _result_none()
	var cost: int = int(card.get("cost") if "cost" in card else 0)
	if game_state.player.energy < cost:
		return _result_none()
	game_state.player.energy -= cost
	combat_state.player_energy_spent_this_turn += cost
	combat_state.turn_cards_played += 1
	if card.has_method("play"):
		card.play(game_state, self, targets)
	var card_manager = game_state.player.card_manager
	if card_manager != null and card_manager.has_method("discard_card"):
		card_manager.discard_card(card)
	return check_combat_end(game_state)


func end_turn(game_state):
	execute_player_end(game_state)
	execute_enemy_turn(game_state)
	var result = check_combat_end(game_state)
	if result == _result_none():
		start_player_turn(game_state)
	return result


func execute_player_end(game_state) -> void:
	if game_state.player == null or game_state.player.card_manager == null:
		return
	if game_state.player.card_manager.has_method("discard_hand"):
		game_state.player.card_manager.discard_hand()
	game_state.player.block = 0
	combat_state.current_phase = "enemy_turn"


func execute_enemy_turn(game_state) -> void:
	if game_state.player == null:
		return
	for enemy in enemies:
		if enemy == null:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var damage: int = 0
		if enemy.has_method("get_intended_damage"):
			damage = int(enemy.get_intended_damage())
		elif "intent_damage" in enemy:
			damage = int(enemy.intent_damage)
		elif "damage" in enemy:
			damage = int(enemy.damage)
		if damage > 0:
			if game_state.player.has_method("take_damage"):
				game_state.player.take_damage(damage, enemy)
			else:
				_apply_player_damage_with_block(game_state.player, damage)
		if enemy.has_method("end_turn"):
			enemy.end_turn(game_state, self)
	combat_state.current_phase = "player_start"


func check_combat_end(game_state):
	var alive_count := 0
	for enemy in enemies:
		if enemy == null:
			continue
		var is_dead := false
		if enemy.has_method("is_dead"):
			is_dead = enemy.is_dead()
		elif "hp" in enemy:
			is_dead = int(enemy.hp) <= 0
		if not is_dead:
			alive_count += 1
	if alive_count == 0:
		return _result_win()
	if game_state.player != null:
		var player_dead := false
		if game_state.player.has_method("is_dead"):
			player_dead = game_state.player.is_dead()
		elif "hp" in game_state.player:
			player_dead = int(game_state.player.hp) <= 0
		if player_dead:
			return _result_lose()
	return _result_none()


func _apply_player_damage_with_block(player, damage: int) -> void:
	var block = int(player.get("block") if "block" in player else 0)
	var blocked = min(block, damage)
	var remain = damage - blocked
	player.block = block - blocked
	if remain > 0 and "hp" in player:
		player.hp -= remain


func _result_none():
	return _read_terminal_result("NONE", 0)


func _result_win():
	return _read_terminal_result("COMBAT_WIN", 1)


func _result_lose():
	return _read_terminal_result("COMBAT_LOSE", 2)


func _read_terminal_result(key: String, fallback: int):
	var path = "res://scripts/stm/utils/types.gd"
	if not FileAccess.file_exists(path):
		return fallback
	var script = load(path)
	if script == null:
		return fallback
	var terminal = script.get("TerminalResult")
	if typeof(terminal) == TYPE_DICTIONARY and terminal.has(key):
		return terminal[key]
	return fallback
