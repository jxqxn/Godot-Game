from actions.card import ExhaustCardAction
from cards.ironclad.strike import Strike
from enemies.act1.cultist import Cultist
from powers.definitions.dark_embrace import DarkEmbracePower
from powers.definitions.feel_no_pain import FeelNoPainPower
from tests.test_combat_utils import create_test_helper


def test_exhaust_card_action_publishes_message_for_feel_no_pain_and_dark_embrace():
    helper = create_test_helper()
    try:
        player = helper.create_player(energy=3)
        enemy = helper.create_enemy(Cultist)
        helper.start_combat([enemy])

        exhaust_target = Strike()
        helper.add_card_to_hand(exhaust_target)
        helper.add_card_to_draw_pile(Strike())
        helper.add_card_to_draw_pile(Strike())
        helper.game_state.player.add_power(FeelNoPainPower(amount=4, owner=player))
        helper.game_state.player.add_power(DarkEmbracePower(amount=1, owner=player))

        initial_block = player.block
        initial_hand_size = len(player.card_manager.get_pile('hand'))

        ExhaustCardAction(card=exhaust_target, source_pile='hand').execute()
        helper.game_state.drive_actions()

        assert exhaust_target in player.card_manager.get_pile('exhaust_pile')
        assert player.block == initial_block + 4
        assert len(player.card_manager.get_pile('hand')) == initial_hand_size
    finally:
        helper._reset_game_state()
