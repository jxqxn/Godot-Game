"""
Ironclad Rare Skill card - Offering
"""

from typing import List
from actions.base import Action
from actions.combat import LoseHPAction, GainEnergyAction
from actions.card import DrawCardsAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Offering(Card):
    """Lose HP, gain Energy, draw cards, exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 0
    base_heal = -6
    base_energy_gain = 2
    base_draw = 3
    base_exhaust = True

    upgrade_draw = 5