"""
Ironclad Uncommon Attack card - Dropkick
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import GainEnergyAction
from actions.card import DrawCardsAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Dropkick(Card):
    """Deal damage, if enemy has Vulnerable gain Energy and draw"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_damage = 5

    upgrade_damage = 8

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        if target and target.has_power("vulnerable"):
            actions.append(GainEnergyAction(energy=1))
            actions.append(DrawCardsAction(count=1))

        from engine.game_state import game_state

        add_actions(actions)

        return