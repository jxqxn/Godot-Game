"""
Ironclad Uncommon Power card - Combust
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
class Combust(Card):
    """At end of turn, deal 5/7 damage to all enemy"""

    card_type = CardType.POWER
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_magic = {"combust_damage": 5, "damage": 5}
    upgrade_magic = {"combust_damage": 7, "damage": 7}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Apply CombustPower
        combust_damage = self.get_magic_value("combust_damage")
        actions.append(ApplyPowerAction(power="CombustPower", target=target, amount=combust_damage, duration=-1))

        from engine.game_state import game_state

        add_actions(actions)

        return