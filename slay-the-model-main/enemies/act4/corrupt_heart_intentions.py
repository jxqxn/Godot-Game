"""Corrupt Heart boss intentions for Act 4."""
from engine.runtime_api import add_action, add_actions

import random
from typing import List

from actions.base import Action, LambdaAction
from actions.card import AddCardAction
from actions.combat import ApplyPowerAction, AttackAction
from powers.definitions.vulnerable import VulnerablePower
from powers.definitions.weak import WeakPower
from powers.definitions.frail import FrailPower
from powers.definitions.strength import StrengthPower
from powers.definitions.artifact import ArtifactPower
from cards.colorless.burn import Burn
from cards.colorless.dazed import Dazed
from cards.colorless.slimed import Slimed
from cards.colorless.void import Void
from cards.colorless.wound import Wound
from enemies.intention import Intention
from powers.definitions.beat_of_death import BeatOfDeathPower
from powers.definitions.painful_stabs import PainfulStabsPower
from utils.types import PilePosType


class Debilitate(Intention):
    """Apply debuffs and shuffle status cards into draw pile."""

    def __init__(self, enemy):
        super().__init__("Debilitate", enemy)

    def execute(self):
        from engine.game_state import game_state
        player = game_state.player

        actions: List[Action] = [
            ApplyPowerAction(VulnerablePower(amount=2, duration=2, owner=player), player),
            ApplyPowerAction(WeakPower(amount=2, duration=2, owner=player), player),
            ApplyPowerAction(FrailPower(amount=2, duration=2, owner=player), player),
        ]

        for status_cls in (Burn, Dazed, Slimed, Void, Wound):
            actions.append(
                AddCardAction(
                    card=status_cls(),
                    dest_pile="draw_pile",
                    position=PilePosType.TOP,
                )
            )
        from engine.game_state import game_state
        add_actions(actions)
        return
class BloodShots(Intention):
    """Deal 2x12 or 2x15 damage."""

    def __init__(self, enemy):
        super().__init__("Blood Shots", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 2
        self.hits = 15 if ascension >= 4 else 12

    def execute(self):
        from engine.game_state import game_state

        actions: List[Action] = []
        for _ in range(self.hits):
            actions.append(
                AttackAction(
                    damage=self.base_damage,
                    target=game_state.player,
                    source=self.enemy,
                    damage_type="attack",
                )
            )
        from engine.game_state import game_state
        add_actions(actions)
        return
class Echo(Intention):
    """Deal 40 or 45 damage."""

    def __init__(self, enemy):
        super().__init__("Echo", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 45 if ascension >= 4 else 40

    def execute(self):
        from engine.game_state import game_state

        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
        ]
        )
        return


class BuffHeart(Intention):
    """Apply Corrupt Heart scaling buff sequence."""

    def __init__(self, enemy):
        super().__init__("Buff", enemy)

    def execute(self):
        self.enemy._buff_count += 1
        buff_count = self.enemy._buff_count

        actions: List[Action] = [
            LambdaAction(func=self._remove_negative_strength),
            ApplyPowerAction(StrengthPower(amount=2, owner=self.enemy), self.enemy),
        ]

        if buff_count == 1:
            actions.append(ApplyPowerAction(ArtifactPower(amount=2, owner=self.enemy), self.enemy))
        elif buff_count == 2:
            actions.append(LambdaAction(func=self._add_beat_of_death))
        elif buff_count == 3:
            actions.append(LambdaAction(func=self._add_painful_stabs))
        elif buff_count == 4:
            actions.append(ApplyPowerAction(StrengthPower(amount=10, owner=self.enemy), self.enemy))
        elif buff_count == 5:
            actions.append(ApplyPowerAction(StrengthPower(amount=50, owner=self.enemy), self.enemy))

        from engine.game_state import game_state

        add_actions(actions)

        return
    def _remove_negative_strength(self):
        strength = self.enemy.get_power("Strength")
        if strength is not None and strength.amount < 0:
            self.enemy.remove_power("Strength")

    def _add_beat_of_death(self):
        beat = self.enemy.get_power("Beat of Death")
        if beat is None:
            self.enemy.add_power(BeatOfDeathPower(amount=1, owner=self.enemy))
        else:
            beat.amount += 1

    def _add_painful_stabs(self):
        if not self.enemy.has_power("Painful Stabs"):
            self.enemy.add_power(PainfulStabsPower(amount=1, owner=self.enemy))
