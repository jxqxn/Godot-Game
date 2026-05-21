"""Defect starter skill card - Dualcast."""

from typing import List

from actions.orb import EvokeOrbAction
from cards.base import Card
from entities.creature import Creature
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Dualcast(Card):
    """Evoke your next orb twice."""

    card_type = CardType.SKILL
    rarity = RarityType.STARTER

    base_cost = 1
    upgrade_cost = 0

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        from engine.runtime_api import add_actions

        add_actions([EvokeOrbAction(index=0, times=2)])
