"""
Ironclad Uncommon Skill card - Seeing Red
"""

from typing import List
from actions.base import Action
from actions.combat import GainEnergyAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class SeeingRed(Card):
    """Gain Energy, Exhaust this card"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_energy_gain = 2
    base_exhaust = True

    upgrade_cost = 0