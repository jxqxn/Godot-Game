"""Time Eater Boss intentions for Act 3."""
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


class Reverberate(Intention):
    """Deals 7x3 damage."""
    
    def __init__(self, enemy):
        super().__init__("Reverberate", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 8 if ascension >= 4 else 7
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
class HeadSlam(Intention):
    """Deals 26 damage. Applies 1 Draw Reduction."""
    
    def __init__(self, enemy):
        super().__init__("Head Slam", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 32 if ascension >= 4 else 26
        self.base_draw_reduction = 1
    
    def execute(self) -> None:
        """Execute the intention."""
        from cards.colorless.slimed import Slimed
        from engine.game_state import game_state
        
        actions = [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack"
            ),
            ApplyPowerAction(
                power="DrawReductionPower",
                target=game_state.player,
                amount=self.base_draw_reduction,
                duration=self.base_draw_reduction
            )
        ]
        if getattr(game_state, "ascension", 0) >= 19:
            actions.extend(
                [
                    AddCardAction(card=Slimed(), dest_pile="discard_pile", source="enemy"),
                    AddCardAction(card=Slimed(), dest_pile="discard_pile", source="enemy"),
                ]
            )
        add_actions(actions)
class Ripple(Intention):
    """Gains 20 block. Applies 1 Vulnerable and 1 Weak."""
    
    def __init__(self, enemy):
        super().__init__("Ripple", enemy)
        self.base_block = 20
        self.base_amount = 1
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state
        
        actions = [
            GainBlockAction(
                block=self.base_block,
                target=self.enemy
            ),
            ApplyPowerAction(
                power="vulnerable",
                target=game_state.player,
                amount=self.base_amount,
                duration=1
            ),
            ApplyPowerAction(
                power="weak",
                target=game_state.player,
                amount=self.base_amount,
                duration=1
            )
        ]
        if getattr(game_state, "ascension", 0) >= 19:
            actions.append(
                ApplyPowerAction(
                    power="frail",
                    target=game_state.player,
                    amount=self.base_amount,
                    duration=1,
                )
            )
        add_actions(actions)
class Haste(Intention):
    """Removes all debuffs. Heals to 50% HP."""
    
    def __init__(self, enemy):
        super().__init__("Haste", enemy)
    
    def execute(self) -> None:
        """Execute the intention."""
        from engine.game_state import game_state

        self.enemy.powers = [
            power for power in self.enemy.powers
            if getattr(power, "is_buff", True)
        ]

        target_hp = self.enemy.max_hp // 2
        heal_amount = max(0, target_hp - self.enemy.hp)
        self.enemy.heal(heal_amount)
        if getattr(game_state, "ascension", 0) >= 19:
            self.enemy.gain_block(self.enemy.intentions["Head Slam"].base_damage)
        # Mark that haste was used
        self.enemy._haste_used = True
