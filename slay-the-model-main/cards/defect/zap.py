"""Defect starter skill card - Zap."""

from typing import List

from actions.orb import AddOrbAction
from cards.base import Card
from entities.creature import Creature
from orbs.lightning import LightningOrb
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class Zap(Card):
    """Channel 1 Lightning."""

    card_type = CardType.SKILL
    rarity = RarityType.STARTER

    base_cost = 1
    upgrade_cost = 0

    def on_play(self, targets: List[Creature] = []):
        super().on_play(targets)
        from engine.runtime_api import add_actions

        add_actions([AddOrbAction(LightningOrb())])
