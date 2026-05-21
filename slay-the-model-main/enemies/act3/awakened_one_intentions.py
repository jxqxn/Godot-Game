"""Awakened One Boss intentions for Act 3."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.combat import (
    AttackAction,
    GainBlockAction,
    ApplyPowerAction,
)
from actions.card import AddCardAction
from enemies.intention import Intention


class Slash(Intention):
    """Deals 20 damage."""
    
    def __init__(self, enemy):
        super().__init__("Slash", enemy)
        self.base_damage = 20
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            damage=self.base_damage,
            target=game_state.player,
            source=self.enemy,
            damage_type="attack"
        )]
        )


class SoulStrike(Intention):
    """Deals 6x4 damage."""
    
    def __init__(self, enemy):
        super().__init__("Soul Strike", enemy)
        self.base_damage = 6
        self.base_hits = 4
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        actions = []
        for _ in range(self.base_hits):
            actions.append(AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack"
            ))
        from engine.game_state import game_state
        add_actions(actions)
class Rebirth(Intention):
    """Heals to full HP. Removes all debuffs. Loses 1 Curiosity."""
    
    def __init__(self, enemy):
        super().__init__("Rebirth", enemy)
    
    def execute(self) -> None:
        """Execute the intention."""
        self.enemy.powers = [
            power
            for power in self.enemy.powers
            if getattr(power, "is_buff", True)
            and getattr(power, "name", "") not in {"Curiosity", "Unawakened", "Shackled"}
        ]

        # Heal to full HP
        self.enemy.heal(self.enemy.max_hp)
        # Switch to phase 2
        self.enemy._phase = 2
class DarkEcho(Intention):
    """Deals 40 damage."""
    
    def __init__(self, enemy):
        super().__init__("Dark Echo", enemy)
        self.base_damage = 40
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        from engine.game_state import game_state
        add_actions(
        [AttackAction(
            damage=self.base_damage,
            target=game_state.player,
            source=self.enemy,
            damage_type="attack"
        )]
        )


class Sludge(Intention):
    """Deals 18 damage. Adds a Wound into your draw pile."""
    
    def __init__(self, enemy):
        super().__init__("Sludge", enemy)
        self.base_damage = 18
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        from cards.colorless.wound import Wound
        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack"
            ),
            AddCardAction(card=Wound(), dest_pile="draw_pile", source="enemy")
        ]
        )


class Tackle(Intention):
    """Deals 10x3 damage."""
    
    def __init__(self, enemy):
        super().__init__("Tackle", enemy)
        self.base_damage = 10
        self.base_hits = 3
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        actions = []
        for _ in range(self.base_hits):
            actions.append(AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack"
            ))
        from engine.game_state import game_state
        add_actions(actions)
