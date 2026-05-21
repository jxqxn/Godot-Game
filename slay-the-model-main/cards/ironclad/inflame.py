"""
Ironclad Uncommon Power card - Inflame
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.strength import StrengthPower
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Inflame(Card):
    """Gain 2 Strength"""

    card_type = CardType.POWER
    rarity = RarityType.UNCOMMON

    base_cost = 1
    base_magic = {"strength": 2}

    upgrade_magic = {"strength": 3}
    
    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Gain Strength (permanent)
        strength_amount = self.get_magic_value("strength")
        actions.extend([
            ApplyPowerAction(StrengthPower(amount=strength_amount, owner=game_state.player), game_state.player),
        ])
        from engine.game_state import game_state
        add_actions(actions)
        return