"""
Ironclad Uncommon Attack card - Reckless Charge
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
class RecklessCharge(Card):
    """Deal damage, shuffle Dazed into draw pile"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_damage = 7

    upgrade_damage = 10

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        # Shuffle Dazed into draw pile
        from cards.colorless import Dazed
        actions.append(AddCardAction(card=Dazed(), dest_pile="draw_pile"))

        from engine.game_state import game_state

        add_actions(actions)

        return