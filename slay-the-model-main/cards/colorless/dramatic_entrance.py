"""
Colorless Uncommon Attack card - Dramatic Entrance
"""

from typing import List
from actions.base import Action
from actions.combat import AttackAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class DramaticEntrance(Card):
    """Deal damage to ALL enemies, Innate, Exhaust"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_ALL

    base_cost = 0
    base_damage = 8
    base_innate = True
    base_exhaust = True

    upgrade_damage = 12
