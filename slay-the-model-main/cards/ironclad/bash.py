"""
Ironclad Basic card - Bash
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import AttackAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.vulnerable import VulnerablePower
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Bash(Card):
    """Deal damage and apply Vulnerable"""

    card_type = CardType.ATTACK
    rarity = RarityType.STARTER

    base_cost = 2
    base_damage = 8
    base_magic = {"vulnerable": 2}

    upgrade_damage = 10
    upgrade_magic = {"vulnerable": 3}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from actions.combat import ApplyPowerAction
        super().on_play(targets)
        actions = []
        # Apply Vulnerable to target
        if targets:
            vulnerable_amount = self.get_magic_value("vulnerable")
            actions.append(ApplyPowerAction(
                VulnerablePower(amount=vulnerable_amount, duration=vulnerable_amount, owner=target),
                target))

        from engine.game_state import game_state

        add_actions(actions)

        return