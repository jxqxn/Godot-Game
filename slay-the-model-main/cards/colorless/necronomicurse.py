"""
Colorless Special Curse card - Necronomicurse
"""
from actions.card import AddCardAction
from cards.base import Card, COST_UNPLAYABLE
from utils.registry import register
from utils.types import PilePosType
from utils.types import CardType, RarityType


@register("card")
class Necronomicurse(Card):
    """Unplayable, Irremovable"""

    card_type = CardType.CURSE
    rarity = RarityType.SPECIAL

    base_cost = COST_UNPLAYABLE
    removable = False
    upgradeable = False

    def on_exhaust(self):
        add_card = AddCardAction(self.copy(), dest_pile="hand", position=PilePosType.TOP)
        from engine.runtime_api import add_action

        add_action(add_card)

    def on_remove(self):
        from engine.runtime_api import add_action

        add_action(AddCardAction(self.copy(), dest_pile="deck", position=PilePosType.TOP))
