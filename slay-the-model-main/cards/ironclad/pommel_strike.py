"""
Ironclad Common Attack card - Pommel Strike
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class PommelStrike(Card):
    """Deal damage and draw cards"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 1
    base_damage = 9
    base_draw = 1

    upgrade_damage = 10
    upgrade_draw = 2
