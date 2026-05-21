"""
Colorless Rare Skill card - Thinking Ahead
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import ChooseMoveCardAction, DrawCardsAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, PilePosType, RarityType


@register("card")
class ThinkingAhead(Card):
    """Draw 2 cards, place a card from your hand on top of your draw pile.
    
    Unupgraded: Exhaust.
    Upgraded: Does not exhaust.
    """

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 0
    base_draw = 2
    base_exhaust = True
    upgrade_exhaust = False

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        from engine.game_state import game_state
        add_actions([
            DrawCardsAction(count=self.base_draw),
            ChooseMoveCardAction(src="hand", dst="draw_pile", amount=1, position=PilePosType.TOP)
        ])
        return
