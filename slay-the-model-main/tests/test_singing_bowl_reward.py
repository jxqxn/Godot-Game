from actions.card_choice import ChooseObtainCardAction
from actions.display import InputRequestAction
from relics.global_relics.uncommon import SingingBowl
from tests.test_combat_utils import create_test_helper
from typing import cast


def test_choose_obtain_card_action_includes_singing_bowl_option():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.namespace = "ironclad"
    player.character = "Ironclad"
    player.relics = [SingingBowl()]

    ChooseObtainCardAction(total=1, namespace="ironclad").execute()

    queued = helper.game_state.action_queue.peek_next()
    assert isinstance(queued, InputRequestAction)
    queued = cast(InputRequestAction, queued)
    assert any("Max HP" in str(option.name) for option in queued.options)


def test_choose_obtain_card_action_allows_skip_by_default_without_extra_option():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.namespace = "ironclad"
    player.character = "Ironclad"

    ChooseObtainCardAction(total=1, namespace="ironclad").execute()

    queued = helper.game_state.action_queue.peek_next()
    assert isinstance(queued, InputRequestAction)
    queued = cast(InputRequestAction, queued)

    assert queued.must_select is False
    assert not any("Skip" in str(option.name) for option in queued.options)


def test_choose_obtain_card_action_can_disable_skip():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.namespace = "ironclad"
    player.character = "Ironclad"

    ChooseObtainCardAction(total=1, namespace="ironclad", can_skip=False).execute()

    queued = helper.game_state.action_queue.peek_next()
    assert isinstance(queued, InputRequestAction)
    queued = cast(InputRequestAction, queued)

    assert queued.must_select is True
    assert not any("Skip" in str(option.name) for option in queued.options)
