"""
Berserk power - At the start of your turn, gain 1 Energy and apply 1 Vulnerable.
"""
from typing import Any, List
from actions.base import Action
from powers.base import Power, StackType
from utils.registry import register


@register("power")
class BerserkPower(Power):
    """At the start of your turn, gain 1 Energy and apply 1 Vulnerable."""
    
    name = "Berserk"
    description = "At the start of your turn, gain 1 Energy and apply 1 Vulnerable."
    stack_type = StackType.INTENSITY
    is_buff = False
    
    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        super().__init__(amount=amount, duration=duration, owner=owner)
    
    def on_turn_start(self):
        """Gain 1 Energy and apply Vulnerable at start of turn."""
        
        # Gain 1 Energy directly
        if self.owner and hasattr(self.owner, 'gain_energy'):
            self.owner.gain_energy(self.amount)
        
        return