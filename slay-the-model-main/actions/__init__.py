"""Lazy action package surface.

This module avoids importing the entire action graph at package import time,
which keeps type checkers from reporting large import cycles while preserving
the existing public API.
"""

from importlib import import_module
from typing import Any

from actions.base import Action, ActionQueue
from utils.result_types import GameTerminalState


_LAZY_EXPORTS = {
    "DisplayTextAction": ("actions.display", "DisplayTextAction"),
    "InputRequestAction": ("actions.display", "InputRequestAction"),
    "AddRandomCardAction": ("actions.card", "AddRandomCardAction"),
    "ChooseExhaustCardAction": ("actions.card", "ChooseExhaustCardAction"),
    "ChooseMoveCardAction": ("actions.card", "ChooseMoveCardAction"),
    "ChooseRemoveCardAction": ("actions.card", "ChooseRemoveCardAction"),
    "ChooseReplaceCardAction": ("actions.card", "ChooseReplaceCardAction"),
    "ChooseTransformCardAction": ("actions.card", "ChooseTransformCardAction"),
    "ChooseUpgradeCardAction": ("actions.card", "ChooseUpgradeCardAction"),
    "CopyCardAction": ("actions.card", "CopyCardAction"),
    "DrawCardsAction": ("actions.card", "DrawCardsAction"),
    "ExhaustCardAction": ("actions.card", "ExhaustCardAction"),
    "ExhaustRandomCardAction": ("actions.card", "ExhaustRandomCardAction"),
    "MoveCardAction": ("actions.card", "MoveCardAction"),
    "RemoveCardAction": ("actions.card", "RemoveCardAction"),
    "ReplaceCardAction": ("actions.card", "ReplaceCardAction"),
    "ShuffleAction": ("actions.card", "ShuffleAction"),
    "TransformCardAction": ("actions.card", "TransformCardAction"),
    "UpgradeAllCardsAction": ("actions.card", "UpgradeAllCardsAction"),
    "UpgradeCardAction": ("actions.card", "UpgradeCardAction"),
    "TriggerRelicAction": ("actions.combat", "TriggerRelicAction"),
    "ApplyPowerAction": ("actions.combat", "ApplyPowerAction"),
    "AttackAction": ("actions.combat", "AttackAction"),
    "DealDamageAction": ("actions.combat", "DealDamageAction"),
    "HealAction": ("actions.combat", "HealAction"),
    "UsePotionAction": ("actions.combat", "UsePotionAction"),
    "GameOverAction": ("actions.game_over", "GameOverAction"),
}


def __getattr__(name: str) -> Any:
    if name not in _LAZY_EXPORTS:
        raise AttributeError(f"module 'actions' has no attribute {name!r}")

    module_name, attr_name = _LAZY_EXPORTS[name]
    value = getattr(import_module(module_name), attr_name)
    globals()[name] = value
    return value


__all__ = [
    "Action",
    "ActionQueue",
    "GameTerminalState",
    *_LAZY_EXPORTS.keys(),
]
