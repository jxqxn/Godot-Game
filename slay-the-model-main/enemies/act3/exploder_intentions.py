"""Exploder enemy intentions for Act 3."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import AttackAction
from enemies.intention import Intention


class Attack(Intention):
    """Attack intention for Exploder - deals damage."""

    def __init__(self, enemy):
        super().__init__("Attack", enemy)
        self.base_damage = 9  # 11 on Ascension 2+

    def execute(self) -> None:
        """Execute attack action."""
        from engine.game_state import game_state
        
        damage = self.base_damage
        if game_state.ascension >= 2:
            damage = 11

        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            damage=damage,
            target=game_state.player,
            source=self.enemy,
            damage_type="attack"
        )]
        )


class Explode(Intention):
    """Explode intention - deals heavy damage and dies."""

    def __init__(self, enemy):
        super().__init__("Explode", enemy)
        self.base_damage = 30

    def execute(self) -> None:
        """Execute explode action - deals damage and enemy dies."""
        from engine.game_state import game_state
        
        actions = [AttackAction(
            damage=self.base_damage,
            target=game_state.player,
            source=self.enemy,
            damage_type="attack"
        )]
        # Enemy dies after exploding
        self.enemy.hp = 0
        from engine.game_state import game_state
        add_actions(actions)
