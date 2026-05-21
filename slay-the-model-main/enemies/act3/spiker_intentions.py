"""Spiker enemy intentions for Slay the Model."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import AttackAction, ApplyPowerAction
from enemies.intention import Intention
class SpikeAttack(Intention):
    """Spiker Attack intention - deals damage."""
    
    def __init__(self, enemy):
        super().__init__("Attack", enemy)
        self.base_damage = 7  # A17+: 9
    
    def execute(self) -> None:
        """Execute Attack intention."""
        damage = self.base_damage
        from engine.game_state import game_state
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            damage = 9
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )


class BuffThorns(Intention):
    """Spiker Buff Thorns intention - gains Thorns."""
    
    def __init__(self, enemy):
        super().__init__("Buff Thorns", enemy)
        self.base_thorns = 2
    
    def execute(self) -> None:
        """Execute Buff Thorns intention."""
        from engine.game_state import game_state
        add_actions(
        [ApplyPowerAction(
            "thorns", self.enemy, self.base_thorns, -1
        )]
        )
