"""Snecko specific intentions."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class PerplexingGlareIntention(Intention):
    """Perplexing Glare - Applies Confused."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("perplexing_glare", enemy)
    
    def execute(self) -> None:
        """Execute Perplexing Glare: applies Confused to player."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(
                power="confused",
                target=game_state.player,
                amount=1,
                duration=1
            )
        ]
        )


class BiteIntention(Intention):
    """Bite - Deals 15 damage (8 on A3+ - note: actually lower on A3+!)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("bite", enemy)
        self.base_damage = 15
    
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


class TailWhipIntention(Intention):
    """Tail Whip - Deals 8 damage, applies 2 Vulnerable (10 dmg, 2 Weak + 2 Vuln on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("tail_whip", enemy)
        self.base_damage = 8
        self.vulnerable_stacks = 2
    
    def execute(self) -> None:
        """Execute Tail Whip: deals damage and applies Vulnerable."""
        from actions.combat import AttackAction, ApplyPowerAction
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
            ),
            ApplyPowerAction(
                power="vulnerable",
                target=game_state.player,
                amount=self.vulnerable_stacks,
                duration=1
            )
        ]
        )
