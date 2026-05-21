"""
Colorless Rare Skill card - Secret Technique
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.card import ChooseMoveCardAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class SecretTechnique(Card):
    """Put Skill from draw pile into hand, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.RARE

    base_cost = 0
    base_exhaust = True
    upgrade_exhaust = False

    # Note: Upgraded version removes Exhaust flag

    def can_play(self, ignore_energy=False):
        can_play, reason = super().can_play(ignore_energy)
        if not can_play:
            return can_play, reason
        from engine.game_state import game_state

        player = game_state.player
        if player is None:
            return False, "No player."
        has_skill = any(
            card.card_type == CardType.SKILL
            for card in player.card_manager.get_pile("draw_pile")
        )
        if not has_skill:
            return False, "No Skill in draw pile."
        return True, None

    def on_play(self, targets: List[Creature] = []):
        from engine.game_state import game_state

        super().on_play(targets)

        if game_state.player and hasattr(game_state.player, "card_manager"):
            add_actions([ChooseMoveCardAction(
                src="draw_pile",
                dst="hand",
                amount=1,
                filter_card_type=CardType.SKILL
            )])
