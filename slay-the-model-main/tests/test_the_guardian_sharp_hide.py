from cards.ironclad.strike import Strike
from enemies.act1.the_guardian import TheGuardian
from tests.test_combat_utils import create_test_helper


def test_guardian_defensive_mode_applies_sharp_hide_and_reflects_attack_damage():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    guardian = TheGuardian()
    helper.start_combat([guardian])

    guardian.intentions["defensive_mode"].execute()
    helper.game_state.drive_actions()

    sharp_hide = guardian.get_power("SharpHide")
    assert sharp_hide is not None
    assert sharp_hide.amount == 3

    strike = Strike()
    helper.add_card_to_hand(strike)

    assert helper.play_card(strike, guardian) is True
    helper.game_state.drive_actions()

    assert player.hp == 77
