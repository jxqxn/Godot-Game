"""The Maw enemy for Slay the Model."""

from typing import Optional
import random

from enemies.act3.the_maw_intentions import (
    TheMawRoar, TheMawSlam, TheMawNomNom, TheMawDrool
)
from enemies.base import Enemy
from utils.types import EnemyType


class TheMaw(Enemy):
    """The Maw is a normal Enemy found exclusively in Act 3.

    Special mechanics:
    - Always starts with Roar (applies 3 Weak and 3 Frail)
    - Afterwards has 50/50 chance of Slam or Nom Nom
    - After Drool: 50/50 between Slam and Nom Nom
    - After Nom Nom: 50/50 between Nom Nom and Drool
    - After Slam: 50/50 between Nom Nom and Drool
    - 300 HP
    """

    enemy_type = EnemyType.NORMAL

    def __init__(self):
        super().__init__(hp_range=(300, 300))
        self._turn_count = 0
        self._last_move = None  # Track last used move

        # Register intentions
        self._roar = TheMawRoar(self)
        self._slam = TheMawSlam(self)
        self._nom_nom = TheMawNomNom(self)
        self._drool = TheMawDrool(self)

        self.add_intention(self._roar)
        self.add_intention(self._slam)
        self.add_intention(self._nom_nom)
        self.add_intention(self._drool)

    def on_combat_start(self, floor: int = 1) -> None:
        """Initialize combat state."""
        super().on_combat_start(floor)
        self._turn_count = 0
        self._last_move = None

    def determine_next_intention(self, floor: int) -> Optional[str]:
        """Determine next intention based on behavior pattern.

        - Always starts with Roar
        - After Roar: 50/50 Slam or Nom Nom
        - After Drool: 50/50 Slam or Nom Nom
        - After Nom Nom: 50/50 Nom Nom or Drool
        - After Slam: 50/50 Nom Nom or Drool
        """
        self._turn_count += 1

        # First turn always Roar
        if self._last_move is None:
            self._last_move = "Roar"
            return self.intentions["Roar"]

        # Determine next move based on last move
        if self._last_move == "Roar" or self._last_move == "Drool":
            # 50/50 between Slam and Nom Nom
            if random.random() < 0.5:
                self._last_move = "Slam"
                return self.intentions["Slam"]
            else:
                self._last_move = "Nom Nom"
                return self.intentions["Nom Nom"]
        elif self._last_move == "Nom Nom" or self._last_move == "Slam":
            # 50/50 between Nom Nom and Drool
            if random.random() < 0.5:
                self._last_move = "Nom Nom"
                return self.intentions["Nom Nom"]
            else:
                self._last_move = "Drool"
                return self.intentions["Drool"]

        # Fallback (shouldn't reach here)
        self._last_move = "Slam"
        return self.intentions["Slam"]