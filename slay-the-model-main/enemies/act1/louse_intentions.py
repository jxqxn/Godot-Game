"""Louse (Red and Green) specific intentions."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class LouseBiteIntention(Intention):
    """Bite - Deals N damage (N is chosen at combat start, between 5-7)."""
    
    def __init__(self, enemy: 'Enemy', damage: int = 5):
        super().__init__("bite", enemy)
        self.base_damage = damage  # Set at combat start
    
    def execute(self) -> None:
        """Execute Bite: deals damage to player."""
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


class RedLouseGrowIntention(Intention):
    """Grow - Gains 3 Strength (4 on A17+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("grow", enemy)
        self.base_strength_gain = 3
    
    def execute(self) -> None:
        """Execute Grow: gains Strength."""
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


class GreenLouseSpitWebIntention(Intention):
    """Spit Web - Applies 2 Weak."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("spit_web", enemy)
    
    def execute(self) -> None:
        """Execute Spit Web: applies 2 Weak to player."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(
                power="Weak",
                target=game_state.player,
                amount=2,
                duration=2
            )
        ]
        )
