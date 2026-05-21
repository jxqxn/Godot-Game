"""
Colorless Uncommon Skill card - Purify
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import ChooseExhaustCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Purify(Card):
    """Exhaust up to cards, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_magic = {"cards": 3}
    base_exhaust = True

    upgrade_magic = {"cards": 5}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        actions = []
        # Exhaust up to N cards
        exhaust_amount = self.get_magic_value("cards")
        actions.append(ChooseExhaustCardAction(
            pile="hand",
            amount=exhaust_amount
        ))

        from engine.game_state import game_state

        add_actions(actions)

        return