"""Tests for Life Suck dynamic heal implementation."""

import unittest
from unittest.mock import Mock, patch

from engine.game_state import game_state
from enemies.act2.shelled_parasite import ShelledParasite
from enemies.act2.shelled_parasite_intentions import LifeSuckIntention
from actions.combat import AttackAction, HealAction


class TestShelledParasiteLifeSuck(unittest.TestCase):
    """Test Life Suck intention and on_damage_dealt callback."""

    def setUp(self):
        """Set up test fixtures."""
        self.enemy = ShelledParasite()
        self.enemy.hp = 50
        self.enemy.max_hp = 80
        game_state.action_queue.clear()

    def test_life_suck_flag_initially_false(self):
        """pending_life_suck_heal should be False initially."""
        self.assertFalse(self.enemy.pending_life_suck_heal)

    def test_life_suck_sets_flag_and_queues_only_attack(self):
        """Life Suck should set flag and queue only AttackAction."""
        with patch('engine.game_state.game_state') as mock_game_state:
            mock_player = Mock()
            mock_player.hp = 100
            mock_game_state.player = mock_player
            
            intention = self.enemy.intentions['life_suck']
            intention.execute()
            
            # Should set flag
            self.assertTrue(self.enemy.pending_life_suck_heal)
            
            # Should queue only 1 action (AttackAction)
            mock_game_state.add_actions.assert_called_once()
            queued_actions = mock_game_state.add_actions.call_args.args[0]
            self.assertEqual(len(queued_actions), 1)
            self.assertIsInstance(queued_actions[0], AttackAction)
            self.assertEqual(queued_actions[0].damage, 10)
            self.assertEqual(queued_actions[0].source, self.enemy)
            self.assertEqual(queued_actions[0].target, mock_player)

    def test_on_damage_dealt_returns_heal_when_flag_set(self):
        """on_damage_dealt should return HealAction when flag is set and damage > 0."""
        self.enemy.pending_life_suck_heal = True
        
        mock_target = Mock()
        self.enemy.on_damage_dealt(damage=8, target=mock_target)
        
        # Should queue HealAction
        self.assertEqual(len(game_state.action_queue.queue), 1)
        self.assertIsInstance(game_state.action_queue.queue[0], HealAction)
        self.assertEqual(getattr(game_state.action_queue.queue[0], "amount", None), 8)
        self.assertEqual(getattr(game_state.action_queue.queue[0], "target", None), self.enemy)
        
        # Flag should be cleared
        self.assertFalse(self.enemy.pending_life_suck_heal)

    def test_on_damage_dealt_no_heal_when_flag_not_set(self):
        """on_damage_dealt should not heal when flag is False."""
        self.enemy.pending_life_suck_heal = False
        
        self.enemy.on_damage_dealt(damage=10)
        
        # Should queue nothing
        self.assertTrue(game_state.action_queue.is_empty())
        self.assertFalse(self.enemy.pending_life_suck_heal)

    def test_on_damage_dealt_no_heal_when_zero_damage(self):
        """on_damage_dealt should not heal when damage is 0 (all blocked)."""
        self.enemy.pending_life_suck_heal = True
        
        self.enemy.on_damage_dealt(damage=0)
        
        # Should queue nothing (no heal)
        self.assertTrue(game_state.action_queue.is_empty())
        # Flag should remain set (not consumed)
        self.assertTrue(self.enemy.pending_life_suck_heal)

    def test_on_damage_dealt_heals_for_partial_damage(self):
        """on_damage_dealt should heal only for damage that gets through block."""
        self.enemy.pending_life_suck_heal = True
        
        # Player has 7 block, so only 3 damage gets through
        self.enemy.on_damage_dealt(damage=3)
        
        # Should heal for 3 (unblocked), not 10 (base damage)
        self.assertEqual(len(game_state.action_queue.queue), 1)
        self.assertEqual(getattr(game_state.action_queue.queue[0], "amount", None), 3)
        self.assertFalse(self.enemy.pending_life_suck_heal)

    def test_full_life_suck_flow(self):
        """Test complete flow: intention sets flag -> attack -> callback heals."""
        with patch('engine.game_state.game_state') as mock_game_state:
            mock_player = Mock()
            mock_player.hp = 100
            mock_game_state.player = mock_player
            
            # Step 1: Execute intention
            intention = self.enemy.intentions['life_suck']
            intention.execute()
            
            # Verify flag set
            self.assertTrue(self.enemy.pending_life_suck_heal)
            
            # Step 2: Simulate damage dealing (10 damage, all gets through)
            mock_player.take_damage = Mock(return_value=10)
            actual_damage = mock_player.take_damage(10)
            
            # Step 3: Call on_damage_dealt callback
            self.enemy.on_damage_dealt(damage=actual_damage, target=mock_player)
            
            # Verify heal for full damage
            mock_game_state.add_actions.assert_called()
            queued_actions = mock_game_state.add_actions.call_args.args[0]
            self.assertEqual(len(queued_actions), 1)
            self.assertEqual(getattr(queued_actions[0], "amount", None), 10)
            self.assertFalse(self.enemy.pending_life_suck_heal)

    def test_flag_consumed_after_single_use(self):
        """Flag should be consumed after first use, not heal multiple times."""
        self.enemy.pending_life_suck_heal = True
        
        # First call should heal
        self.enemy.on_damage_dealt(damage=5)
        self.assertEqual(len(game_state.action_queue.queue), 1)
        self.assertEqual(getattr(game_state.action_queue.queue[0], "amount", None), 5)
        
        # Second call should not heal (flag cleared)
        game_state.action_queue.clear()
        self.enemy.on_damage_dealt(damage=5)
        self.assertTrue(game_state.action_queue.is_empty())


if __name__ == '__main__':
    unittest.main()
