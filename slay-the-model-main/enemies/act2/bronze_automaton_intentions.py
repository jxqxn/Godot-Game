"""Bronze Automaton intentions."""
from engine.runtime_api import add_action, add_actions

from typing import List
from enemies.intention import Intention
from actions.combat import (
    AttackAction,
    GainBlockAction,
    ApplyPowerAction,
    AddEnemyAction,
)


class SpawnOrbs(Intention):
    """Summon 2 Bronze Orbs."""

    def __init__(self, enemy):
        super().__init__("Spawn Orbs", enemy)

    def execute(self) -> None:
        """Summon 2 Bronze Orb minions."""
        from enemies.act2.bronze_orb import BronzeOrb
        actions = []
        # Summon 2 Bronze Orbs
        for _ in range(2):
            orb = BronzeOrb()
            actions.append(AddEnemyAction(orb))
        from engine.game_state import game_state
        add_actions(actions)
class Flail(Intention):
    """Deal 7x2 damage."""

    def __init__(self, enemy):
        super().__init__("Flail", enemy)
        self.base_damage = 7
        self.hits = 2

    def execute(self) -> None:
        """Deal damage to player twice."""
        from engine.game_state import game_state
        actions = []
        for _ in range(self.hits):
            actions.append(
                AttackAction(self.base_damage, game_state.player, self.enemy, "attack")
            )
        from engine.game_state import game_state
        add_actions(actions)
class Boost(Intention):
    """Gain 3 Strength and 9 Block (4 Strength A17+)."""

    def __init__(self, enemy):
        super().__init__("Boost", enemy)
        self.base_block = 9
        self.base_strength_gain = 3

    def execute(self) -> None:
        """Gain strength and block."""
        from engine.game_state import game_state
        actions = []
        # Gain Strength (4 on A17+, 3 otherwise)
        strength_gain = 4 if game_state.ascension >= 17 else 3
        actions.append(
            ApplyPowerAction("strength", self.enemy, strength_gain)
        )
        # Gain Block
        actions.append(GainBlockAction(self.base_block, self.enemy))
        from engine.game_state import game_state
        add_actions(actions)
class HyperBeam(Intention):
    """Deal 45 damage (54 A17+)."""

    def __init__(self, enemy):
        super().__init__("Hyper Beam", enemy)
        self.base_damage = 45

    def execute(self) -> None:
        """Deal heavy damage to player."""
        from engine.game_state import game_state
        from engine.game_state import game_state
        add_actions([AttackAction(self.base_damage, game_state.player, self.enemy, "attack")])
class Stunned(Intention):
    """Does nothing (Stunned turn)."""

    def __init__(self, enemy):
        super().__init__("Stunned", enemy)

    def execute(self) -> None:
        """Do nothing."""
