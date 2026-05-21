"""
Ironclad Common Attack card - Anger
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import AddCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Anger(Card):
    """Deal damage and add a copy to discard pile"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 0
    base_damage = 6

    upgrade_damage = 8

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        from engine.game_state import game_state
        add_actions([AddCardAction(card=self.copy(), dest_pile="discard_pile")])
        return