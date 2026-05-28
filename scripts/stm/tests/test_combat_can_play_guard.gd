extends GutTest

const GameBootstrapScript := preload("res://scripts/stm/tests/test_bootstrap.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")


class RejectingCard:
	extends RefCounted

	var card_name: String = "拒绝出牌"
	var cost: int = 0
	var play_called: bool = false

	func can_play(_game_state) -> bool:
		return false

	func play(_game_state, _combat = null, _targets := []) -> Array:
		play_called = true
		return []


func test_combat_play_card_respects_card_can_play_guard() -> void:
	# Given：一场已开始的战斗，并把一张 can_play() 明确返回 false 的牌放入手牌。
	var bootstrap = GameBootstrapScript.new()
	var game_state = bootstrap.create_test_game()
	var combat = bootstrap.create_test_combat(game_state)
	combat.start(game_state)
	var card = RejectingCard.new()
	game_state.player.card_manager.hand = [card]
	var starting_energy: int = game_state.player.energy
	# When：外部代码绕过 UI，直接通过 Combat 公共入口尝试打出这张牌。
	var result = combat.play_card(game_state, card, [])
	# Then：规则层仍应拒绝出牌，不扣能量、不调用卡牌 play()、不移动到弃牌堆。
	assert_eq(result, TypesScript.TerminalResult.NONE)
	assert_eq(game_state.player.energy, starting_energy)
	assert_false(card.play_called)
	assert_true(game_state.player.card_manager.hand.has(card))
	assert_false(game_state.player.card_manager.discard_pile.has(card))
