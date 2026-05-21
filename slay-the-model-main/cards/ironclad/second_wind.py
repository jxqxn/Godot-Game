"""
Ironclad Uncommon Skill card - Second Wind
"""
from engine.runtime_api import add_action, add_actions

from typing import List
from actions.base import Action
from actions.combat import GainBlockAction, HealAction
from actions.card import DrawCardsAction, ExhaustCardAction
from cards.base import Card
from entities.creature import Creature
from utils.dynamic_values import get_magic_value
from utils.registry import register
from utils.types import CardType, RarityType


@register("card")
class SecondWind(Card):
    """Exhaust all non-attack cards in hand, gain 5/7 block for each exhausted"""

    card_type = CardType.SKILL
    rarity = RarityType.UNCOMMON

    base_cost = 1
    
    base_magic = {"block_for_exhaust": 5}
    upgrade_magic = {"block_for_exhaust": 7}

    def on_play(self, targets: List[Creature] = []):
        target = targets[0] if targets else None
        from engine.game_state import game_state
        player = game_state.player

        block = get_magic_value(self, "block_for_exhaust")

        super().on_play(targets)

        actions = []
        # Exhaust all cards in hand and gain block for each
        hand = game_state.player.card_manager.get_pile('hand')
        for card in hand:
            if card.card_type != CardType.ATTACK:
                actions.append(ExhaustCardAction(card=card, source_pile="hand"))
                actions.append(GainBlockAction(block=block, target=player, source=player, card=card))

        from engine.game_state import game_state

        add_actions(actions)

        return