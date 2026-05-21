"""
Demon Form power for Ironclad.
At end of your turn, gain Strength.
"""
from engine.runtime_api import add_action, add_actions
from typing import List, Any
from powers.base import Power, StackType
from actions.base import Action
from utils.registry import register


@register("power")
class DemonFormPower(Power):
    """At start of your turn, gain Strength."""

    name = "Demon Form"
    description = "At end of your turn, gain Strength."
    stack_type = StackType.INTENSITY
    is_buff = True

    def __init__(self, amount: int = 2, duration: int = -1, owner=None):
        """
        Args:
            amount: Strength to gain each turn
            duration: 0 for permanent
        """
        super().__init__(amount=amount, duration=duration, owner=owner)

    def on_turn_start_post_draw(self):
        """Gain Strength after the normal turn draw."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        from powers.definitions.strength import StrengthPower

        actions = []
        if game_state.player:
            actions.append(ApplyPowerAction(
                StrengthPower(amount=self.amount, owner=game_state.player),
                game_state.player
            ))

        from engine.game_state import game_state

        add_actions(actions)

        return
