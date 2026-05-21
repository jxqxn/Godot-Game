"""Spire Growth enemy intentions for Slay the Model."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import AttackAction, ApplyPowerAction
from enemies.intention import Intention
class Constrict(Intention):
    """Spire Growth Constrict intention - applies Constricted."""
    
    def __init__(self, enemy):
        super().__init__("Constrict", enemy)
        self.base_amount = 10  # A17+: 12
    
    def execute(self) -> None:
        """Execute Constrict intention."""
        amount = self.base_amount
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            amount = 12
        from engine.game_state import game_state
        add_actions(
        [ApplyPowerAction(
            "constricted", game_state.player, amount, -1
        )]
        )


class QuickTackle(Intention):
    """Spire Growth Quick Tackle intention - deals damage."""
    
    def __init__(self, enemy):
        super().__init__("Quick Tackle", enemy)
        self.base_damage = 16  # A17+: 18
    
    def execute(self) -> None:
        """Execute Quick Tackle intention."""
        damage = self.base_damage
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            damage = 18
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )


class Smash(Intention):
    """Spire Growth Smash intention - deals damage."""
    
    def __init__(self, enemy):
        super().__init__("Smash", enemy)
        self.base_damage = 22  # A17+: 25
    
    def execute(self) -> None:
        """Execute Smash intention."""
        damage = self.base_damage
        from engine.game_state import game_state
        if game_state.ascension >= 17:
            damage = 25
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )
