"""
Ironclad Common Attack card - Body Slam
"""

from cards.base import Card
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class BodySlam(Card):
    """Deal damage equal to your block"""

    card_type = CardType.ATTACK
    rarity = RarityType.COMMON

    base_cost = 1
    base_damage = 0  # Base damage is 0, will be calculated dynamically

    upgrade_cost = 0

    @property
    def damage(self) -> int:
        """Damage equals current block"""
        from engine.game_state import game_state
        return game_state.player.block
