"""Module-level runtime scheduler helpers over the global game_state."""

from typing import TYPE_CHECKING

from engine.input_protocol import InputRequest
from utils.result_types import GameTerminalState

if TYPE_CHECKING:
    from engine.messages import GameMessage


def _get_game_state():
    from engine.game_state import game_state

    return game_state


def add_action(action, to_front: bool = False) -> None:
    _get_game_state().add_action(action, to_front=to_front)


def add_actions(actions, to_front: bool = False) -> None:
    _get_game_state().add_actions(actions, to_front=to_front)


def publish_message(message: "GameMessage") -> None:
    _get_game_state().publish_message(message)


def request_input(request: InputRequest) -> None:
    _get_game_state().request_input(request)


def set_terminal_state(state: GameTerminalState) -> None:
    _get_game_state().set_terminal_state(state)
