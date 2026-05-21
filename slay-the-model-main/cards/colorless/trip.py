"""
Colorless Uncommon Skill card - Trip
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.vulnerable import VulnerablePower
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Trip(Card):
    """Apply Vulnerable to enemy/all enemies"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    base_target_type = TargetType.ENEMY_SELECT
    upgrade_target_type = TargetType.ENEMY_ALL

    base_cost = 0
    base_magic = {"vulnerable": 2}

    upgrade_magic = {"vulnerable": 2}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Apply Vulnerable to target(s)
        vuln_amount = self.get_magic_value("vulnerable")

        if self.upgrade_level > 0:
            # Upgraded: Apply to ALL enemies
            assert game_state.current_combat is not None
            for enemy in game_state.current_combat.enemies:
                actions.append(ApplyPowerAction(
                    VulnerablePower(amount=vuln_amount, duration=vuln_amount, owner=enemy),
                    enemy
                ))
        else:
            # Base: Apply to single target
            if targets:
                actions.append(ApplyPowerAction(
                    VulnerablePower(amount=vuln_amount, duration=vuln_amount, owner=target),
                    target
                ))

        from engine.game_state import game_state

        add_actions(actions)

        return