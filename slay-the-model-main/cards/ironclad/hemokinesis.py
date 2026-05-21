"""
Ironclad Uncommon Attack card - Hemokinesis
"""

from typing import List
from actions.base import Action
from actions.combat import LoseHPAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Hemokinesis(Card):
    """Lose HP, deal damage"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_damage = 15
    base_heal = -2

    upgrade_damage = 20
