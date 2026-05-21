"""
Ironclad Common Attack card - Heavy Blade
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class HeavyBlade(Card):
    """Deal damage, Strength affects this multiple times"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 2
    base_damage = 14
    base_magic = {"strength_mult": 3}

    upgrade_damage = 17
    upgrade_magic = {"strength_mult": 5}
