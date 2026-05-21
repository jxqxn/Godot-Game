"""
Magnetism power for combat effects.
Add random colorless card to hand at start of turn.
"""
from engine.runtime_api import add_action, add_actions
from typing import List
from actions.base import Action
from actions.card import AddRandomCardAction
from powers.base import Power, StackType
from utils.registry import register
from utils.types import CardType


@register("power")
class MagnetismPower(Power):
    """Add random colorless card to hand at start of turn."""

    name = "Magnetism"
    description = "Add random colorless card to hand at start of turn."
    stack_type = StackType.INTENSITY
    is_buff = True

    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        """
        Args:
            amount: Not used
            duration: 0 for permanent (this combat)
        """
        super().__init__(amount=amount, duration=duration, owner=owner)

    def on_turn_start(self):
        """Add random colorless card to hand at start of turn."""
        from engine.game_state import game_state
        add_actions([AddRandomCardAction(pile="hand", namespace="colorless")])
        return