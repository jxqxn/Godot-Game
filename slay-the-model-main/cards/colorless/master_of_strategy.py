"""
Colorless Rare Skill card - Master of Strategy
"""

from typing import List
from actions.base import Action
from actions.card import DrawCardsAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class MasterOfStrategy(Card):
    """Draw cards, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 0
    base_draw = 3
    base_exhaust = True

    upgrade_draw = 4
