"""
Intangible power for combat effects.
Reduce all damage taken to 1.
"""
from typing import List
from powers.base import Power, StackType
from utils.registry import register
from utils.damage_phase import DamagePhase


@register("power")
class IntangiblePower(Power):
    """Reduce all damage taken to 1."""

    name = "Intangible"
    description = "Reduce all damage taken to 1."
    stack_type = StackType.DURATION
    is_buff = True
    modify_phase = DamagePhase.CAPPING  # Applied last, caps damage to 1

    def __init__(self, amount: int = 0, duration: int = 1, owner=None):
        """
        Args:
            amount: Not used (duration controls effect)
            duration: Duration in turns (default 1)
        """
        super().__init__(amount=amount, duration=duration, owner=owner)
    
    def modify_damage_taken(self, base_damage: int) -> int:
        """Reduce all damage and HP loss to 1."""
        if base_damage > 0:
            return 1
        return base_damage
