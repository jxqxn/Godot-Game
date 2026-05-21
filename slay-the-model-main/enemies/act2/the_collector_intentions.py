"""The Collector intentions - Act 2 Elite enemy."""
from engine.runtime_api import add_action, add_actions

import random
from typing import TYPE_CHECKING, List

from actions.combat import AttackAction, GainBlockAction, ApplyPowerAction
from enemies.intention import Intention
from powers.definitions.strength import StrengthPower
from powers.definitions.weak import WeakPower
from powers.definitions.vulnerable import VulnerablePower
from powers.definitions.frail import FrailPower

if TYPE_CHECKING:
    from enemies.act2.the_collector import TheCollector


class Spawn(Intention):
    """Summons up to 2 Torch Heads."""
    
    def __init__(self, enemy: "TheCollector"):
        super().__init__("Spawn", enemy)
    
    def execute(self) -> None:
        """Execute spawn - summon Torch Heads."""
        from engine.game_state import game_state
        from actions.combat import AddEnemyAction
        from enemies.act2.the_collector import TorchHead
        enemies = (
            game_state.current_combat.enemies
            if game_state.current_combat is not None
            else []
        )
        
        actions = []
        
        # Count alive Torch Heads
        torch_head_count = sum(1 for e in enemies
                             if e.is_alive and isinstance(e, TorchHead))
        
        # Can only have max 2 Torch Heads
        to_summon = min(2, 2 - torch_head_count)
        
        for _ in range(to_summon):
            actions.append(AddEnemyAction(TorchHead))
        
        from engine.game_state import game_state
        
        add_actions(actions)
        
class Fireball(Intention):
    """Deals 18 damage."""
    
    def __init__(self, enemy: "TheCollector"):
        super().__init__("Fireball", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 21 if ascension >= 4 else 18
    
    def execute(self) -> None:
        """Execute fireball attack."""
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


class Buff(Intention):
    """All enemies gain 3 Strength. Gains 15 Block."""
    
    def __init__(self, enemy: "TheCollector"):
        super().__init__("Buff", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_strength_gain = 5 if ascension >= 19 else (4 if ascension >= 4 else 3)
        self.base_block = 18 if ascension >= 9 else 15
    
    def execute(self) -> None:
        """Execute buff - strengthen all allies and gain block."""
        from engine.game_state import game_state
        enemies = (
            game_state.current_combat.enemies
            if game_state.current_combat is not None
            else []
        )
        
        actions = []
        
        # Apply strength to all enemies
        for enemy in enemies:
            if enemy.is_alive:
                actions.append(ApplyPowerAction(StrengthPower(amount=self.base_strength_gain, owner=enemy), enemy))

        
        # Gain block for self
        actions.append(GainBlockAction(
            block=self.base_block,
            target=self.enemy
        ))
        
        from engine.game_state import game_state
        
        add_actions(actions)
        
class MegaDebuff(Intention):
    """Applies 3 Weak, 3 Vulnerable, and 3 Frail."""
    
    def __init__(self, enemy: "TheCollector"):
        super().__init__("Mega Debuff", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_amount = 5 if ascension >= 19 else 3
    
    def execute(self) -> None:
        """Execute mega debuff - apply multiple debuffs."""
        from engine.game_state import game_state
        
        actions = []
        player = game_state.player
        
        # Apply 3 Weak
        actions.append(ApplyPowerAction(WeakPower(amount=self.base_amount, owner=player), player))

        
        # Apply 3 Vulnerable
        actions.append(ApplyPowerAction(VulnerablePower(amount=self.base_amount, owner=player), player))

        
        # Apply 3 Frail
        actions.append(ApplyPowerAction(FrailPower(amount=self.base_amount, owner=player), player))

        
        from engine.game_state import game_state

        
        add_actions(actions)

        
class Tackle(Intention):
    """Deals 7 damage (Torch Head attack)."""
    
    def __init__(self, enemy):
        super().__init__("Tackle", enemy)
        self.base_damage = 7
    
    def execute(self) -> None:
        """Execute tackle attack."""
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
