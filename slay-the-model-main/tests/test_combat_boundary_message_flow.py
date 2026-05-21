from enemies.act1.cultist import Cultist
from cards.ironclad.strike import Strike
from relics.character.ironclad import BurningBlood
from relics.global_relics.common import Anchor, BagOfPreparation
from tests.test_combat_utils import create_test_helper
from utils.result_types import GameTerminalState


def _capture_published_message_types(game_state, monkeypatch):
    original_publish = game_state.publish_message
    published = []

    def wrapped(message, *args, **kwargs):
        published.append(type(message).__name__)
        return original_publish(message, *args, **kwargs)

    monkeypatch.setattr(game_state, "publish_message", wrapped)
    return published


def test_init_combat_publishes_combat_started_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.relics = [BagOfPreparation()]
    player.deck = [Strike(), Strike()]
    enemy = helper.create_enemy(Cultist, hp=20)

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    helper.start_combat([enemy])
    helper.game_state.drive_actions()

    assert "CombatStartedMessage" in published
    assert len(player.card_manager.get_pile("hand")) >= 2


def test_start_player_turn_publishes_turn_started_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.relics.append(Anchor())
    enemy = helper.create_enemy(Cultist, hp=20)
    combat = helper.start_combat([enemy])

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    combat._start_player_turn()
    helper.game_state.drive_actions()

    assert "PlayerTurnStartedMessage" in published
    assert player.block == 10


def test_end_player_phase_publishes_turn_ended_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    enemy = helper.create_enemy(Cultist, hp=20)
    combat = helper.start_combat([enemy])

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    combat._end_player_phase()

    assert "PlayerTurnEndedMessage" in published


def test_check_combat_end_publishes_combat_ended_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=50, max_hp=80, energy=3)
    player.relics = [BurningBlood()]
    enemy = helper.create_enemy(Cultist, hp=1)
    combat = helper.start_combat([enemy])
    enemy.hp = 0
    initial_hp = player.hp

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    result = combat._check_combat_end()

    assert result == GameTerminalState.COMBAT_WIN
    assert "CombatEndedMessage" in published
    assert player.hp == initial_hp + 6
