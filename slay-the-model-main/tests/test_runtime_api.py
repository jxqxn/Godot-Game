from actions.base import LambdaAction
from actions.display import InputRequestAction
from engine.game_state import GameState
from engine.messages import HealedMessage
from utils.option import Option
from utils.result_types import GameTerminalState


def test_runtime_api_operates_on_global_game_state(monkeypatch):
    from engine import game_state as gs_module
    from engine.runtime_api import (
        add_action,
        add_actions,
        publish_message,
        request_input,
        set_terminal_state,
    )

    gs = GameState()
    executed = []

    original_game_state = gs_module.game_state
    try:
        gs_module.game_state = gs

        add_action(LambdaAction(lambda: executed.append("one")))
        add_actions([LambdaAction(lambda: executed.append("two"))])

        request = InputRequestAction(
            title="test",
            options=[Option(name="ok", actions=[])],
        ).request
        request_input(request)
        assert gs.pending_input_request is request

        set_terminal_state(GameTerminalState.GAME_EXIT)
        assert gs.terminal_state == GameTerminalState.GAME_EXIT

        gs.terminal_state = None
        gs.pending_input_request = None
        gs.player.relics = []
        publish_message(HealedMessage(target=gs.player, amount=1, previous_hp=1, new_hp=2))

        gs.drive_actions()
        assert executed == ["one", "two"]
    finally:
        gs_module.game_state = original_game_state
