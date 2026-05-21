"""Transient enemy intention for Slay the Model."""
from engine.runtime_api import add_action, add_actions

from typing import List

from actions.combat import AttackAction
from enemies.intention import Intention
class TransientAttack(Intention):
    """Transient Attack intention - damage scales with turn number."""
    
    def __init__(self, enemy):
        super().__init__("Attack", enemy)
        self.base_damage = 20
    
    def execute(self) -> None:
        """Execute Attack intention - deals 20+N damage where N = turn * 10."""
        current_turn = getattr(self.enemy, '_turn_count', 1)
        
        damage = self.base_damage + (current_turn * 10)
        from engine.game_state import game_state
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            damage = 30 + (current_turn * 10)
        
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )
