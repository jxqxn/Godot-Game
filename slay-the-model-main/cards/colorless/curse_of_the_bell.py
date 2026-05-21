"""
Colorless Special Curse card - Curse of the Bell
"""

from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class CurseOfTheBell(Card):
    """Unplayable, Irremovable"""

    card_type = CardType.CURSE
    rarity = RarityType.SPECIAL

    base_cost = COST_UNPLAYABLE
    irremovable = False
    upgradeable = False
