"""
Colorless Uncommon Attack card - Flash of Steel
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class FlashOfSteel(Card):
    """Deal damage, draw 1 card"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 0
    base_damage = 3
    base_draw = 1

    upgrade_damage = 5
