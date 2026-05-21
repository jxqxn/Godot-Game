"""
Colorless Uncommon Skill card - Finesse
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Finesse(Card):
    """Gain block, draw 1 card"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_block = 2
    base_draw = 1

    upgrade_block = 4
