"""
Ironclad Rare Attack card - Immolate
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import AddCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Immolate(Card):
    """Deal damage to ALL enemies, add Burn"""

    card_type = CardType.ATTACK
    rarity = RarityType.RARE
    target_type = TargetType.ENEMY_ALL

    base_cost = 2
    base_damage = 21

    upgrade_damage = 28

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        # Add Burn status to discard pile
        from cards.colorless import Burn
        actions.append(AddCardAction(card=Burn(), dest_pile="discard_pile"))

        from engine.game_state import game_state

        add_actions(actions)

        return