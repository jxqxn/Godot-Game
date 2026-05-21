"""
Dexterity power for combat effects.
Increases Block gained from cards.
"""
from typing import List
from powers.base import Power, StackType
from utils.registry import register

@register("power")
class DexterityPower(Power):
    """Increases Block gained from cards."""
    
    name = "Dexterity"
    description = "Increases Block gained from cards."
    stack_type = StackType.INTENSITY
    is_buff = True  # Beneficial effect - increases block
    
    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        """
        Args:
            amount: Dexterity amount (default 1)
            duration: 0 for permanent, positive for temporary turns
        """
        super().__init__(amount=amount, duration=duration, owner=owner)

    def modify_block_gained(self, base_block: int) -> int:
        """Modify block gained from cards by Dexterity amount.
        
        Args:
            base_block: Base block amount before modification
            
        Returns:
            Modified block amount (base + dexterity)
        """
        return base_block + self.amount
