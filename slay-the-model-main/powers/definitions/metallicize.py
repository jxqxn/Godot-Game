"""
Metallicize power for Ironclad.
Gain block at the end of your turn.
"""
from engine.runtime_api import add_action, add_actions
from typing import List, Any
from actions.base import Action
from powers.base import Power, StackType
from actions.combat import GainBlockAction
from utils.registry import register


@register("power")
class MetallicizePower(Power):
    """Gain 3/4 block at end of your turn."""

    name = "Metallicize"
    description = "Gain 3/4 block at end of your turn."
    stack_type = StackType.INTENSITY
    is_buff = True

    def __init__(self, amount: int = 3, duration: int = -1, owner=None):
        """
        Args:
            amount: Block to gain each turn (default 3)
            duration: 0 for permanent
        """
        super().__init__(amount=amount, duration=-1, owner=owner)

    def on_turn_end(self):
        """Gain block at end of turn for the owner."""
        if self.owner:
            from engine.game_state import game_state
            add_actions([GainBlockAction(block=self.amount, target=self.owner)])
            return
        return