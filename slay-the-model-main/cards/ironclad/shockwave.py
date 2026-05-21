"""
Ironclad Uncommon Skill card - Shockwave
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.vulnerable import VulnerablePower
from powers.definitions.weak import WeakPower
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Shockwave(Card):
    """Apply Vulnerable and Weak to ALL enemies"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_ALL

    base_cost = 2
    base_exhaust = True
    
    base_magic = {"vulnerable": 3, "weak": 3}
    upgrade_magic = {"vulnerable": 5, "weak": 5}

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        actions = []
        vulnerable_amount = self.get_magic_value("vulnerable")
        weak_amount = self.get_magic_value("weak")

        # Apply Vulnerable and Weak to ALL enemies
        for enemy in targets:
            if enemy.hp > 0:
                actions.append(ApplyPowerAction(
                    VulnerablePower(amount=vulnerable_amount, duration=vulnerable_amount, owner=enemy), enemy))
                actions.append(ApplyPowerAction(
                    WeakPower(amount=weak_amount, duration=weak_amount, owner=enemy), enemy))

        from engine.game_state import game_state

        add_actions(actions)

        return