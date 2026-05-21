from typing import Optional
from cards.base import COST_UNPLAYABLE, Card
from utils.types import CardType


class Wound(Card):
    """Wound card - unplayable"""
    base_cost = COST_UNPLAYABLE
    card_type = CardType.STATUS
    upgradeable = False
