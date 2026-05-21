"""Dagger minion intentions for Slay the Model."""
from engine.runtime_api import add_action, add_actions

from typing import List

from actions.combat import AttackAction, RemoveEnemyAction
from enemies.intention import Intention


class WoundIntention(Intention):
    """Dagger Wound intention - deals damage and adds Wound."""
    
    def __init__(self, enemy):
        super().__init__("Wound", enemy)
        self.base_damage = 9
    
    def execute(self) -> None:
        """Execute Wound intention."""
        from cards.colorless import Wound
        from engine.game_state import game_state
        
        # Add Wound to player's discard pile
        game_state.player.card_manager.get_pile("discard_pile").append(Wound())
        
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            self.enemy.calculate_damage(self.base_damage),
            game_state.player,
            self.enemy,
            "attack"
        )]
        )


class ExplodeIntention(Intention):
    """Dagger Explode intention - deals damage and dies."""
    
    def __init__(self, enemy):
        super().__init__("Explode", enemy)
        self.base_damage = 25
    
    def execute(self) -> None:
        """Execute Explode intention."""
        from engine.game_state import game_state
        
        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                self.base_damage,
                game_state.player,
                self.enemy,
                "attack"
            ),
            RemoveEnemyAction(self.enemy)
        ]
        )
