#!/usr/bin/env python
"""Tests for orb action system."""

import unittest
from unittest.mock import Mock
from typing import Any, cast

from engine.game_state import game_state
from orbs.dark import DarkOrb
from orbs.frost import FrostOrb
from orbs.lightning import LightningOrb


class TestOrbActions(unittest.TestCase):
    """Test orb action system."""

    def setUp(self):
        """Set up test fixtures."""
        # Reset game state
        game_state._initialized = False
        game_state.__init__()
        # Set up player with get_power returning None (no Focus power)
        cast(Any, game_state).player = Mock()
        player = cast(Any, game_state).player
        player.orb_slots = []
        player.get_power = Mock(return_value=None)
        # Set up combat state
        cast(Any, game_state).combat_state = Mock()
        cast(Any, game_state).combat_state.enemies = []

    def test_dark_orb_creation(self):
        """Test that DarkOrb can be created."""
        orb = DarkOrb()
        self.assertIsInstance(orb, DarkOrb)

    def test_frost_orb_creation(self):
        """Test that FrostOrb can be created."""
        orb = FrostOrb()
        self.assertIsInstance(orb, FrostOrb)

    def test_lightning_orb_creation(self):
        """Test that LightningOrb can be created."""
        orb = LightningOrb()
        self.assertIsInstance(orb, LightningOrb)

    def test_dark_orb_on_passive(self):
        """Test DarkOrb on_passive queues actions directly."""
        orb = DarkOrb()
        result = orb.on_passive()
        self.assertIsNone(result)

    def test_frost_orb_on_passive(self):
        """Test FrostOrb on_passive queues actions directly."""
        orb = FrostOrb()
        result = orb.on_passive()
        self.assertIsNone(result)

    def test_orb_has_evoke_method(self):
        """Test that orbs have evoke method."""
        orb = DarkOrb()
        self.assertTrue(hasattr(orb, 'on_evoke'))

    def test_orb_has_passive_method(self):
        """Test that orbs have passive method."""
        orb = DarkOrb()
        self.assertTrue(hasattr(orb, 'on_passive'))

    def test_orb_has_charge_attribute(self):
        """Test that orbs have charge attribute."""
        orb = DarkOrb()
        self.assertTrue(hasattr(orb, 'charge'))


if __name__ == '__main__':
    unittest.main()
