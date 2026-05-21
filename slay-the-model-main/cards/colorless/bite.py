"""
Colorless Special Attack card - Bite
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Bite(Card):
    """Deal damage and heal"""

    card_type = CardType.ATTACK
    rarity = RarityType.SPECIAL
    target_type = TargetType.ENEMY_SELECT

    base_cost = 1
    base_damage = 7
    base_heal = 2

    upgrade_damage = 8
    upgrade_heal = 3
