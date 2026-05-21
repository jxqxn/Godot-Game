from actions.combat import DealDamageAction
from enemies.act1.gremlin_nob import GremlinNob
from enemies.act1.louse import RedLouse
from enemies.act1.lagavulin import Lagavulin
from enemies.act1.the_hexaghost import TheHexaghost
from enemies.act1.slime_boss import SlimeBoss
from enemies.act2.book_of_stabbing import BookOfStabbing
from enemies.act2.the_collector import TheCollector, TorchHead
from enemies.act3.awakened_one import AwakenedOne
from enemies.act3.deca import Deca
from enemies.act3.donu import Donu
from enemies.act3.time_eater import TimeEater
from enemies.act3.writhing_mass import WrithingMass
from enemies.act4.corrupt_heart import CorruptHeart
from powers.definitions.strength import StrengthPower
from powers.definitions.weak import WeakPower
from tests.test_combat_utils import create_test_helper
from utils.types import DamageType


def test_hexaghost_inferno_uses_six_small_hits():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 0

    boss = TheHexaghost()

    assert boss.max_hp == 250
    assert boss.intentions["inferno"].base_damage == 2
    assert boss.intentions["inferno"]._hits == 6


def test_hexaghost_ascension_four_inferno_damage_and_ascension_nine_hp():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 9

    boss = TheHexaghost()

    assert boss.max_hp == 264
    assert boss.intentions["inferno"].base_damage == 3
    assert boss.intentions["tackle"].base_damage == 6


def test_time_eater_haste_heals_to_half_and_only_clears_debuffs():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    boss = TimeEater()
    helper.start_combat([boss])
    boss.add_power(WeakPower(duration=1, owner=boss))
    boss.add_power(StrengthPower(amount=3, owner=boss))
    boss.hp = 100

    boss.intentions["Haste"].execute()
    helper.game_state.drive_actions()

    assert boss.hp == boss.max_hp // 2
    assert boss.get_power("Time Warp") is not None
    assert boss.get_power("Strength") is not None
    assert boss.get_power("Weak") is None
    assert boss.block == boss.intentions["Head Slam"].base_damage


def test_gremlin_nob_starts_without_enrage_and_bellow_applies_it():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 0

    nob = GremlinNob()
    helper.start_combat([nob])

    assert nob.get_power("Enrage") is None

    nob.intentions["bellow"].execute()
    helper.game_state.drive_actions()

    enrage = nob.get_power("Enrage")
    assert enrage is not None
    assert enrage.amount == 2


def test_gremlin_nob_ascension_values_match_source_thresholds():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 18

    nob = GremlinNob()

    assert 85 <= nob.max_hp <= 90
    assert nob.intentions["skull_bash"].base_damage == 8
    assert nob.intentions["bull_rush"].base_damage == 16

    helper.start_combat([nob])
    nob.intentions["bellow"].execute()
    helper.game_state.drive_actions()

    assert nob.get_power("Enrage").amount == 3


def test_curl_up_does_not_trigger_on_lethal_hit():
    helper = create_test_helper()
    player = helper.create_player()
    enemy = RedLouse()
    enemy.max_hp = 4
    enemy.hp = 4
    helper.start_combat([enemy])

    DealDamageAction(
        damage=4,
        target=enemy,
        source=player,
        damage_type=DamageType.PHYSICAL,
    ).execute()
    helper.game_state.drive_actions()

    assert enemy.is_dead()
    assert enemy.block == 0


def test_malleable_does_not_trigger_on_lethal_hit():
    helper = create_test_helper()
    player = helper.create_player()
    enemy = WrithingMass()
    enemy.max_hp = 4
    enemy.hp = 4
    helper.start_combat([enemy])

    DealDamageAction(
        damage=4,
        target=enemy,
        source=player,
        damage_type=DamageType.PHYSICAL,
    ).execute()
    helper.game_state.drive_actions()

    assert enemy.is_dead()
    assert enemy.block == 0
    malleable = enemy.get_power("Malleable")
    assert malleable is not None
    assert malleable.current_block == malleable.amount


def test_book_of_stabbing_starts_with_painful_stabs_and_first_multi_is_two_hits():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 0

    enemy = BookOfStabbing()
    helper.start_combat([enemy])

    assert enemy.get_power("Painful Stabs") is not None

    enemy.current_intention = enemy.intentions["Multi Stab"]
    enemy.execute_intention()

    attack_actions = [
        action for action in helper.game_state.action_queue.queue
        if action.__class__.__name__ == "AttackAction"
    ]
    assert len(attack_actions) == 2
    assert enemy.multi_stab_count == 1


def test_book_of_stabbing_ascension_thresholds_match_source():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 18

    enemy = BookOfStabbing()

    assert 168 <= enemy.max_hp <= 172
    assert enemy.intentions["Multi Stab"].base_damage == 7
    assert enemy.intentions["Big Stab"].base_damage == 24


def test_awakened_one_rebirth_preserves_buffs_but_clears_curiosity_and_debuffs():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    boss = AwakenedOne()
    helper.start_combat([boss])
    boss.add_power(WeakPower(duration=1, owner=boss))
    boss.add_power(StrengthPower(amount=3, owner=boss))
    boss.hp = 0

    boss.intentions["Rebirth"].execute()

    assert boss.hp == boss.max_hp
    assert boss._phase == 2
    assert boss.get_power("Regeneration") is not None
    assert boss.get_power("Strength") is not None
    assert boss.get_power("Curiosity") is None
    assert boss.get_power("Weak") is None


def test_corrupt_heart_combat_start_uses_source_ascension_values():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    heart = CorruptHeart()
    helper.start_combat([heart])

    assert heart.max_hp == 800
    assert heart.get_power("Beat of Death") is not None
    assert heart.get_power("Beat of Death").amount == 2
    assert heart.get_power("Invincible") is not None
    assert heart.get_power("Invincible").amount == 200
    assert heart.intentions["Blood Shots"].base_damage == 2
    assert heart.intentions["Blood Shots"].hits == 15
    assert heart.intentions["Echo"].base_damage == 45


def test_lagavulin_high_damage_threshold_is_ascension_three():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 3

    enemy = Lagavulin()

    assert enemy.intentions["attack"].base_damage == 20


def test_slime_boss_ascension_values_match_source():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    boss = SlimeBoss()

    assert boss.max_hp == 150
    assert boss.intentions["slam"].base_damage == 38
    assert boss.intentions["goop_spray"]._slimed_count == 5


def test_donu_and_deca_ascension_values_match_source():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    donu = Donu()
    deca = Deca()
    helper.start_combat([donu, deca])

    assert donu.max_hp == 265
    assert donu.intentions["Beam"].base_damage == 12
    assert donu.get_power("Artifact").amount == 3

    assert deca.max_hp == 265
    assert deca.intentions["Beam"].base_damage == 12
    assert deca.get_power("Artifact").amount == 3
    assert deca._add_plated_armor is True


def test_collector_and_torch_head_ascension_values_match_source():
    helper = create_test_helper()
    helper.create_player()
    helper.game_state.ascension = 19

    collector = TheCollector()
    torch_head = TorchHead()

    assert collector.enemy_type.name == "BOSS"
    assert collector.max_hp == 300
    assert collector.intentions["Fireball"].base_damage == 21
    assert collector.intentions["Buff"].base_strength_gain == 5
    assert collector.intentions["Buff"].base_block == 18
    assert collector.intentions["Mega Debuff"].base_amount == 5
    assert 40 <= torch_head.max_hp <= 45
