"""
Colorless Uncommon Skill card - Dark Shackles
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.strength import StrengthPower
from powers.definitions.strength_up import StrengthUpPower
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class DarkShackles(Card):
    """Enemy loses Strength this turn, Exhaust"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    target_type = TargetType.ENEMY_SELECT

    base_cost = 0
    base_magic = {"strength_loss": 9}
    base_exhaust = True

    upgrade_magic = {"strength_loss": 15}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        super().on_play(targets)
        if targets:
            strength_loss = self.get_magic_value("strength_loss")
            assert target is not None
            actions = [ApplyPowerAction(
                StrengthPower(amount=-strength_loss, duration=1, owner=target),
                target
            )]
            artifact = target.get_power("Artifact")
            if artifact is None or artifact.amount <= 0:
                actions.append(
                    ApplyPowerAction(
                        StrengthUpPower(amount=strength_loss, duration=1, owner=target),
                        target,
                    )
                )
            add_actions(actions)
