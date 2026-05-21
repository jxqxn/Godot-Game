"""Chosen specific intentions."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class PokeIntention(Intention):
    """Poke - Deals 5x2 damage (6x2 on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("poke", enemy)
        self.base_damage = 5
        self.hits = 2
    
    def execute(self) -> None:
        """Execute Poke: deals 5x2 damage to player."""
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
class HexIntention(Intention):
    """Hex - Applies Hex status to player."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("hex", enemy)
    
    def execute(self) -> None:
        """Execute Hex: applies Hex to player."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        from powers.definitions.hex import HexPower

        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            ApplyPowerAction(HexPower(amount=1, owner=game_state.player), game_state.player)
        ]
        )



class DebilitateIntention(Intention):
    """Debilitate - Deals 10 damage, applies 2 Vulnerable (12 dmg on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("debilitate", enemy)
        self.base_damage = 10
        self.vulnerable_stacks = 2
    
    def execute(self) -> None:
        """Execute Debilitate: deals damage and applies Vulnerable."""
        from actions.combat import AttackAction, ApplyPowerAction
        from engine.game_state import game_state
        from powers.definitions.vulnerable import VulnerablePower


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
            ApplyPowerAction(VulnerablePower(amount=self.vulnerable_stacks, owner=game_state.player), game_state.player)

        ]
        )


class DrainIntention(Intention):
    """Drain - Applies 3 Weak to player, gains 3 Strength."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("drain", enemy)
        self.weak_stacks = 3
        self.strength_gain = 3
    
    def execute(self) -> None:
        """Execute Drain: applies Weak and gains Strength."""
        from actions.combat import ApplyPowerAction
        from engine.game_state import game_state
        from powers.definitions.strength import StrengthPower
        from powers.definitions.weak import WeakPower


        actions = [
            ApplyPowerAction(StrengthPower(amount=self.strength_gain, owner=self.enemy), self.enemy)
        ]


        
        if game_state and game_state.player:
            actions.append(
                ApplyPowerAction(WeakPower(amount=self.weak_stacks, owner=game_state.player), game_state.player)
            )



        from engine.game_state import game_state



        add_actions(actions)



class ZapIntention(Intention):
    """Zap - Deals 18 damage (21 on A3+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("zap", enemy)
        self.base_damage = 18
    
    def execute(self) -> None:
        """Execute Zap: deals 18 damage to player."""
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
