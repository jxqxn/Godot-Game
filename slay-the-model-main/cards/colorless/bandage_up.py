"""
Colorless Uncommon Skill card - Bandage Up
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class BandageUp(Card):
    """Heal HP and exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_heal = 4
    base_exhaust = True

    upgrade_heal = 6
