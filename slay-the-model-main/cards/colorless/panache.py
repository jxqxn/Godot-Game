"""
Colorless Rare Power card - Panache
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from cards.base import Card
from entities.creature import Creature
from powers.base import Power
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Panache(Card):
    """Power: Deal damage to all enemies when playing 5 cards"""

    card_type = CardType.POWER
    rarity = RarityType.RARE

    base_cost = 0
    base_magic = {"damage": 10}

    upgrade_magic = {"damage": 14}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state
        from actions.combat import ApplyPowerAction

        super().on_play(targets)

        actions = []
        # Apply Panache power
        damage_amount = self.get_magic_value("damage")
        actions.append(ApplyPowerAction(
            power="PanachePower",
            target=game_state.player,
            amount=damage_amount,
            duration=-1  # Permanent for this combat
        ))

        from engine.game_state import game_state

        add_actions(actions)

        return