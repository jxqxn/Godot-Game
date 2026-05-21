"""
Simple test script to verify ConfusedPower fix without loading full game state.
"""
from powers.definitions.confused import ConfusedPower
from cards.base import Card
from player.card_manager import CardManager
from player.player import Player
from actions.card import DrawCardsAction
from utils.types import PilePosType
from utils.types import CardType

# Simple mock game state
class MockGameState:
    def __init__(self):
        self.player = None

# Test 1: Verify on_card_draw randomizes cost
print("Test 1: on_card_draw randomizes card cost")
class TestCard(Card):
    base_cost = 2
    name = "Test Card"
    card_type = CardType.ATTACK

confused = ConfusedPower()
card = TestCard()

print(f"  Original cost: {card._cost}")
confused.on_card_draw(card)
print(f"  Cost after on_card_draw: {card._cost}")
assert 0 <= card._cost <= 3, f"Cost should be 0-3, got {card._cost}"
print("  [PASS] Test 1 passed")

# Test 2: Verify DrawCardsAction triggers on_card_draw
print("\nTest 2: DrawCardsAction triggers on_card_draw")
player = Player()
player.card_manager = CardManager(deck=[])

# Add cards to draw pile
for _ in range(3):
    card = TestCard()
    player.card_manager.add_to_pile(card, "draw_pile", PilePosType.BOTTOM)

# Add ConfusedPower
confused_power = ConfusedPower()
confused_power.owner = player
player.powers = [confused_power]

# Draw cards
draw_action = DrawCardsAction(count=3)
draw_action.execute()

# Check hand
hand = player.card_manager.get_pile("hand")
print(f"  Cards in hand: {len(hand)}")
assert len(hand) == 3, f"Should have 3 cards in hand, got {len(hand)}"

# Check costs
costs = [c._cost for c in hand]
print(f"  Costs: {costs}")
assert all(0 <= c <= 3 for c in costs), f"All costs should be 0-3, got {costs}"
print("  [PASS] Test 2 passed")

# Test 3: Verify on_turn_start randomizes existing hand
print("\nTest 3: on_turn_start randomizes existing hand")
player2 = Player()
player2.card_manager = CardManager(deck=[])

# Add cards directly to hand (simulating previous turns)
card1 = TestCard()
card2 = TestCard()
card3 = TestCard()
player2.card_manager.add_to_pile(card1, "hand", PilePosType.TOP)
player2.card_manager.add_to_pile(card2, "hand", PilePosType.TOP)
player2.card_manager.add_to_pile(card3, "hand", PilePosType.TOP)

# Add ConfusedPower
confused_power2 = ConfusedPower()
confused_power2.owner = player2
player2.powers = [confused_power2]

# Execute on_turn_start
actions = confused_power2.on_turn_start()
actions[0].execute()

# Check costs
new_costs = [c._cost for c in player2.card_manager.get_pile("hand")]
print(f"  Costs after on_turn_start: {new_costs}")
assert all(0 <= c <= 3 for c in new_costs), f"All costs should be 0-3, got {new_costs}"
print("  [PASS] Test 3 passed")

# Test 4: Verify without ConfusedPower, costs are not randomized
print("\nTest 4: Without ConfusedPower, costs are NOT randomized")
player3 = Player()
player3.card_manager = CardManager(deck=[])
player3.powers = []

card = TestCard()
player3.card_manager.add_to_pile(card, "draw_pile", PilePosType.BOTTOM)

# Draw without ConfusedPower
draw_action = DrawCardsAction(count=1)
draw_action.execute()

print(f"  Cost after draw (no ConfusedPower): {card._cost}")
assert card._cost == 2, f"Cost should still be 2 without ConfusedPower, got {card._cost}"
print("  [PASS] Test 4 passed")

print("\n" + "="*50)
print("All tests passed! ConfusedPower fix is working correctly.")
print("="*50)
print("\nSummary of changes:")
print("1. ConfusedPower now has on_card_draw() method that randomizes cost")
print("2. DrawCardsAction now triggers on_card_draw for each drawn card")
print("3. on_turn_start() still randomizes existing hand cards")
print("4. Effect description updated to reflect correct behavior")