"""
Ironclad Common Skill card - Havoc
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import ExhaustCardAction
from actions.combat import PlayCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Havoc(Card):
    """Play top card of draw pile and exhaust it"""

    card_type = CardType.SKILL
    rarity = RarityType.COMMON

    base_cost = 1

    upgrade_cost = 0

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Play top card of draw pile (index 0 is the top)
        draw_pile = game_state.player.card_manager.get_pile('draw_pile')
        if draw_pile:
            card_to_play = draw_pile[0]  # Top of pile is index 0
            actions.append(PlayCardAction(card=card_to_play, is_auto=True, ignore_energy=True))
            actions.append(ExhaustCardAction(card=card_to_play))

        from engine.game_state import game_state

        add_actions(actions)

        return