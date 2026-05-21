from engine.runtime_api import add_action
from actions.base import LambdaAction
from actions.combat import DealDamageAction
from orbs.base import Orb
from utils.combat import resolve_target
from utils.dynamic_values import resolve_orb_value
from utils.types import TargetType


class DarkOrb(Orb):
    passive_timing = "turn_end"
    target_type = TargetType.ENEMY_LOWEST_HP
    base_charge = 6

    def __init__(self):
        self.charge = self.base_charge

    def on_passive(self) -> None:
        add_action(
            LambdaAction(
                func=lambda: setattr(self, "charge", self.charge + resolve_orb_value(self.base_charge))
            )
        )

    def on_evoke(self) -> None:
        target_list = resolve_target(self.target_type)
        target = target_list[0] if target_list else None
        if target is None:
            return
        damage = self.charge
        if target.get_power("Lock-On") is not None:
            damage = int(damage * 1.5)
        add_action(
            DealDamageAction(
                damage=damage,
                target=target,
                damage_type="magic",
            )
        )
