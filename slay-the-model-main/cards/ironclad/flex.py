"""
Ironclad Common Skill card - Flex
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.strength import StrengthPower
from powers.definitions.strength_down import StrengthDownPower
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Flex(Card):
    """Gain Strength, lose it at end of turn"""

    card_type = CardType.SKILL
    rarity = RarityType.COMMON

    base_cost = 0
    base_magic = {"temp_strength": 2}

    upgrade_magic = {"temp_strength": 4}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Gain temporary Strength
        strength_amount = self.get_magic_value("temp_strength")
        actions.extend([
            ApplyPowerAction(StrengthPower(amount=strength_amount, owner=game_state.player), game_state.player),
            ApplyPowerAction(StrengthDownPower(amount=strength_amount, duration=1, owner=game_state.player), game_state.player)  # This power should handle the strength loss at end of turn
        ])
        from engine.game_state import game_state
        add_actions(actions)
        return