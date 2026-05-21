"""
Ironclad Uncommon Skill card - Disarm
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Disarm(Card):
    """Apply Strength to enemy"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 1
    base_magic = {"strength_debuff": 2, "strength": 2}

    upgrade_magic = {"strength_debuff": 3, "strength": 3}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        # Apply Strength debuff to target
        if targets:
            strength_amount = self.get_magic_value("strength_debuff")
            actions.append(ApplyPowerAction(target=target, power="strength", amount=-strength_amount))

        from engine.game_state import game_state

        add_actions(actions)

        return