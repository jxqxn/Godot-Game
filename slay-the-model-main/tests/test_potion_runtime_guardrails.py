from cards.ironclad.strike import Strike
from cards.silent.eviscerate import Eviscerate
from actions.display import InputRequestAction
from potions.global_potions import LiquidMemories, SneckoOil
from tests.test_combat_utils import CombatTestHelper
from typing import cast


def test_snecko_oil_randomizes_hand_with_end_of_turn_cost_override():
    helper = CombatTestHelper()
    player = helper.create_player()
    helper.start_combat([])

    first = Eviscerate()
    second = Strike()
    helper.add_card_to_hand(first)
    helper.add_card_to_hand(second)

    potion = SneckoOil()
    potion.on_use([])
    helper.game_state.drive_actions()

    assert first.cost_until_end_of_turn is not None
    assert second.cost_until_end_of_turn is not None
    assert 0 <= first.cost_until_end_of_turn <= 3
    assert 0 <= second.cost_until_end_of_turn <= 3


def test_liquid_memories_reads_discard_pile_name():
    helper = CombatTestHelper()
    player = helper.create_player()
    helper.start_combat([])

    discarded = Strike()
    helper.add_card_to_discard_pile(discarded)

    potion = LiquidMemories()
    potion.on_use([])

    input_request = cast(InputRequestAction, helper.game_state.action_queue.peek_next())
    option_names = [str(option.name) for option in input_request.options]
    assert any("Strike" in name for name in option_names)
