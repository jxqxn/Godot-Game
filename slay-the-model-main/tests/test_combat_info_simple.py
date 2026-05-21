"""
Test P2-2 combat info display.
"""
import types
from typing import Any, cast


def test_combat_snapshot_uses_runtime_event_layer(monkeypatch):
    from engine import runtime_presenter
    from engine.combat import Combat
    from engine.game_state import game_state
    from engine.runtime_events import drain_runtime_events, get_runtime_events
    from engine.runtime_presenter import flush_runtime_events

    rendered = []
    monkeypatch.setattr(runtime_presenter, "render_runtime_event", lambda event: rendered.append(event))

    class DummyCardManager:
        def get_pile(self, name):
            return []

    class DummyPower:
        def __init__(self, name="DummyPower", amount=None, duration=-1):
            self.name = name
            self.amount = amount
            self.duration = duration
            self.localization_prefix = "powers"

        def local(self, field, **kwargs):
            return types.SimpleNamespace(resolve=lambda: f"{self.name}.{field}")

    class DummyCreature:
        def __init__(self, name="Dummy"):
            self.name = name
            self.hp = 10
            self.max_hp = 10
            self.block = 0
            self.energy = 3
            self.max_energy = 3
            self.draw_count = 5
            self.card_manager = DummyCardManager()
            self.relics = []
            self.powers = []
            self.current_intention = None

        def is_dead(self):
            return False

        def local(self, field, **kwargs):
            return types.SimpleNamespace(resolve=lambda: f"{self.name}.{field}")

    original_player = game_state.player
    original_current_combat = game_state.current_combat
    original_config = game_state.config
    try:
        player = DummyCreature("Player")
        player.powers = [DummyPower()]
        enemy = DummyCreature("Enemy")
        enemy.powers = [DummyPower()]
        cast(Any, game_state).player = player
        game_state.current_combat = Combat(enemies=[enemy])
        cast(Any, game_state).config = types.SimpleNamespace(mode="debug", debug={"print": False})
        drain_runtime_events()

        game_state.current_combat._print_combat_state()
        queued = get_runtime_events()

        assert queued
        assert queued[0].kind == "text"
        assert rendered == []

        flush_runtime_events()
        assert len(rendered) == len(queued)
        assert rendered[0].kind == queued[0].kind
    finally:
        drain_runtime_events()
        game_state.player = original_player
        game_state.current_combat = original_current_combat
        game_state.config = original_config


def test_combat_snapshot_includes_player_stance_and_orbs(monkeypatch):
    from engine import runtime_presenter
    from engine.combat import Combat
    from engine.game_state import game_state
    from engine.runtime_events import drain_runtime_events
    from engine.runtime_presenter import flush_runtime_events
    from localization import current_language, set_language, t
    from orbs.dark import DarkOrb
    from orbs.frost import FrostOrb
    from orbs.lightning import LightningOrb
    from player.orb_manager import OrbManager
    from player.status_manager import StatusManager
    from utils.types import StatusType

    rendered: list[str] = []
    monkeypatch.setattr(
        runtime_presenter,
        "render_runtime_event",
        lambda event: rendered.append(event.text),
    )

    class DummyCardManager:
        def get_pile(self, name):
            return []

    class DummyCreature:
        def __init__(self, name="Dummy"):
            self.name = name
            self.hp = 10
            self.max_hp = 10
            self.block = 0
            self.energy = 3
            self.max_energy = 3
            self.draw_count = 5
            self.card_manager = DummyCardManager()
            self.relics = []
            self.powers = []
            self.current_intention = None
            self.status_manager: Any = None
            self.orb_manager: Any = None

        def is_dead(self):
            return False

        def local(self, field, **kwargs):
            return types.SimpleNamespace(resolve=lambda: f"{self.name}.{field}")

    original_player = game_state.player
    original_current_combat = game_state.current_combat
    original_config = game_state.config
    original_language = current_language
    try:
        set_language("zh")
        player = DummyCreature("Player")
        player.status_manager = StatusManager(StatusType.WRATH)
        player.orb_manager = OrbManager(max_orb_slots=3)
        player.orb_manager.add_orb(LightningOrb())
        player.orb_manager.add_orb(FrostOrb())
        player.orb_manager.add_orb(DarkOrb())
        enemy = DummyCreature("Enemy")

        cast(Any, game_state).player = player
        game_state.current_combat = Combat(enemies=[enemy])
        cast(Any, game_state).config = types.SimpleNamespace(
            mode="debug",
            debug={"print": False},
        )
        drain_runtime_events()

        game_state.current_combat._print_combat_state()
        flush_runtime_events()

        output = "".join(rendered)
        assert t("ui.stance", default="姿态") in output
        assert t("ui.status.wrath", default="愤怒") in output
        assert t("ui.orbs", default="充能球") in output
        assert t("orbs.LightningOrb.name", default="闪电球") in output
        assert f"{t('ui.passive', default='被动')}: 3" in output
        assert f"{t('ui.evoke', default='主动')}: 8" in output
        assert t("orbs.FrostOrb.name", default="冰霜球") in output
        assert f"{t('ui.passive', default='被动')}: 2" in output
        assert f"{t('ui.evoke', default='主动')}: 5" in output
        assert t("orbs.DarkOrb.name", default="黑暗球") in output
        assert f"{t('ui.passive', default='被动')}: 6" in output
        assert f"{t('ui.evoke', default='主动')}: 6" in output
        assert "orbs.LightningOrb.name" not in output
    finally:
        drain_runtime_events()
        game_state.player = original_player
        game_state.current_combat = original_current_combat
        game_state.config = original_config
        set_language(original_language)
