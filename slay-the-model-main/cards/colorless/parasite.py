"""
Colorless Curse card - Parasite
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ModifyMaxHpAction
from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Parasite(Card):
    """Unplayable, lose 3 Max HP if removed from deck"""

    card_type = CardType.CURSE
    rarity = RarityType.CURSE

    base_cost = COST_UNPLAYABLE
    upgradeable = False

    def on_remove(self):
        """Lose 3 Max HP when exhausted/removed from deck"""
        from actions.combat import ModifyMaxHpAction

        max_hp_loss = 3
        from engine.game_state import game_state
        add_actions([ModifyMaxHpAction(amount=-max_hp_loss)])
        return