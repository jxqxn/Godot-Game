"""Sharp Hide power for The Guardian defensive mode."""

from engine.runtime_api import add_actions
from actions.combat import DealDamageAction
from powers.base import Power, StackType
from utils.registry import register
from utils.types import DamageType


@register("power")
class SharpHidePower(Power):
    """Reflect damage when attacked."""

    name = "SharpHide"
    description = "When attacked, deal {amount} damage back."
    stack_type = StackType.INTENSITY
    is_buff = True

    def on_physical_attack_taken(
        self,
        damage: int,
        source=None,
        card=None,
        damage_type: str = "physical",
    ):
        if source is None:
            return
        add_actions(
            [
                DealDamageAction(
                    damage=self.amount,
                    target=source,
                    damage_type=DamageType.MAGICAL,
                )
            ]
        )
