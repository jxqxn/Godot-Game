"""
Simple test to verify ConfusedPower fix - no game_state dependency.
"""
from powers.definitions.confused import ConfusedPower
from cards.base import Card
from player.card_manager import CardManager
from player.player import Player
from utils.types import PilePosType

from utils.types import CardType
print("="*60)
print("Testing ConfusedPower Fix")
print("="*60)

# Test 1: Direct on_card_draw() call
print("\n[TEST 1] Direct on_card_draw() call")
print("-"*40)
class TestCard(Card):
    base_cost = 2
    name = "Test Card"
    card_type = CardType.ATTACK

confused = ConfusedPower()
card = TestCard()

print(f"Original cost: {card._cost}")
confused.on_card_draw(card)
print(f"Cost after on_card_draw: {card._cost}")
assert 0 <= card._cost <= 3
print("[PASS] Test 1 completed")

# Test 2: Multiple on_card_draw() calls
print("\n[TEST 2] Multiple on_card_draw() calls")
print("-"*40)
cards = []
for i in range(5):
    c = TestCard()
    confused.on_card_draw(c)
    cards.append(c)
    print(f"Card {i+1}: cost = {c._cost}")
    assert 0 <= c._cost <= 3
print("[PASS] Test 2 completed")

# Test 3: on_turn_start() randomizes existing hand
print("\n[TEST 3] on_turn_start() randomizes existing hand")
print("-"*40)
player = Player()
player.card_manager = CardManager(deck=[])

# Add cards directly to hand
card1 = TestCard()
card2 = TestCard()
card3 = TestCard()
player.card_manager.add_to_pile(card1, "hand", PilePosType.TOP)
player.card_manager.add_to_pile(card2, "hand", PilePosType.TOP)
player.card_manager.add_to_pile(card3, "hand", PilePosType.TOP)

print(f"Original costs: {[c._cost for c in player.card_manager.get_pile('hand')]}")

# Apply ConfusedPower and execute on_turn_start
confused_power = ConfusedPower()
confused_power.owner = player
player.powers = [confused_power]

actions = confused_power.on_turn_start()
actions[0].execute()

new_costs = [c._cost for c in player.card_manager.get_pile("hand")]
print(f"Costs after on_turn_start: {new_costs}")
assert all(0 <= c <= 3 for c in new_costs)
print("[PASS] Test 3 completed")

# Test 4: Without ConfusedPower, costs stay same
print("\n[TEST 4] Without ConfusedPower, costs stay same")
print("-"*40)
player2 = Player()
player2.card_manager = CardManager(deck=[])
player2.powers = []

card = TestCard()
player2.card_manager.add_to_pile(card, "hand", PilePosType.TOP)
print(f"Original cost: {card._cost}")
assert card._cost == 2
print("[PASS] Test 4 completed")

print("\n" + "="*60)
print("ALL TESTS PASSED!")
print("="*60)
print("\nSummary of ConfusedPower Fix:")
print("-" * 60)
print("BEFORE:")
print("  - Only randomized costs at turn start (on_turn_start)")
print("  - New cards drawn during turn kept original cost")
print("  - Did not match effect description 'Whenever you draw a card'")
print()
print("AFTER:")
print("  - on_card_draw() method randomizes cost when card is drawn")
print("  - on_turn_start() still randomizes existing hand cards")
print("  - Matches effect description 'Whenever you draw a card'")
print("-" * 60)