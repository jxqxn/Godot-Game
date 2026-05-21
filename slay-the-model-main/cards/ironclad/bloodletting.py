"""
Ironclad Uncommon Skill card - Bloodletting
"""

from typing import List
from actions.base import Action
from actions.combat import LoseHPAction, GainEnergyAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Bloodletting(Card):
    """Lose HP, gain Energy"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_heal = -2
    base_energy_gain = 2

    upgrade_energy_gain = 3
