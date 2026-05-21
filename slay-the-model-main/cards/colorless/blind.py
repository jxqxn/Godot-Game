"""
Colorless Uncommon Skill card - Blind
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import ApplyPowerAction
from cards.base import Card
from entities.creature import Creature
from powers.definitions.weak import WeakPower
from utils.registry import register
from utils.types import CardType, RarityType, TargetType


@register("card")
class Blind(Card):
    """Apply Weak to enemy/all enemies"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON
    base_target_type = TargetType.ENEMY_SELECT
    upgrade_target_type = TargetType.ENEMY_ALL

    base_cost = 0

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state

        super().on_play(targets)

        actions = []
        # Apply Weak to target(s)
        weak_amount = 2

        if self.upgrade_level > 0:
            # Upgraded: Apply to ALL enemies
            assert game_state.current_combat is not None
            for enemy in game_state.current_combat.enemies:
                actions.append(ApplyPowerAction(
                    WeakPower(amount=weak_amount, duration=weak_amount, owner=enemy),
                    enemy
                ))
        else:
            # Base: Apply to single target
            if targets:
                actions.append(ApplyPowerAction(
                    WeakPower(amount=weak_amount, duration=weak_amount, owner=target),
                    target
                ))

        from engine.game_state import game_state

        add_actions(actions)

        return