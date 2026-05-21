from typing import cast

from actions.display import InputRequestAction
from events.hypnotizing_mushrooms import HypnotizingColoredMushrooms
from tests.test_combat_utils import create_test_helper
from tui.app import SelectionPanel
from utils.option import Option


def test_selection_panel_renders_option_effect_text():
    panel = SelectionPanel()

    lines = panel._build_selection_lines(
        title="Event",
        options=[Option(name="Eat", actions=[], detail="Heal 25% HP. Gain Parasite.")],
        max_select=1,
        must_select=True,
    )

    rendered = "\n".join(lines)
    assert "Heal 25% HP. Gain Parasite." in rendered


def test_hypnotizing_mushrooms_options_expose_effect_text():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.floor_in_act = 11
    helper.game_state.action_queue.clear()

    event = HypnotizingColoredMushrooms()
    event.trigger()

    menu = cast(InputRequestAction, helper.game_state.action_queue.queue[-1])
    assert isinstance(menu, InputRequestAction)

    assert getattr(menu.options[0], "detail", None) is not None
    assert getattr(menu.options[1], "detail", None) is not None
