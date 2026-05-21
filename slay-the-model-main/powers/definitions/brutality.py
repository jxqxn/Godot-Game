"""
Brutality power for Ironclad.
At start of your turn, lose 1 HP and draw 1 card.
"""
from engine.runtime_api import add_action, add_actions
from typing import List
from powers.base import Power, StackType
from actions.base import Action
from actions.card import DrawCardsAction
from actions.combat import LoseHPAction
from utils.registry import register


@register("power")
class BrutalityPower(Power):
    """At start of turn, lose HP and draw cards."""

    name = "Brutality"
    description = "At start of your turn, lose 1 HP and draw 1 card."
    stack_type = StackType.PRESENCE
    is_buff = True

    def __init__(self, amount: int = 0, duration: int = -1, owner=None):
        """
        Args:
            amount: Not used
            duration: 0 for permanent
        """
        super().__init__(amount=amount, duration=duration, owner=owner)

    def on_turn_start_post_draw(self):
        """Lose 1 HP and draw 1 card after the normal turn draw."""
        add_actions(
        [
            LoseHPAction(amount=1),
            DrawCardsAction(count=1),
        ]
        )
        return
