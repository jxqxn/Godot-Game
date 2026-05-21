# Silent Potions - Character-specific potions for Silent
from actions.card import AddCardAction
from actions.combat import ApplyPowerAction
from powers.definitions.poison import PoisonPower
from powers.definitions.intangible import IntangiblePower
from potions.base import Potion
from utils.types import RarityType, TargetType
from utils.random import get_random_card
from utils.registry import get_registered_instance, register

# Common Potions
@register("potion")
class PoisonPotion(Potion):
    """Apply 6 Poison to target enemy (12 with Sacred Bark) - Silent only"""
    rarity = RarityType.COMMON
    category = "Silent"
    name = "Poison Potion"
    target_type = TargetType.ENEMY_SELECT
    def __init__(self):
        super().__init__()
        self._amount = 6  # Sacred Bark doubles to 12

    def on_use(self, targets) -> None:
        self.queue_actions([ApplyPowerAction(PoisonPower(amount=self.amount, owner=targets[0]), targets[0])])

# Uncommon Potions
@register("potion")
class CunningPotion(Potion):
    """Add 3 Shiv+ cards to hand (6 with Sacred Bark) - Silent only"""
    rarity = RarityType.UNCOMMON
    category = "Silent"
    name = "Cunning Potion"

    def __init__(self):
        super().__init__()
        self._amount = 3  # Sacred Bark doubles to 6

    def on_use(self, targets) -> None:
        from actions.card import AddCardAction
        from utils.random import get_random_card
        
        actions = []
        for _ in range(self.amount):
            shiv_card = get_registered_instance("card", "Shiv")
            if shiv_card:
                shiv_card.upgrade()  # Upgrade to Shiv+
                actions.append(AddCardAction(card=shiv_card, dest_pile='hand'))
        
        self.queue_actions(actions)

# Rare Potions
@register("potion")
class GhostInAJar(Potion):
    """Gain 1 Intangible (2 with Sacred Bark) - Silent only"""
    rarity = RarityType.RARE
    category = "Silent"
    name = "Ghost in a Jar"

    def __init__(self):
        super().__init__()
        self._amount = 1  # Sacred Bark doubles to 2

    def on_use(self, targets) -> None:
        from engine.game_state import game_state
        self.queue_actions([ApplyPowerAction(IntangiblePower(amount=self.amount, owner=game_state.player), game_state.player)])

