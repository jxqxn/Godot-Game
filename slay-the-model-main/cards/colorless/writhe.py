"""
Colorless Curse card - Writhe
"""

from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Writhe(Card):
    """Unplayable, Innate"""

    card_type = CardType.CURSE
    rarity = RarityType.CURSE

    base_cost = COST_UNPLAYABLE
    base_innate = True
    upgradeable = False
