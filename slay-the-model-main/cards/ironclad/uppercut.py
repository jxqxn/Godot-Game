"""
Ironclad Uncommon Attack card - Uppercut
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Uppercut(Card):
    """Deal damage and apply Vulnerable and Weak"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 2
    base_damage = 13
    base_magic = {"vulnerable": 1, "weak": 1}

    upgrade_magic = {"vulnerable": 2, "weak": 2}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        if targets:
            vulnerable_amount = self.get_magic_value("vulnerable")
            weak_amount = self.get_magic_value("weak")

            actions.append(ApplyPowerAction(target=target, power="vulnerable", amount=vulnerable_amount))
            actions.append(ApplyPowerAction(target=target, power="weak", amount=weak_amount))

        from engine.game_state import game_state

        add_actions(actions)

        return