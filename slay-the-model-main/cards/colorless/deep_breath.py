"""
Colorless Uncommon Skill card - Deep Breath
"""
from engine.runtime_api import add_actions
from typing import List
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class DeepBreath(Card):
    """Shuffle discard into draw pile, draw cards"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0
    base_draw = 1

    upgrade_draw = 2

    def on_play(self, targets: List[Creature] = []):
        from actions.card import ShuffleAction

        super().on_play(targets)
        add_actions([ShuffleAction()], to_front=True)
