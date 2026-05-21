"""
PenNib power for double damage on every 10th attack.
"""
from typing import Any, List
from actions.base import Action
from powers.base import Power, StackType
from utils.registry import register


@register("power")
class PenNibPower(Power):
    """Next attack deals double damage."""
    
    name = "PenNib"
    description = "Next attack deals double damage."
    stack_type = StackType.DURATION
    is_buff = True
    
    def __init__(self, amount: int = 0, duration: int = -1, owner=None):
        """
        Args:
            amount: Multiplier (default 1 for double damage)
            duration: Number of attacks this applies to (default 1)
            owner: Creature with this power
        """
        super().__init__(amount=amount, duration=duration, owner=owner)
        self.damage_multiplier = 2  # Double damage
        self.active = True  # Whether the multiplier is active for this attack
    
    def modify_damage_dealt(self, base_damage: int, card=None, target=None) -> int:
        """
        Double damage when an attack is dealt.
        
        This is the correct approach - modify damage through callback
        instead of modifying the card directly.
        """
        if self.active and card and hasattr(card, 'card_type'):
            from utils.types import CardType
            if card.card_type == CardType.ATTACK:
                self.active = False  # Only apply once
                # Directly remove power instead of setting duration
                if self.owner:
                    self.owner.remove_power(self.name)
                return base_damage * self.damage_multiplier
        
        return base_damage
