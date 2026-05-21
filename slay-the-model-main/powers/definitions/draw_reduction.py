"""
Draw Reduction power for Time Eater boss.
Draw 1 less card at the start of each turn.
"""
from typing import List
from powers.base import Power, StackType
from utils.registry import register


@register("power")
class DrawReductionPower(Power):
    """Draw 1 less card at the start of each turn.
    
    This power reduces the number of cards drawn at the start of turn.
    Used by Time Eater's HeadSlam attack.
    """

    name = "Draw Reduction"
    description = "Draw 1 less card at the start of each turn."
    stack_type = StackType.INTENSITY
    is_buff = False  # This is a debuff

    def __init__(self, amount: int = 1, duration: int = 1, owner=None):
        """
        Args:
            amount: Turns of draw reduction (default 1)
            duration: Duration in turns (default 1)
        """
        super().__init__(amount=amount, duration=duration, owner=owner)
    
    def get_draw_reduction(self) -> int:
        """Return the number of cards to reduce from draw count.
        """
        return self.amount