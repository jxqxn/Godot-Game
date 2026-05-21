"""
Colorless Uncommon Skill card - Good Instincts
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class GoodInstincts(Card):
    """Gain block"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_block = 6

    upgrade_block = 9
