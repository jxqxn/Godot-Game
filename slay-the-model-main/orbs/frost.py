from engine.runtime_api import add_action
from actions.combat import GainBlockAction
from orbs.base import Orb
from utils.dynamic_values import resolve_orb_value


class FrostOrb(Orb):
    passive_timing = "turn_end"

    def __init__(self):
        self.passive_block = 2
        self.evoke_block = 5

    def on_passive(self) -> None:
        from engine.game_state import game_state

        add_action(
            GainBlockAction(
                block=resolve_orb_value(self.passive_block),
                target=game_state.player,
            )
        )

    def on_evoke(self) -> None:
        from engine.game_state import game_state

        add_action(
            GainBlockAction(
                block=resolve_orb_value(self.evoke_block),
                target=game_state.player,
            )
        )
