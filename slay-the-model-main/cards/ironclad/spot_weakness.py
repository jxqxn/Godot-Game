"""
Ironclad Uncommon Skill card - Spot Weakness
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from enemies.base import Enemy
from entities.creature import Creature
from utils.dynamic_values import get_magic_value
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class SpotWeakness(Card):
    """If target's intention is attack, gain 3/4 Strength"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 1
    base_magic = {"strength": 3}

    upgrade_magic = {"strength": 4}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state
        player = game_state.player

        super().on_play(targets)

        actions = []
        assert target is not None
        assert isinstance(target, Enemy)
        enemy_target: Enemy = target
        current_intention = enemy_target.current_intention
        if current_intention is not None and current_intention.base_damage > 0:
            actions.append(ApplyPowerAction("strength", player, amount=get_magic_value(self, "strength")))

        from engine.game_state import game_state

        add_actions(actions)

        return
