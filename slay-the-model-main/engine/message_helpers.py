"""Shared helpers for message dispatch and legacy handler adaptation."""
from __future__ import annotations

from typing import Iterable, List


def as_actions(result) -> List:
    if not result:
        return []
    if isinstance(result, list):
        return [action for action in result if action is not None]
    return [result]


def invoke_hook(subject, method_name: str, *args, **kwargs) -> List:
    hook = getattr(subject, method_name, None)
    if not hook:
        return []

    call_patterns = [
        lambda: hook(*args, **kwargs),
        lambda: hook(*args),
        lambda: hook(),
    ]
    for attempt in call_patterns:
        try:
            return as_actions(attempt())
        except TypeError:
            continue
    return []


def alive_entities_from_game_state() -> List:
    from engine.game_state import game_state

    combat = getattr(game_state, "current_combat", None)
    if combat is None:
        return []
    return [entity for entity in getattr(combat, "enemies", []) if getattr(entity, "hp", 0) > 0]


def iter_player_relics(owner) -> Iterable:
    for relic in list(getattr(owner, "relics", [])):
        yield relic


def iter_owner_powers(owner) -> Iterable:
    for power in list(getattr(owner, "powers", [])):
        yield power
