from actions.combat import ModifyMaxHpAction
from tests.test_combat_utils import create_test_helper


def test_modify_max_hp_action_does_not_use_legacy_hook():
    helper = create_test_helper()
    player = helper.create_player(hp=50, max_hp=50, energy=3)
    initial_hp = player.hp
    initial_max_hp = player.max_hp

    def fail(*args, **kwargs):
        raise AssertionError("legacy on_max_hp_changed hook should not be used")

    player.on_max_hp_changed = fail

    result = ModifyMaxHpAction(amount=7).execute()

    assert result is None
    assert player.max_hp == initial_max_hp + 7
    assert player.hp == initial_hp + 7
