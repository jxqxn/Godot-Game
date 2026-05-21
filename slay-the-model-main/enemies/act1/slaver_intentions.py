"""Slaver (Blue and Red) specific intentions."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class StabIntention(Intention):
    """Stab - Deals damage (12 for Blue, 13 for Red)."""
    
    def __init__(self, enemy: 'Enemy', damage: int = 12):
        super().__init__("stab", enemy)
        self.base_damage = damage
    
    def execute(self) -> None:
        """Execute Stab: deals damage to player."""
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


class RakeIntention(Intention):
    """Rake (Blue Slaver) - Deals 7 damage and applies 1 Weak."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("rake", enemy)
        self.base_damage = 7
        self._weak_stacks = 1
    
    def execute(self) -> None:
        """Execute Rake: deals damage and applies Weak."""
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
                power="Weak",
                target=game_state.player,
                amount=self._weak_stacks,
                duration=self._weak_stacks
            )
        ]
        )


class ScrapeIntention(Intention):
    """Scrape (Red Slaver) - Deals 8 damage and applies 1 Vulnerable."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("scrape", enemy)
        self.base_damage = 8
        self._vulnerable_stacks = 1
    
    def execute(self) -> None:
        """Execute Scrape: deals damage and applies Vulnerable."""
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
                power="Vulnerable",
                target=game_state.player,
                amount=self._vulnerable_stacks,
                duration=self._vulnerable_stacks
            )
        ]
        )


class EntangleIntention(Intention):
    """Entangle (Red Slaver) - Applies Entangled (cannot play Attacks this turn)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("entangle", enemy)
    
    def execute(self) -> None:
        """Execute Entangle: applies Entangled to player."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        # Entangled is a debuff that prevents playing Attack cards for 1 turn
        # We'll use a custom power or mark it
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(
                power="Entangled",
                target=game_state.player,
                amount=1,
                duration=1
            )
        ]
        )
