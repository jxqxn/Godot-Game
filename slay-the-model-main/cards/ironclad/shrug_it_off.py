"""
Ironclad Common Skill card - Shrug It Off
"""

from typing import List
from actions.base import Action
from actions.combat import GainBlockAction
from actions.card import DrawCardsAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class ShrugItOff(Card):
    """Gain block and draw cards"""

    card_type = CardType.SKILL
    rarity = RarityType.COMMON

    base_cost = 1
    base_block = 8
    base_draw = 1

    upgrade_block = 11