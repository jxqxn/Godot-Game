"""
Colorless Uncommon Attack card - Mind Blast
"""

from typing import List
from actions.base import Action
from actions.combat import AttackAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class MindBlast(Card):
    """Damage equals draw pile size, Innate"""

    card_type = CardType.ATTACK
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 2
    base_innate = True

    upgrade_cost = 1

    @property
    def damage(self) -> int:
        """Damage equals card num in draw_pile"""
        from engine.game_state import game_state
        return len(game_state.player.card_manager.get_pile('draw_pile'))