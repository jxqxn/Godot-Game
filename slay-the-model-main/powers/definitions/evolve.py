"""
Evolve power for Ironclad.
Whenever you draw a status card, draw additional cards.
"""
from engine.runtime_api import add_action, add_actions
from typing import TYPE_CHECKING, List, Any
from powers.base import Power, StackType
from actions.base import Action
from actions.card import DrawCardsAction
from utils.registry import register


@register("power")
class EvolvePower(Power):
    """Whenever you draw a status card, draw 1/2."""

    name = "Evolve"
    description = "Whenever you draw a status card, draw 1/2."
    stack_type = StackType.INTENSITY
    is_buff = True

    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        """
        Args:
            amount: Cards to draw when status is drawn (default 1)
            duration: 0 for permanent
        """
        super().__init__(amount=amount, duration=duration, owner=owner)

    def on_card_draw(self, card: Any):
        """Draw additional card when a status card is drawn."""
        if TYPE_CHECKING:
            from utils.types import CardType

        # Check if drawn card is a status card (non-character card)
        from engine.game_state import game_state
        if hasattr(card, 'card_type') and card.card_type == CardType.STATUS:
            from engine.game_state import game_state
            add_actions([DrawCardsAction(count=self.amount)])
            return
        return