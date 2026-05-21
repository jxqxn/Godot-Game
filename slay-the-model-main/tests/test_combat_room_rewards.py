"""Tests for combat room reward behavior."""

import unittest
from unittest.mock import Mock

from actions.card import ChooseAddRandomCardAction, ChooseObtainCardAction
from actions.reward import AddGoldAction, AddRandomPotionAction
from engine.game_state import game_state
from rooms.combat import CombatRoom
from utils.types import CombatType, RoomType


class TestCombatRoomRewards(unittest.TestCase):
    """Test reward rules for combat room victory."""

    def setUp(self):
        game_state._initialized = False
        game_state.__init__()
        game_state.player = Mock()
        game_state.player.relics = []

    def test_act3_boss_victory_has_no_reward_actions(self):
        """Act 3 boss victory should not generate combat rewards."""
        game_state.current_act = 3
        room = CombatRoom(enemies=[], room_type=RoomType.BOSS)

        actions = room._handle_victory()

        self.assertTrue(actions)
        self.assertFalse(any(isinstance(a, AddGoldAction) for a in actions))
        self.assertFalse(any(isinstance(a, ChooseAddRandomCardAction)
                             for a in actions))
        self.assertFalse(any(isinstance(a, AddRandomPotionAction)
                             for a in actions))

    def test_act4_boss_victory_has_no_reward_actions(self):
        """Act 4 boss victory should not generate combat rewards."""
        game_state.current_act = 4
        room = CombatRoom(enemies=[], room_type=RoomType.BOSS)

        actions = room._handle_victory()

        self.assertTrue(actions)
        self.assertFalse(any(isinstance(a, AddGoldAction) for a in actions))
        self.assertFalse(any(isinstance(a, ChooseAddRandomCardAction)
                             for a in actions))
        self.assertFalse(any(isinstance(a, AddRandomPotionAction)
                             for a in actions))

    def test_normal_combat_card_reward_can_skip(self):
        """Normal combat rewards should expose an explicit skip option."""
        game_state.current_act = 1
        game_state.player.namespace = "ironclad"
        room = CombatRoom(enemies=[], room_type=RoomType.MONSTER)
        room.combat = Mock(combat_type=CombatType.NORMAL)

        actions = room._handle_victory()

        card_rewards = [a for a in actions if isinstance(a, ChooseObtainCardAction)]
        self.assertEqual(len(card_rewards), 1)
        self.assertTrue(card_rewards[0].can_skip)


if __name__ == "__main__":
    unittest.main()
