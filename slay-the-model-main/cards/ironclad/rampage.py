"""
Ironclad Uncommon Attack card - Rampage
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Rampage(Card):
    """Deal damage, increase damage this combat"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_damage = 8

    base_magic = {"damage_gain": 5, "damage_increase": 5}
    upgrade_magic = {"damage_gain": 8, "damage_increase": 8}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        # Increase this card's damage for the combat
        damage_increase = self.get_magic_value(
            "damage_increase",
            self.get_magic_value("damage_gain"),
        )
        self._damage += damage_increase

        from engine.game_state import game_state

        add_actions(actions)

        return