#!/usr/bin/env python
"""Tests for LimitBreak card."""

import unittest

from cards.ironclad.limit_break import LimitBreak


class TestLimitBreak(unittest.TestCase):
    """Test LimitBreak card functionality."""

    def test_limit_break_creation(self):
        """Test LimitBreak card can be created."""
        card = LimitBreak()
        self.assertIsInstance(card, LimitBreak)

    def test_limit_break_has_cost(self):
        """Test LimitBreak card has correct cost."""
        card = LimitBreak()
        self.assertEqual(card.cost, 1)

    def test_limit_break_plus_has_cost(self):
        """Test LimitBreak+ card has correct cost."""
        card = LimitBreak(upgraded=True)
        self.assertEqual(card.cost, 1)

    def test_limit_break_is_attack(self):
        """Test LimitBreak is a skill card."""
        card = LimitBreak()
        from utils.types import CardType
        self.assertEqual(card.card_type, CardType.SKILL)

    def test_limit_break_exhausts(self):
        """Test LimitBreak exhausts when played."""
        card = LimitBreak()
        self.assertTrue(card.exhaust)


if __name__ == "__main__":
    unittest.main()
