"""Tests for gold reward calculation in combat rooms.

This test file verifies that gold rewards are calculated correctly
for different room types (normal, elite, boss).
"""

import unittest
import random
from unittest.mock import patch, MagicMock

from rooms.combat import CombatRoom
from utils.types import RoomType


class TestGoldRewardCalculation(unittest.TestCase):
    """Test cases for gold reward calculation in combat rooms."""

    def setUp(self):
        """Set up test fixtures."""
        self.room = CombatRoom()

    def test_normal_room_gold_range(self):
        """Test that normal combat rooms give 10-20 gold."""
        self.room.room_type = RoomType.NORMAL
        gold_values = []
        for _ in range(100):
            gold = self.room._calculate_gold_reward()
            gold_values.append(gold)
        
        # All values should be in range
        for gold in gold_values:
            self.assertGreaterEqual(gold, 10)
            self.assertLessEqual(gold, 20)
        
        # Should have some variance (not all same value)
        self.assertGreater(len(set(gold_values)), 1)

    def test_elite_room_gold_range(self):
        """Test that elite combat rooms give 25-35 gold."""
        self.room.room_type = RoomType.ELITE
        gold_values = []
        for _ in range(100):
            gold = self.room._calculate_gold_reward()
            gold_values.append(gold)
        
        # All values should be in range
        for gold in gold_values:
            self.assertGreaterEqual(gold, 25)
            self.assertLessEqual(gold, 35)
        
        # Should have some variance (not all same value)
        self.assertGreater(len(set(gold_values)), 1)

    def test_boss_room_gold_range(self):
        """Test that boss combat rooms give 95-105 gold."""
        self.room.room_type = RoomType.BOSS
        gold_values = []
        for _ in range(100):
            gold = self.room._calculate_gold_reward()
            gold_values.append(gold)
        
        # All values should be in range
        for gold in gold_values:
            self.assertGreaterEqual(gold, 95)
            self.assertLessEqual(gold, 105)
        
        # Should have some variance (not all same value)
        self.assertGreater(len(set(gold_values)), 1)

    def test_gold_reward_is_integer(self):
        """Test that gold reward is always an integer."""
        for room_type in [RoomType.NORMAL, RoomType.ELITE, RoomType.BOSS]:
            self.room.room_type = room_type
            for _ in range(10):
                gold = self.room._calculate_gold_reward()
                self.assertIsInstance(gold, int)

    def test_different_room_types_give_different_gold(self):
        """Test that different room types give different gold amounts on average."""
        # Collect gold samples for each room type
        normal_gold = []
        elite_gold = []
        boss_gold = []
        
        self.room.room_type = RoomType.NORMAL
        for _ in range(100):
            normal_gold.append(self.room._calculate_gold_reward())
        
        self.room.room_type = RoomType.ELITE
        for _ in range(100):
            elite_gold.append(self.room._calculate_gold_reward())
        
        self.room.room_type = RoomType.BOSS
        for _ in range(100):
            boss_gold.append(self.room._calculate_gold_reward())
        
        # Boss should give more than elite on average
        self.assertGreater(sum(boss_gold) / len(boss_gold),
                          sum(elite_gold) / len(elite_gold))
        
        # Elite should give more than normal on average
        self.assertGreater(sum(elite_gold) / len(elite_gold),
                          sum(normal_gold) / len(normal_gold))


if __name__ == "__main__":
    unittest.main()
