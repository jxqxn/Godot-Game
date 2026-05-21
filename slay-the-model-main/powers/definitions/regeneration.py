"""
Regeneration power for combat effects.
Heal HP at end of turn; Regen reduces by 1 each turn.
"""
from engine.runtime_api import add_action, add_actions
from typing import List
from actions.base import Action
from actions.combat import HealAction
from powers.base import Power, StackType
from utils.registry import register

@register("power")
class RegenerationPower(Power):
    """Heal HP at end of turn; Regen reduces by 1 each turn."""
    
    name = "Regeneration"
    description = "Heal HP at end of turn; Regen reduces by 1 each turn."
    stack_type = StackType.LINKED
    amount_equals_duration = True
    is_buff = True  # Beneficial effect - heals over time
    
    def __init__(self, amount: int = 0, duration: int = 5, owner=None):
        """
        Args:
            amount: HP to heal each turn (default 5)
            duration: 0 for permanent, positive for temporary turns
        """
        super().__init__(amount=duration, duration=duration, owner=owner)
        
    def on_turn_end(self):
        from engine.game_state import game_state
        add_actions([HealAction(amount=self.amount)])
        super().on_turn_end()
        return