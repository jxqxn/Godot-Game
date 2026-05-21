"""
Ironclad Common Attack card - Iron Wave
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class IronWave(Card):
    """Gain block and deal damage"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 1
    base_block = 5
    base_damage = 5

    upgrade_block = 7
    upgrade_damage = 7
