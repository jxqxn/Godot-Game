from actions.combat import ApplyPowerAction, GainBlockAction, HealAction, LoseHPAction, UsePotionBHAction
from actions.reward import AddGoldAction
from enemies.act1.cultist import Cultist
from engine.messages import HealedMessage
from potions.global_potions import BlockPotion
from powers.definitions.juggernaut import JuggernautPower
from powers.definitions.rupture import RupturePower
from relics.character.ironclad import ChampionBelt, RedSkull
from relics.global_relics.common import ToyOrnithopter
from relics.global_relics.event import BloodyIdol
from tests.test_combat_utils import create_test_helper
from typing import cast


def test_status_actions_import_from_split_modules():
    from actions.combat import ApplyPowerAction as CombatApplyPowerAction
    from actions.combat import UsePotionBHAction as CombatUsePotionBHAction
    from actions.combat_status import ApplyPowerAction as SplitApplyPowerAction
    from actions.combat_status import UsePotionBHAction as SplitUsePotionBHAction

    assert CombatApplyPowerAction is SplitApplyPowerAction
    assert CombatUsePotionBHAction is SplitUsePotionBHAction


def _capture_published_message_types(game_state, monkeypatch):
    original_publish = game_state.publish_message
    published = []

    def wrapped(message, *args, **kwargs):
        published.append(type(message).__name__)
        return original_publish(message, *args, **kwargs)

    monkeypatch.setattr(game_state, "publish_message", wrapped)
    return published


def test_apply_power_action_publishes_power_applied_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    player.relics = [ChampionBelt()]
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    ApplyPowerAction(power="Vulnerable", target=enemy, amount=1).execute()
    helper.game_state.drive_actions()

    assert "PowerAppliedMessage" in published
    assert enemy.has_power("Vulnerable")
    assert enemy.has_power("Weak")


def test_use_potion_action_publishes_potion_used_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=40, max_hp=80, energy=3)
    player.relics = [ToyOrnithopter()]
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    potion = BlockPotion()
    player.potions.append(potion)
    initial_hp = player.hp

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    UsePotionBHAction(potion=potion, targets=[player]).execute()
    helper.game_state.drive_actions()

    assert "PotionUsedMessage" in published
    assert player.hp == initial_hp + 5
    assert potion not in player.potions


def test_add_gold_action_publishes_gold_gained_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=40, max_hp=80, energy=3)
    player.relics = [BloodyIdol()]
    initial_hp = player.hp

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    AddGoldAction(amount=12).execute()
    helper.game_state.drive_actions()

    assert "GoldGainedMessage" in published
    assert player.gold == 111
    assert player.hp == initial_hp + 5


def test_heal_action_publishes_healed_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=35, max_hp=80, energy=3)
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    initial_hp = player.hp

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    HealAction(amount=10, target=player).execute()

    assert "HealedMessage" in published
    assert player.hp == initial_hp + 10


def test_healed_message_runs_red_skull_response():
    helper = create_test_helper()
    player = helper.create_player(hp=35, max_hp=80, energy=3)
    red_skull = RedSkull()
    player.relics = [red_skull]
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    helper.game_state.drive_actions()

    helper.game_state.publish_message(
        HealedMessage(target=player, amount=10, previous_hp=35, new_hp=45),
    )
    action = helper.game_state.action_queue.peek_next()
    assert isinstance(action, ApplyPowerAction)
    action = cast(ApplyPowerAction, action)
    assert action.target is player
    assert getattr(action.power, "amount", None) == -3


def test_heal_action_does_not_use_direct_red_skull_fallback(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=35, max_hp=80, energy=3)
    red_skull = RedSkull()
    player.relics = [red_skull]
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    helper.game_state.drive_actions()

    monkeypatch.setattr(helper.game_state, "publish_message", lambda message, *args, **kwargs: [])

    HealAction(amount=10, target=player).execute()

    assert player.strength == 3


def test_lose_hp_action_publishes_hp_lost_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    player.add_power(RupturePower(amount=1, owner=player))
    card = enemy  # just a non-None sentinel won't work with Rupture semantics
    from cards.ironclad.bloodletting import Bloodletting
    bloodletting = Bloodletting()

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    LoseHPAction(amount=3, target=player, card=bloodletting, source=bloodletting).execute()
    helper.game_state.drive_actions()

    assert "HpLostMessage" in published
    assert player.hp == 77
    assert player.strength == 1


def test_gain_block_action_publishes_block_gained_message(monkeypatch):
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80, energy=3)
    enemy = helper.create_enemy(Cultist, hp=30)
    helper.start_combat([enemy])
    player.add_power(JuggernautPower(amount=5, owner=player))

    published = _capture_published_message_types(helper.game_state, monkeypatch)

    GainBlockAction(block=7, target=player).execute()
    helper.game_state.drive_actions()

    assert "BlockGainedMessage" in published
    assert player.block == 7
    assert enemy.hp == 25

