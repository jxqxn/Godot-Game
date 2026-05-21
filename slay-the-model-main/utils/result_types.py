"""Terminal game-state enums used at runtime boundaries."""

from enum import Enum


class GameTerminalState(str, Enum):
    COMBAT_WIN = "COMBAT_WIN"
    GAME_WIN = "GAME_WIN"
    COMBAT_ESCAPE = "COMBAT_ESCAPE"
    GAME_LOSE = "GAME_LOSE"
    GAME_EXIT = "GAME_EXIT"
