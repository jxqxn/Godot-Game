from dataclasses import dataclass

from actions.base import Action
from engine.message_bus import MessageBus
from engine.messages import GameMessage


class _MarkerAction(Action):
    def __init__(self, label):
        self.label = label

    def execute(self):
        return None


@dataclass(frozen=True)
class _DummyMessage(GameMessage):
    value: str


class _HighPriorityHandler:
    priority = 10

    def handles(self, message):
        return isinstance(message, _DummyMessage)

    def handle(self, message):
        return [_MarkerAction(f'high:{message.value}')]


class _LowPriorityHandler:
    priority = 20

    def handles(self, message):
        return isinstance(message, _DummyMessage)

    def handle(self, message):
        return [_MarkerAction(f'low:{message.value}')]


def test_message_bus_collects_actions_in_priority_order():
    bus = MessageBus()
    bus.register(_LowPriorityHandler())
    bus.register(_HighPriorityHandler())

    actions = bus.publish(_DummyMessage('x'))

    assert [action.label for action in actions] == ['high:x', 'low:x']
