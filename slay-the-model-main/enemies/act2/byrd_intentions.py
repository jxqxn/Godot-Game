"""Byrd specific intentions."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class PeckIntention(Intention):
    """Peck - Deals 1x5 damage (1x6 on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("peck", enemy)
        self.base_damage = 5
        self.hits = 5
    
    def execute(self) -> None:
        """Execute Peck: deals 1x5 damage to player."""
        from actions.combat import AttackAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        actions = []
        for _ in range(self.hits):
            actions.append(
                AttackAction(
                    damage=self.base_damage,
                    target=game_state.player,
                    source=self.enemy,
                    damage_type="attack",
                )
            )
        from engine.game_state import game_state
        add_actions(actions)
class CawIntention(Intention):
    """Caw - Gains 1 Strength."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("caw", enemy)
        self.base_strength_gain = 1
    
    def execute(self) -> None:
        """Execute Caw: gains 1 Strength."""
        from actions.combat import ApplyPowerAction
        
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(
                power="strength",
                target=self.enemy,
                amount=self.base_strength_gain,
                duration=-1
            )
        ]
        )


class SwoopIntention(Intention):
    """Swoop - Deals 12 damage (17 on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("swoop", enemy)
        self.base_damage = 12
    
    def execute(self) -> None:
        """Execute Swoop: deals damage to player."""
        from actions.combat import AttackAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
        ]
        )


class StunnedIntention(Intention):
    """Stunned - Does nothing."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("stunned", enemy)
    
    def execute(self) -> None:
        """Execute Stunned: does nothing."""
class HeadbuttIntention(Intention):
    """Headbutt - Deals 3 damage."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("headbutt", enemy)
        self.base_damage = 3
    
    def execute(self) -> None:
        """Execute Headbutt: deals 3 damage to player."""
        from actions.combat import AttackAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
        ]
        )


class GoAirborneIntention(Intention):
    """Go Airborne - Gains 3 Flying."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("go_airborne", enemy)
        self.base_flying_gain = 3
    
    def execute(self) -> None:
        """Execute Go Airborne: gains Flying status."""
        from actions.combat import ApplyPowerAction
        
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(
                power="Flying",
                target=self.enemy,
                amount=self.base_flying_gain,
                duration=-1
            )
        ]
        )
