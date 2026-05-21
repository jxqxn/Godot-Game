"""
Colorless Rare Skill card - Apotheosis
"""
from typing import List
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Apotheosis(Card):
    """Upgrade ALL cards for this battle, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 2
    base_exhaust = True

    upgrade_cost = 1

    def on_play(self, targets: List[Creature] = []):
        from engine.game_state import game_state

        super().on_play(targets)
        player = game_state.player
        if player is None:
            return

        for pile_name in ("hand", "draw_pile", "discard_pile", "exhaust_pile"):
            for card in list(player.card_manager.get_pile(pile_name)):
                if card.can_upgrade():
                    card.upgrade()
