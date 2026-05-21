"""Public message bus API and legacy handler exports."""
from __future__ import annotations

from typing import List, Protocol, runtime_checkable

from engine.message_dispatch import dispatch_class_level_subscribers
from engine.message_helpers import as_actions
from engine.messages import GameMessage


@runtime_checkable
class MessageHandler(Protocol):
    """Protocol for message handlers that emit follow-up actions."""

    priority: int

    def handles(self, message: GameMessage) -> bool:
        ...

    def handle(self, message: GameMessage) -> List:
        ...


class MessageBus:
    """Collect follow-up actions from registered handlers and class subscribers."""

    def __init__(self):
        self._handlers: List[MessageHandler] = []

    def register(self, handler: MessageHandler) -> None:
        self._handlers.append(handler)
        self._handlers.sort(key=lambda current: getattr(current, "priority", 0))

    def publish(self, message: GameMessage, participants: List | None = None) -> List:
        if participants is None:
            try:
                from engine.game_state import game_state
                participants = game_state.runtime_context.message_participants_for_message(message)
            except Exception:
                participants = []
        actions: List = []
        for handler in self._handlers:
            if not handler.handles(message):
                continue
            result = handler.handle(message)
            if not result:
                continue
            actions.extend(as_actions(result))
        actions.extend(dispatch_class_level_subscribers(message, participants=participants))
        return actions
