from actions.watcher import GainMantraAction
from cards.colorless.beta import Beta
from cards.colorless.omega import Omega
from cards.ironclad.strike import Strike
from cards.watcher.alpha import Alpha
from cards.watcher.blasphemy import Blasphemy
from cards.watcher.brilliance import Brilliance
from cards.watcher.deva_form import DevaForm
from cards.watcher.lesson_learned import LessonLearned
from cards.watcher.master_reality import MasterReality
from cards.watcher.prostrate import Prostrate
from cards.watcher.rushdown import Rushdown
from cards.watcher.spirit_shield import SpiritShield
from cards.watcher.talk_to_the_hand import TalkToTheHand
from cards.watcher.worship import Worship
from enemies.act1.cultist import Cultist
from tests.test_combat_utils import create_test_helper
from utils.dynamic_values import resolve_potential_damage
from utils.types import StatusType


def test_wrath_does_not_scale_non_attack_damage():
    helper = create_test_helper()
    player = helper.create_player()
    enemy = helper.create_enemy(Cultist, hp=40)
    helper.start_combat([enemy])
    player.status_manager.status = StatusType.WRATH

    assert resolve_potential_damage(5, player, enemy, card=None) == 5


def test_divinity_does_not_scale_non_attack_damage():
    helper = create_test_helper()
    player = helper.create_player()
    enemy = helper.create_enemy(Cultist, hp=40)
    helper.start_combat([enemy])
    player.status_manager.status = StatusType.DIVINITY

    assert resolve_potential_damage(5, player, enemy, card=None) == 5


def test_prostrate_upgrade_adds_mantra_not_block_and_card_no_longer_exhausts():
    card = Prostrate()
    card.upgrade()

    assert card.exhaust is False
    assert card.get_magic_value("mantra") == 3
    assert card.block == 4


def test_deva_form_is_ethereal_until_upgraded():
    card = DevaForm()
    assert card.ethereal is True

    card.upgrade()
    assert card.ethereal is False


def test_lesson_learned_exhausts():
    assert LessonLearned().exhaust is True


def test_brilliance_scales_with_total_mantra_gained_this_combat():
    helper = create_test_helper()
    helper.create_player()
    helper.start_combat([helper.create_enemy(Cultist, hp=40)])

    GainMantraAction(3).execute()
    GainMantraAction(4).execute()
    helper.game_state.drive_actions()

    assert Brilliance().damage == 19


def test_talk_to_the_hand_exhausts_and_upgrade_increases_block_return():
    card = TalkToTheHand()
    assert card.exhaust is True
    assert card.get_magic_value("block") == 2

    card.upgrade()
    assert card.get_magic_value("block") == 3


def test_spirit_shield_excludes_itself_from_hand_count():
    helper = create_test_helper()
    helper.create_player()
    helper.start_combat([helper.create_enemy(Cultist, hp=20)])

    card = SpiritShield()
    helper.add_card_to_hand(card)
    helper.add_card_to_hand(Strike())
    helper.add_card_to_hand(Strike())

    assert card.block == 6


def test_gain_mantra_tracks_total_gained_and_enters_divinity():
    helper = create_test_helper()
    player = helper.create_player()
    helper.start_combat([helper.create_enemy(Cultist, hp=30)])

    GainMantraAction(12).execute()
    helper.game_state.drive_actions()

    mantra = player.get_power("Mantra")
    combat = helper.game_state.current_combat
    assert combat is not None
    assert mantra is not None
    assert mantra.amount == 2
    assert player.status_manager.status == StatusType.DIVINITY
    assert combat.combat_state.mantra_gained == 12


def test_rushdown_upgrade_reduces_cost_to_zero():
    card = Rushdown()
    card.upgrade()
    assert card.cost == 0


def test_worship_upgrade_grants_retain_not_innate():
    card = Worship()
    card.upgrade()
    assert card.retain is True
    assert card.innate is False


def test_blasphemy_upgrade_grants_retain():
    card = Blasphemy()
    card.upgrade()
    assert card.retain is True


def test_alpha_upgrade_grants_innate():
    card = Alpha()
    card.upgrade()
    assert card.innate is True


def test_master_reality_upgrades_beta_and_omega_created_by_alpha_chain():
    helper = create_test_helper()
    player = helper.create_player(energy=10)
    enemy = helper.create_enemy(Cultist, hp=60)
    helper.start_combat([enemy])

    master_reality = MasterReality()
    alpha = Alpha()
    helper.add_card_to_hand(master_reality)
    helper.add_card_to_hand(alpha)

    assert helper.play_card(master_reality) is True
    assert helper.play_card(alpha) is True

    beta = next(card for card in player.card_manager.get_pile("draw_pile") if isinstance(card, Beta))
    assert beta.upgrade_level == 1

    player.card_manager.remove_from_pile(beta, "draw_pile")
    helper.add_card_to_hand(beta)
    assert helper.play_card(beta) is True

    omega = next(card for card in player.card_manager.get_pile("draw_pile") if isinstance(card, Omega))
    assert omega.upgrade_level == 1
