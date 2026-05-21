"""Donu Boss intentions for Act 3."""
from engine.runtime_api import add_action, add_actions

from typing import List

from actions.combat import (
    AttackAction,
    ApplyPowerAction,
)
from enemies.intention import Intention


class CircleOfPower(Intention):
    """All enemies gain 3 Strength."""
    
    def __init__(self, enemy):
        super().__init__("Circle of Power", enemy)
        self.base_strength_gain = 3
    
    def execute(self) -> None:
        """Execute the intention - give all enemies 3 Strength."""
        from engine.game_state import game_state
        
        actions = []
        combat = game_state.current_combat
        if combat is None:
            return
        # Apply Strength to all enemies
        for enemy in combat.enemies:
            if not enemy.is_dead:
                actions.append(ApplyPowerAction(
                    power="strength",
                    target=enemy,
                    amount=self.base_strength_gain
                ))
        from engine.game_state import game_state
        add_actions(actions)
class Beam(Intention):
    """Deals 10x2 damage."""
    
    def __init__(self, enemy):
        super().__init__("Beam", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 12 if ascension >= 4 else 10
        self.base_hits = 2
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        
        actions = []
        for _ in range(self.base_hits):
            actions.append(AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack"
            ))
        from engine.game_state import game_state
        add_actions(actions)
