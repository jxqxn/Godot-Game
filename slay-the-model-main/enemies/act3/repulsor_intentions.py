"""Repulsor enemy intentions for Slay the Model."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import AttackAction
from enemies.intention import Intention
class DazeIntention(Intention):
    """Repulsor Daze intention - adds Dazed cards to player's draw pile."""
    
    def __init__(self, enemy):
        super().__init__("Daze", enemy)
        self.base_amount = 2
    
    def execute(self) -> None:
        """Execute Daze intention - adds 2 Dazed cards to draw pile."""
        from cards.colorless import Dazed
        
        # Add 2 Dazed cards to player's draw pile
        for _ in range(self.base_amount):
            from engine.game_state import game_state
            game_state.player.card_manager.get_pile("draw_pile").append(Dazed())
        
class RepulsorAttack(Intention):
    """Repulsor Attack intention - deals damage."""
    
    def __init__(self, enemy):
        super().__init__("Attack", enemy)
        self.base_damage = 11  # A17+: 13
    
    def execute(self) -> None:
        """Execute Attack intention."""
        damage = self.base_damage
        from engine.game_state import game_state
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            damage = 13
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )
