"""
Ironclad Rare Skill card - Impervious
"""

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction, GainBlockAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Impervious(Card):
    """Gain Massive Block"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 2
    base_block = 30
    base_exhaust = True

    upgrade_block = 40