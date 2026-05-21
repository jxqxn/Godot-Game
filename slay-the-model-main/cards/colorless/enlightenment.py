"""
Colorless Uncommon Skill card - Enlightenment
"""
from typing import List
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Enlightenment(Card):
    """Reduce cost of all cards in hand to 1 energy"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 0

    def on_play(self, targets: List[Creature] = []):
        from engine.game_state import game_state

        super().on_play(targets)

        if game_state.player and hasattr(game_state.player, "card_manager"):
            hand_cards = list(game_state.player.card_manager.get_pile("hand"))
            for card in hand_cards:
                current_cost = card.cost
                base_cost = getattr(card, "_cost", current_cost)
                if self.upgrade_level == 0:
                    if current_cost > 1:
                        card.cost_until_end_of_turn = 1
                else:
                    if current_cost > 1:
                        card.cost_until_end_of_turn = 1
                    if base_cost > 1:
                        card.cost = 1
