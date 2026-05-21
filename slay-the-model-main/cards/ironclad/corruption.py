"""
Ironclad Rare Power card - Corruption
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Corruption(Card):
    """Skills cost 0 energy"""

    card_type = CardType.POWER
    rarity = RarityType.RARE

    base_cost = 3
    upgrade_cost = 2

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Apply CorruptionPower
        actions.append(ApplyPowerAction(power="CorruptionPower", target=target, amount=0, duration=-1))

        from engine.game_state import game_state

        add_actions(actions)

        return