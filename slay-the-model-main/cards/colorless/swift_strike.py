"""
Colorless Uncommon Attack card - Swift Strike
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class SwiftStrike(Card):
    """Deal damage"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 0
    base_damage = 7

    upgrade_damage = 10
