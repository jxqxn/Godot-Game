"""Reptomancer enemy intentions for Slay the Model."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import AttackAction, ApplyPowerAction, AddEnemyAction
from enemies.act3.dagger import Dagger
from enemies.intention import Intention
from powers.definitions.weak import WeakPower


class SpawnDaggerIntention(Intention):
    """Reptomancer Spawn Dagger intention - summons a Dagger."""
    
    def __init__(self, enemy):
        super().__init__("Spawn Dagger", enemy)
    
    def execute(self) -> None:
        """Execute Spawn Dagger intention."""
        from engine.game_state import game_state
        combat = game_state.current_combat
        if combat is None:
            return
        
        # Maximum 4 Daggers can be in play
        dagger_count = sum(1 for e in combat.enemies if isinstance(e, Dagger))
        
        if dagger_count < 4:
            from engine.game_state import game_state
            add_actions([AddEnemyAction(Dagger())])
            return
class BigBiteIntention(Intention):
    """Reptomancer Big Bite intention - 30 damage."""
    
    def __init__(self, enemy):
        super().__init__("Big Bite", enemy)
        self.base_damage = 30
    
    def execute(self) -> None:
        """Execute Big Bite intention."""
        from engine.game_state import game_state
        
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(self.base_damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )


class SnakeStrikeIntention(Intention):
    """Reptomancer Snake Strike intention - 13x2 damage + Weak."""
    
    def __init__(self, enemy):
        super().__init__("Snake Strike", enemy)
        self.base_damage = 13  # A17+ only
        self.base_times = 2
    
    def execute(self) -> None:
        """Execute Snake Strike intention."""
        from engine.game_state import game_state
        
        actions = []
        for _ in range(self.base_times):
            actions.append(AttackAction(
                self.enemy.calculate_damage(self.base_damage),
                game_state.player,
                self.enemy,
                "attack"
            ))
        actions.append(ApplyPowerAction(WeakPower(amount=1, owner=game_state.player), game_state.player))
        from engine.game_state import game_state
        add_actions(actions)
