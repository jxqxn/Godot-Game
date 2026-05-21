#!/usr/bin/env python
"""Tests for enemy intention system."""

import unittest
from unittest.mock import Mock, patch

from engine.game_state import game_state
from enemies.act1.cultist import Cultist
from enemies.act1.jaw_worm import JawWorm
from enemies.act1.louse import RedLouse
from enemies.act1.lagavulin import Lagavulin
from enemies.act1.spike_slime import SpikeSlimeL, SpikeSlimeM


class TestEnemyIntentions(unittest.TestCase):
    """Test enemy intention system."""

    def setUp(self):
        """Set up test fixtures."""
        # Reset game state
        game_state._initialized = False
        game_state.__init__()
        game_state.player = Mock()

    def test_cultist_has_intentions(self):
        """Test that Cultist has intentions defined."""
        cultist = Cultist()
        self.assertIsNotNone(cultist.intentions)
        self.assertIn('ritual', cultist.intentions)

    def test_cultist_intention_on_combat_start(self):
        """Test Cultist intention after combat start."""
        cultist = Cultist()
        cultist.on_combat_start(floor=1)
        self.assertIsNotNone(cultist.current_intention)

    def test_jaw_worm_has_intentions(self):
        """Test that JawWorm has intentions defined."""
        worm = JawWorm()
        self.assertIsNotNone(worm.intentions)

    def test_jaw_worm_intention_on_combat_start(self):
        """Test JawWorm intention after combat start."""
        worm = JawWorm()
        worm.on_combat_start(floor=1)
        self.assertIsNotNone(worm.current_intention)

    def test_red_louse_has_intentions(self):
        """Test that RedLouse has intentions defined."""
        louse = RedLouse()
        self.assertIsNotNone(louse.intentions)

    def test_red_louse_intention_on_combat_start(self):
        """Test RedLouse intention after combat start."""
        louse = RedLouse()
        louse.on_combat_start(floor=1)
        self.assertIsNotNone(louse.current_intention)

    def test_lagavulin_has_intentions(self):
        """Test that Lagavulin has intentions defined."""
        enemy = Lagavulin()
        self.assertIsNotNone(enemy.intentions)

    def test_spike_slime_l_has_intentions(self):
        """Test that SpikeSlimeL has intentions defined."""
        slime = SpikeSlimeL()
        self.assertIsNotNone(slime.intentions)

    def test_spike_slime_l_intention_on_combat_start(self):
        """Test SpikeSlimeL intention after combat start."""
        slime = SpikeSlimeL()
        slime.on_combat_start(floor=1)
        self.assertIsNotNone(slime.current_intention)

    def test_spike_slime_m_has_intentions(self):
        """Test that SpikeSlimeM has intentions defined."""
        slime = SpikeSlimeM()
        self.assertIsNotNone(slime.intentions)

    def test_spike_slime_m_intention_on_combat_start(self):
        """Test SpikeSlimeM intention after combat start."""
        slime = SpikeSlimeM()
        slime.on_combat_start(floor=1)
        self.assertIsNotNone(slime.current_intention)

    def test_enemy_can_execute_intention(self):
        """Test that enemy can execute current intention."""
        cultist = Cultist()
        cultist.on_combat_start(floor=1)
        # Execute intention should not raise
        cultist.execute_intention()


if __name__ == '__main__':
    unittest.main()
