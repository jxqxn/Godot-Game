class_name StmGameBootstrap
extends RefCounted

const GAME_STATE_PATH := "res://scripts/stm/engine/game_state.gd"
const COMBAT_PATH := "res://scripts/stm/engine/combat.gd"


func create_test_game():
	var strike_1 = _new_global("StmStrike")
	var defend_1 = _new_global("StmDefend")
	var strike_2 = _new_global("StmStrike")
	var defend_2 = _new_global("StmDefend")
	var deck: Array = [strike_1, defend_1, strike_2, defend_2]
	var player = _new_global("StmPlayer", [deck])
	var game_state_script = load(GAME_STATE_PATH)
	var game_state = game_state_script.new(player)
	return game_state


func create_test_combat(game_state):
	var enemy = _new_global("StmDummyEnemy")
	var combat_script = load(COMBAT_PATH)
	var combat = combat_script.new([enemy], "normal")
	game_state.current_combat = combat
	return combat


func _new_global(class_name_text: String, args: Array = []):
	for item in ProjectSettings.get_global_class_list():
		if item.get("class") == class_name_text:
			var path = item.get("path", "")
			if path == "":
				break
			var script = load(path)
			if script == null:
				break
			match args.size():
				0:
					return script.new()
				1:
					return script.new(args[0])
				2:
					return script.new(args[0], args[1])
				3:
					return script.new(args[0], args[1], args[2])
				_:
					return script.new()
	return null
