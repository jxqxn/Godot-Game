"""
Ironclad Uncommon Skill card - Intimidate
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
class Intimidate(Card):
    """Apply Weak to ALL enemies"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_ALL

    base_cost = 0
    base_magic = {"weak": 1}

    upgrade_magic = {"weak": 2}

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        actions = []
        # Apply weak debuff to all enemies
        weak_amount = self.get_magic_value("weak")
        for enemy in targets:
            if enemy.hp > 0:
                actions.append(ApplyPowerAction(target=enemy, power="weak", amount=weak_amount))

        from engine.game_state import game_state

        add_actions(actions)

        return