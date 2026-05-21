"""
Ironclad Common Attack card - Sword Boomerang
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class SwordBoomerang(Card):
    """Deal damage multiple times to random enemies"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON
    target_type = TargetType.ENEMY_RANDOM

    base_cost = 1
    base_damage = 3
    base_attack_times = 3

    upgrade_damage = 4
    upgrade_attack_times = 4
