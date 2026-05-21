"""
Ironclad Common Skill card - War Cry
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import DrawCardsAction, ChooseMoveCardAction 
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class WarCry(Card):
    """Draw cards and put a card on top of draw pile"""

    card_type = CardType.SKILL
    rarity = RarityType.COMMON

    base_cost = 0
    base_draw = 1

    upgrade_draw = 2

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Draw cards
        actions.append(DrawCardsAction(count=self.draw))

        actions.append(ChooseMoveCardAction(src="hand", dst="draw_pile", amount=1))

        from engine.game_state import game_state

        add_actions(actions)

        return