from actions.watcher import GainMantraAction
from cards.base import Card
from engine.runtime_api import add_action
from typing import List
from utils.registry import register
from utils.types import CardType, RarityType, TargetType

@register("card")
class Prostrate(Card):
    card_type = CardType.SKILL
    target_type = TargetType.SELF
    rarity = RarityType.COMMON
    base_cost = 0
    base_block = 4
    base_magic = {"mantra": 2}
    base_exhaust = False
    upgrade_magic = {"mantra": 3}
    text_name = "Prostrate"
    text_description = "Gain {block} Block. Gain 2 Mantra. Exhaust."

    def on_play(self, targets: List = []):
        super().on_play(targets)
        add_action(GainMantraAction(self.get_magic_value("mantra")))
