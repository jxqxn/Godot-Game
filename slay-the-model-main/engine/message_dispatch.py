"""Class-level message subscriber dispatch."""
from __future__ import annotations

from typing import List

from engine.message_contracts import invoke_subscription_contract
from engine.message_helpers import as_actions
from engine.messages import GameMessage
from engine.subscriptions import iter_bound_subscribers


def invoke_subscription(bound_method, message: GameMessage, method_name: str | None = None) -> List:
    result = invoke_subscription_contract(bound_method, message, method_name=method_name)
    if result is None:
        return []
    return as_actions(result)


def dispatch_class_level_subscribers(message: GameMessage, participants: List | None = None) -> List:
    actions: List = []
    subscriber_calls = []
    for participant_index, participant in enumerate(participants or []):
        for order, name, bound_method, spec in iter_bound_subscribers(participant, message):
            subscriber_calls.append((order, participant_index, name, bound_method, spec))
    subscriber_calls.sort(key=lambda item: (item[0], item[1], item[2]))
    for _order, _participant_index, name, bound_method, _spec in subscriber_calls:
        result = invoke_subscription(bound_method, message, method_name=name)
        if not result:
            continue
        actions.extend(as_actions(result))
    return actions
