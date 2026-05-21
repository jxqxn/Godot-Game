"""
Ironclad Common Attack card - Clash
"""

from typing import Optional
from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Clash(Card):
    """Deal damage if all cards in hand are Attacks"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 0
    base_damage = 14

    upgrade_damage = 18

    def can_play(self, ignore_energy=False) -> tuple[bool, Optional[str]]:
        """Can only play if every card in hand is an Attack"""
        from engine.game_state import game_state

        for card in game_state.player.card_manager.get_pile('hand'):
            if card.card_type != CardType.ATTACK:
                return False, "All cards in hand must be Attacks."

        return super().can_play(ignore_energy=ignore_energy)
