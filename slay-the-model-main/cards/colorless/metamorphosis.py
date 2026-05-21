"""
Colorless Rare Skill card - Metamorphosis
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import AddRandomCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Metamorphosis(Card):
    """Shuffle random Attacks into draw pile, cost 0 this combat, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 2
    base_magic = {"cards": 3}
    base_exhaust = True

    upgrade_magic = {"cards": 5}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state
        
        super().on_play(targets)
        
        actions = []
        # Shuffle random Attacks into draw pile
        card_count = self.get_magic_value("cards")

        for _ in range(card_count):
            actions.append(AddRandomCardAction(
                pile="draw_pile",
                card_type=CardType.ATTACK,
                namespace=game_state.player.namespace,
                permanent_cost=0
            ))
        from engine.game_state import game_state
        add_actions(actions)
        return