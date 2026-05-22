class_name StmGameBootstrap
extends RefCounted

const GAME_STATE_PATH := "res://scripts/stm/engine/game_state.gd"
const COMBAT_PATH := "res://scripts/stm/engine/combat.gd"
const CLASS_PATHS := {
	"StmStrike": "res://scripts/stm/cards/test/strike.gd",
	"StmDefend": "res://scripts/stm/cards/test/defend.gd",
	"StmPlayer": "res://scripts/stm/player/player.gd",
	"StmDummyEnemy": "res://scripts/stm/enemies/test/dummy_enemy.gd",
}


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
	if CLASS_PATHS.has(class_name_text):
		var explicit_script = load(CLASS_PATHS[class_name_text])
		if explicit_script != null:
			return _new_with_args(explicit_script, args)
	for item in ProjectSettings.get_global_class_list():
		if item.get("class") == class_name_text:
			var path = item.get("path", "")
			if path == "":
				break
			var script = load(path)
			if script == null:
				break
			return _new_with_args(script, args)
	return null


func _new_with_args(script, args: Array):
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
