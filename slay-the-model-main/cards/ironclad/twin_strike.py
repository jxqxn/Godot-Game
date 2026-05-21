"""
Ironclad Common Attack card - Twin Strike
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class TwinStrike(Card):
    """Deal damage twice"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 1
    base_damage = 5
    base_attack_times = 2

    upgrade_damage = 7
