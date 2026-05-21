"""
Ironclad Uncommon Skill card - Dual Wield
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import AddCardAction, ChooseCopyCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class DualWield(Card):
    """Choose a card in hand and add a copy"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 1

    upgrade_cost = 0

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state
        from utils.types import CardType

        super().on_play(targets)

        actions = []
        # Choose a card in hand and add a copy
        # Dual Wield can only copy Attack or Power cards, not Skill cards
        if game_state.player.card_manager.get_pile("hand"):
            actions.append(ChooseCopyCardAction(
                pile="hand", 
                copies=1, 
                card_types=[CardType.ATTACK, CardType.POWER]
            ))

        from engine.game_state import game_state

        add_actions(actions)

        return