from actions.base import LambdaAction
from cards.defect.dualcast import Dualcast
from cards.defect.zap import Zap
from engine.runtime_api import add_action
from orbs.base import Orb
from orbs.lightning import LightningOrb
from relics.character.defect import CrackedCore
from tests.test_combat_utils import create_test_helper


class _TrackingOrb(Orb):
    def __init__(self):
        super().__init__()
        self.evoke_count = 0

    def on_evoke(self):
        add_action(LambdaAction(func=self._mark_evoke))

    def _mark_evoke(self):
        self.evoke_count += 1


class TestDefectStarters:
    def setup_method(self):
        self.helper = create_test_helper()
        self.player = self.helper.create_player(hp=75, max_hp=75, energy=3)
        self.player.namespace = "defect"

    def test_zap_basic_properties(self):
        card = Zap()
        assert card.cost == 1

    def test_zap_channels_lightning(self):
        self.helper.start_combat([])
        card = Zap()
        self.helper.add_card_to_hand(card)

        result = self.helper.play_card(card)
        assert result is True
        assert len(self.player.orb_manager.orbs) == 1
        assert isinstance(self.player.orb_manager.orbs[0], LightningOrb)

    def test_dualcast_evokes_next_orb_twice(self):
        self.helper.start_combat([])
        orb = _TrackingOrb()
        self.player.orb_manager.add_orb(orb)
        card = Dualcast()
        self.helper.add_card_to_hand(card)

        result = self.helper.play_card(card)
        assert result is True
        assert len(self.player.orb_manager.orbs) == 0
        assert orb.evoke_count == 2

    def test_cracked_core_channels_lightning_on_combat_start(self):
        self.helper.start_combat([])
        relic = CrackedCore()
        self.player.relics = [relic]

        assert len(self.player.orb_manager.orbs) == 0

        relic.on_combat_start(self.player)
        self.helper.game_state.drive_actions()

        assert len(self.player.orb_manager.orbs) == 1
        assert isinstance(self.player.orb_manager.orbs[0], LightningOrb)
