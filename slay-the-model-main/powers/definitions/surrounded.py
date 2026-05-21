"""
Surrounded power for combat effects.
Telegraph debuff - no gameplay hooks yet.
"""
from powers.base import Power, StackType
from utils.registry import register


@register("power")
class SurroundedPower(Power):
    """Surrounded power - debuff telegraph with no effect hooks."""
    
    name = "Surrounded"
    description = "从背后被攻击时，受伤+50%"
    stack_type = StackType.PRESENCE
    is_buff = False  # Debuff effect - increases damage taken
    
    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        """
        Args:
            amount: Magnitude (default 1)
            duration: 0 for permanent (unused in telegraph)
            owner: The creature that has this power
        """
        super().__init__(amount=amount, duration=duration, owner=owner)
