"""
Ironclad Rare Power card - Juggernaut
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
class Juggernaut(Card):
    """Whenever you gain Block, deal 5 damage to ALL enemies"""

    card_type = CardType.POWER
    rarity = RarityType.RARE

    base_cost = 2
    base_magic = {"damage_per_block": 5, "damage": 5}

    upgrade_magic = {"damage_per_block": 7, "damage": 7}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Apply JuggernautPower
        damage_per_block = self.get_magic_value("damage_per_block")
        actions.append(ApplyPowerAction(power="JuggernautPower", target=game_state.player, amount=damage_per_block, duration=-1))

        from engine.game_state import game_state

        add_actions(actions)

        return