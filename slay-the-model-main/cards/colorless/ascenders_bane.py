"""
Colorless Special Curse card - AscendersBane
"""

from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class AscendersBane(Card):
    """Unplayable, Ethereal, Irremovable"""

    card_type = CardType.CURSE
    rarity = RarityType.SPECIAL

    base_cost = COST_UNPLAYABLE
    base_ethereal = True
    upgradeable = False
    removable = False
