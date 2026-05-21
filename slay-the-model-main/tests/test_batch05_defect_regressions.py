from actions.base import LambdaAction
from actions.orb import AddOrbAction
from cards.defect.creative_ai import CreativeAI
from cards.defect.glacier import Glacier
from cards.defect.hologram import Hologram
from cards.defect.rebound import Rebound
from cards.defect.strike import Strike
from cards.defect.zap import Zap
from cards.base import Card
from enemies.act1.cultist import Cultist
from orbs.base import Orb
from orbs.plasma import PlasmaOrb
from powers.definitions.biased_cognition import BiasedCognitionPower
from powers.definitions.creative_ai import CreativeAIPower
from powers.definitions.focus import FocusPower
from tests.test_combat_utils import create_test_helper
from utils.registry import register
from utils.types import CardType, PilePosType, RarityType


class _TrackingOrb(Orb):
    def __init__(self, name: str):
        super().__init__()
        self.name = name
        self.evoked = 0

    def on_passive(self) -> None:
        return

    def on_evoke(self) -> None:
        from engine.runtime_api import add_action

        add_action(LambdaAction(func=self._mark))

    def _mark(self) -> None:
        self.evoked += 1


@register("card")
class _TestPowerCard(Card):
    card_type = CardType.POWER
    rarity = RarityType.SPECIAL
    base_cost = 1


def test_add_orb_action_evokes_leftmost_when_slots_are_full():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    helper.start_combat([])
    player.orb_manager.max_orb_slots = 2
    left = _TrackingOrb("left")
    right = _TrackingOrb("right")
    player.orb_manager.add_orb(left)
    player.orb_manager.add_orb(right)

    AddOrbAction(PlasmaOrb()).execute()
    helper.game_state.drive_actions()

    assert left.evoked == 1
    assert right.evoked == 0
    assert len(player.orb_manager.orbs) == 2
    assert player.orb_manager.orbs[0] is right
    assert isinstance(player.orb_manager.orbs[1], PlasmaOrb)


def test_plasma_is_not_modified_by_focus():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    helper.start_combat([])
    player.add_power(FocusPower(amount=3, owner=player))

    orb = PlasmaOrb()

    assert orb.passive_energy_gain == 1
    assert orb.evoke_energy_gain == 2


def test_rebound_puts_the_next_non_power_card_on_top_of_draw_pile():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    enemy = helper.create_enemy(Cultist, hp=40)
    helper.start_combat([enemy])

    rebound = Rebound()
    strike = Strike()
    player.card_manager.get_pile("draw_pile").clear()
    helper.add_card_to_hand(rebound)
    helper.add_card_to_hand(strike)

    assert helper.play_card(rebound, target=enemy)
    assert helper.play_card(strike, target=enemy)

    draw_pile = player.card_manager.get_pile("draw_pile")
    assert draw_pile
    assert draw_pile[-1] is strike


def test_rebound_does_not_rebound_power_cards():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    helper.start_combat([])

    rebound = Rebound()
    power_card = _TestPowerCard()
    helper.add_card_to_hand(rebound)
    helper.add_card_to_hand(power_card)

    assert helper.play_card(rebound)
    assert helper.play_card(power_card)

    assert power_card not in player.card_manager.get_pile("draw_pile")


def test_creative_ai_stacks_by_amount():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    helper.start_combat([])

    player.add_power(CreativeAIPower(amount=1, owner=player))
    player.add_power(CreativeAIPower(amount=1, owner=player))
    power = player.get_power("Creative AI")

    assert power is not None
    assert power.amount == 2


def test_biased_cognition_negative_focus_loss_stacks():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=3)
    helper.start_combat([])
    player.add_power(FocusPower(amount=6, owner=player))
    player.add_power(BiasedCognitionPower(amount=1, owner=player))
    player.add_power(BiasedCognitionPower(amount=1, owner=player))
    biased = player.get_power("Biased Cognition")

    assert biased is not None
    assert biased.amount == 2
    biased.on_turn_start()
    helper.game_state.drive_actions()

    focus = player.get_power("Focus")
    assert focus is not None
    assert focus.amount == 4


def test_glacier_cost_matches_original():
    assert Glacier().cost == 2


def test_hologram_is_common():
    assert Hologram().rarity == RarityType.COMMON


def test_start_turn_orbs_trigger_before_normal_draw():
    helper = create_test_helper()
    player = helper.create_player(hp=75, max_hp=75, energy=0, max_energy=5)
    combat = helper.start_combat([])
    player.card_manager.get_pile("hand").clear()
    player.card_manager.get_pile("draw_pile").clear()
    player.card_manager.add_to_pile(Zap(), "draw_pile", PilePosType.TOP)
    player.orb_manager.add_orb(PlasmaOrb())

    combat._start_player_turn()
    helper.game_state.drive_actions()

    assert player.energy == 6
    assert len(player.card_manager.get_pile("hand")) == 1
