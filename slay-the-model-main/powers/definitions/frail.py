"""
Frail power for combat effects.
Reduce block gained by 25%.
"""
from typing import List
from powers.base import Power, StackType
from utils.registry import register


@register("power")
class FrailPower(Power):
    """Reduce block gained by 25%."""

    name = "Frail"
    description = "Reduce block gained by 25%."
    stack_type = StackType.DURATION
    is_buff = False

    def __init__(self, amount: int = 0, duration: int = 1, owner=None):
        """
        Args:
            amount: Frail stacks (default 1)
            duration: Duration in turns (default 1)
        """
        super().__init__(amount=amount, duration=duration, owner=owner)
    
    def modify_block_gained(self, base_block: int) -> int:
        """Reduce block gained by 25%."""
        return int(base_block * 0.75)
