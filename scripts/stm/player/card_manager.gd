class_name StmCardManager
extends RefCounted

var deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var exhaust_pile: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(initial_deck: Array = []) -> void:
	deck = initial_deck.duplicate()
	rng.seed = 20260522


func reset_for_combat() -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust_pile.clear()
	for card in deck:
		if card != null and card.has_method("copy"):
			draw_pile.append(card.copy())
		else:
			draw_pile.append(card)
	draw_pile = _shuffled_copy(draw_pile)


func get_pile(pile_name: String) -> Array:
	match pile_name:
		"deck":
			return deck
		"draw_pile":
			return draw_pile
		"discard_pile":
			return discard_pile
		"hand":
			return hand
		"exhaust_pile":
			return exhaust_pile
		_:
			return []


func get_hand_sorted_by_priority() -> Array:
	var entries: Array = []
	for index in range(hand.size()):
		var card = hand[index]
		entries.append({
			"card": card,
			"index": index,
			"priority": _card_play_priority(card),
		})
	entries.sort_custom(_compare_priority_entries)
	var sorted_hand: Array = []
	for entry in entries:
		sorted_hand.append(entry["card"])
	return sorted_hand


func find_highest_priority_playable_card(game_state):
	var sorted_hand: Array = get_hand_sorted_by_priority()
	for index in range(sorted_hand.size() - 1, -1, -1):
		var card = sorted_hand[index]
		if card != null and card.has_method("can_play") and card.can_play(game_state):
			return card
	return null


func add_to_pile(pile_name: String, card, pos_type = StmTypes.PilePosType.TOP) -> bool:
	var pile: Array = get_pile(pile_name)
	if pile.is_empty() and pile_name not in ["deck", "draw_pile", "discard_pile", "hand", "exhaust_pile"]:
		return false
	match int(pos_type):
		StmTypes.PilePosType.BOTTOM:
			pile.append(card)
		StmTypes.PilePosType.RANDOM:
			var index: int = rng.randi_range(0, pile.size())
			pile.insert(index, card)
		_:
			pile.push_front(card)
	return true


func get_card_location(card) -> String:
	if deck.has(card):
		return "deck"
	if draw_pile.has(card):
		return "draw_pile"
	if discard_pile.has(card):
		return "discard_pile"
	if hand.has(card):
		return "hand"
	if exhaust_pile.has(card):
		return "exhaust_pile"
	return ""


func remove_from_pile(pile_name: String, card) -> bool:
	var pile: Array = get_pile(pile_name)
	var index: int = pile.find(card)
	if index < 0:
		return false
	pile.remove_at(index)
	return true


func move_to(card, to_pile: String, pos_type = StmTypes.PilePosType.TOP) -> bool:
	if not _is_valid_pile_name(to_pile):
		return false
	var from_pile: String = get_card_location(card)
	if from_pile == "":
		return add_to_pile(to_pile, card, pos_type)
	if not remove_from_pile(from_pile, card):
		return false
	if add_to_pile(to_pile, card, pos_type):
		return true
	add_to_pile(from_pile, card, StmTypes.PilePosType.TOP)
	return false


func shuffle_discard_to_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile = _shuffled_copy(draw_pile)


func draw_one():
	if draw_pile.is_empty():
		shuffle_discard_to_draw()
	if draw_pile.is_empty():
		return null
	var card = draw_pile.pop_back()
	hand.append(card)
	return card


func draw_many(amount: int) -> Array:
	var drawn: Array = []
	var count: int = max(0, amount)
	for _i in count:
		var card = draw_one()
		if card == null:
			break
		drawn.append(card)
	return drawn


func discard(card) -> bool:
	if not hand.has(card):
		return false
	hand.erase(card)
	discard_pile.append(card)
	return true


func discard_card(card) -> bool:
	return discard(card)


func discard_hand() -> void:
	var cards = hand.duplicate()
	for card in cards:
		discard(card)


func exhaust_card(card) -> bool:
	var location: String = get_card_location(card)
	if location == "":
		return false
	remove_from_pile(location, card)
	exhaust_pile.append(card)
	return true


func _compare_priority_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority := int(a.get("priority", 0))
	var b_priority := int(b.get("priority", 0))
	if a_priority == b_priority:
		return int(a.get("index", 0)) < int(b.get("index", 0))
	return a_priority < b_priority


func _card_play_priority(card) -> int:
	if card != null and card.get("play_priority") != null:
		return int(card.get("play_priority"))
	return 0


func _shuffled_copy(source: Array) -> Array:
	var result: Array = source.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


func _is_valid_pile_name(pile_name: String) -> bool:
	return pile_name in ["deck", "draw_pile", "discard_pile", "hand", "exhaust_pile"]
