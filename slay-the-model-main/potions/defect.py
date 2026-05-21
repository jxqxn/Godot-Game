# Defect Potions - Character-specific potions for Defect
from actions.base import LambdaAction
from actions.combat import ApplyPowerAction
from actions.orb import AddOrbAction
from powers.definitions.focus import FocusPower
from orbs.dark import DarkOrb
from player.player import Player
from potions.base import Potion
from utils.types import RarityType
from utils.registry import register

# Common Potions
@register("potion")
class FocusPotion(Potion):
    """Gain 2 Focus (4 with Sacred Bark) - Defect only"""
    rarity = RarityType.COMMON
    category = "Defect"
    name = "Focus Potion"

    def __init__(self):
        super().__init__()
        self._amount = 2  # Sacred Bark doubles to 4

    def on_use(self, targets) -> None:
        self.queue_actions([ApplyPowerAction(FocusPower(amount=self.amount, owner=targets[0]), targets[0])])

# Rare Potions
@register("potion")
class EssenceOfDarkness(Potion):
    """Channel 1 Dark orb per Orb slot (2 per slot with Sacred Bark) - Rare"""
    rarity = RarityType.RARE
    category = "Defect"
    name = "Essence of Darkness"

    def __init__(self):
        super().__init__()
        self._amount = 1  # Sacred Bark doubles to 2 (dark orbs per slot)

    def on_use(self, targets) -> None:
        from engine.game_state import game_state
        self.queue_actions([
            AddOrbAction(DarkOrb())
            for _ in range(game_state.player.orb_manager.max_orb_slots)
        ])

# Uncommon Potions
@register("potion")
class PotionOfCapacity(Potion):
    """Gain 3 Orb slots (6 with Sacred Bark) - Defect only"""
    rarity = RarityType.UNCOMMON
    category = "Defect"
    name = "Potion of Capacity"

    def __init__(self):
        super().__init__()
        self._amount = 3  # Sacred Bark doubles to 6

    def on_use(self, targets) -> None:
        # Gain orb slots
        player = targets[0]
        assert isinstance(player, Player), "Potion of Capacity can only be used by the player"
        self.queue_actions([
            LambdaAction(
                func=lambda: setattr(
                    player.orb_manager,
                    "max_orb_slots",
                    player.orb_manager.max_orb_slots + self.amount,
                )
            )
        ])
