"""
Ironclad Rare Attack card - Bludgeon
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Bludgeon(Card):
    """Deal massive damage"""

    card_type = CardType.ATTACK
    rarity = RarityType.RARE

    base_cost = 3
    base_damage = 32

    upgrade_damage = 42
