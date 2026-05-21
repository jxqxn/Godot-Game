"""
Colorless Curse card - Clumsy
"""

from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Clumsy(Card):
    """Unplayable, Ethereal"""

    card_type = CardType.CURSE
    rarity = RarityType.CURSE

    base_cost = COST_UNPLAYABLE
    base_ethereal = True
    upgradeable = False
