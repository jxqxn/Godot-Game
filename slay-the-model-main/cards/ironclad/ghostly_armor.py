"""
Ironclad Uncommon Skill card - Ghostly Armor
"""

from typing import List
from actions.base import Action
from actions.combat import GainBlockAction, ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class GhostlyArmor(Card):
    """Gain block"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_block = 10
    base_ethereal = True

    upgrade_block = 13