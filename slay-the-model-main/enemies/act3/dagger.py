"""Dagger minion for Slay the Model."""

from typing import List, Optional

from enemies.act3.dagger_intentions import WoundIntention, ExplodeIntention
from enemies.base import Enemy
from utils.types import EnemyType


class Dagger(Enemy):
    """Dagger is a Minion enemy summoned only by Reptomancer.
    
    Special mechanics:
    - Uses Wound then Explode (always in this order)
    - Dies after Explode
    - Is a minion and should not trigger on_fatal effects
    """
    
    enemy_type = EnemyType.NORMAL  # Minions are treated as normal enemies
    
    def __init__(self):
        super().__init__(hp_range=(20, 20), is_minion=True)
        self._turn_count = 0
        
        # Register intentions
        self.add_intention(WoundIntention(self))
        self.add_intention(ExplodeIntention(self))
    
    def determine_next_intention(self, floor: int) -> Optional[str]:
        """Determine next intention - Wound then Explode."""
        self._turn_count += 1
        
        if self._turn_count == 1:
            return self.intentions["Wound"]
        else:
            return self.intentions["Explode"]
