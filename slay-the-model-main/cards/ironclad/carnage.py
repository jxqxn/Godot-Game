"""
Ironclad Uncommon Attack card - Carnage
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Carnage(Card):
    """Deal massive damage to enemy"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 2
    base_damage = 20
    base_ethereal = True

    upgrade_damage = 28
