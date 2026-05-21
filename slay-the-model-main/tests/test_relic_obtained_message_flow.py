from actions.combat import GainBlockAction
from actions.reward import AddRandomRelicAction, AddRelicAction, AddRelicByNameAction
from engine.message_bus import MessageBus
from engine.messages import RelicObtainedMessage
from engine.subscriptions import MessagePriority, subscribe
from relics.base import Relic
from tests.test_combat_utils import create_test_helper


def _capture_published_message_types(game_state, monkeypatch):
    original_publish = game_state.publish_message
    published = []

    def wrapped(message, *args, **kwargs):
        published.append(type(message).__name__)
        return original_publish(message, *args, **kwargs)

    monkeypatch.setattr(game_state, "publish_message", wrapped)
    return published


class _ObtainRelic(Relic):
    def __init__(self):
        super().__init__()
        self.triggered = False

    @subscribe(RelicObtainedMessage, priority=MessagePriority.PLAYER_RELIC)
    def on_obtain(self):
        self.triggered = True
        from engine.game_state import game_state

        return [GainBlockAction(block=7, target=game_state.player)]


def test_message_bus_dispatches_relic_obtained_subscription():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    relic = _ObtainRelic()

    actions = MessageBus().publish(
        RelicObtainedMessage(owner=player, relic=relic),
        participants=[relic],
    )

    assert relic.triggered is True
    assert len(actions) == 1
    assert isinstance(actions[0], GainBlockAction)


def test_add_relic_action_publishes_relic_obtained_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    relic = _ObtainRelic()

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    AddRelicAction(relic=relic).execute()
    helper.game_state.drive_actions()

    assert "RelicObtainedMessage" in published
    assert relic in player.relics
    assert relic.triggered is True
    assert player.block == 7


def test_add_relic_by_name_action_publishes_relic_obtained_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    relic = _ObtainRelic()

    published = _capture_published_message_types(helper.game_state, monkeypatch)
    monkeypatch.setattr("actions.reward.get_registered_instance", lambda *_args, **_kwargs: relic)

    AddRelicByNameAction(relic_id="TestRelic").execute()
    helper.game_state.drive_actions()

    assert "RelicObtainedMessage" in published
    assert relic in player.relics
    assert relic.triggered is True
    assert player.block == 7


def test_add_random_relic_action_publishes_relic_obtained_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    relic = _ObtainRelic()

    published = _capture_published_message_types(helper.game_state, monkeypatch)
    monkeypatch.setattr("actions.reward.get_random_relic", lambda **_kwargs: relic)

    AddRandomRelicAction().execute()
    helper.game_state.drive_actions()

    assert "RelicObtainedMessage" in published
    assert relic in player.relics
    assert relic.triggered is True
    assert player.block == 7
