"""
Unit tests for events implementation.

Note: Due to circular import between engine.game_state and rooms.neo,
these tests import event modules directly using __import__ to bypass events.__init__.py
"""

import unittest
from unittest.mock import Mock, patch
import sys
import importlib.util
import os

# Import event_pool module directly using __import__ to bypass events.__init__.py
spec = importlib.util.spec_from_file_location(
    "event_pool",
    os.path.join(os.path.dirname(__file__), "..", "events", "event_pool.py")
)
assert spec is not None
assert spec.loader is not None
event_pool_module = importlib.util.module_from_spec(spec)
sys.modules['events.event_pool'] = event_pool_module
spec.loader.exec_module(event_pool_module)
event_pool = event_pool_module.event_pool

# Import event files directly using __import__ to bypass events.__init__.py
# This ensures @register_event decorators are called
event_files = ['big_fish', 'the_cleric', 'woman_in_blue']
for event_file in event_files:
    spec = importlib.util.spec_from_file_location(
        f"events.{event_file}",
        os.path.join(os.path.dirname(__file__), "..", "events", f"{event_file}.py")
    )
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[f'events.{event_file}'] = module
    spec.loader.exec_module(module)


class TestEventRegistration(unittest.TestCase):
    """Test that all events are properly registered"""

    def test_all_events_registered(self):
        """Test that all 3 events are registered in event pool"""
        all_event_ids = ['big_fish', 'the_cleric', 'woman_in_blue']

        for event_id in all_event_ids:
            event_class = event_pool.get_event_by_id(event_id)
            self.assertIsNotNone(event_class,
                             f"Event {event_id} should be registered")

    def test_event1_registered(self):
        """Test that BigFishEvent is registered"""
        event_class = event_pool.get_event_by_id('big_fish')
        self.assertIsNotNone(event_class, "BigFishEvent should be registered")
        self.assertEqual(event_class.__name__, 'BigFishEvent')

    def test_event2_registered(self):
        """Test that TheClericEvent is registered"""
        event_class = event_pool.get_event_by_id('the_cleric')
        self.assertIsNotNone(event_class, "TheClericEvent should be registered")
        self.assertEqual(event_class.__name__, 'TheClericEvent')

    def test_event3_registered(self):
        """Test that WomanInBlueEvent is registered"""
        event_class = event_pool.get_event_by_id('woman_in_blue')
        self.assertIsNotNone(event_class, "WomanInBlueEvent should be registered")
        self.assertEqual(event_class.__name__, 'WomanInBlueEvent')


class TestEventTriggers(unittest.TestCase):
    """Test event trigger methods"""

    def test_big_fish_trigger(self):
        """Test BigFishEvent can be instantiated"""
        from events.big_fish import BigFishEvent
        event = BigFishEvent()
        self.assertIsNotNone(event)
        self.assertFalse(event.event_ended)

    def test_the_cleric_trigger(self):
        """Test TheClericEvent can be instantiated"""
        from events.the_cleric import TheClericEvent
        event = TheClericEvent()
        self.assertIsNotNone(event)
        self.assertFalse(event.event_ended)

    def test_woman_in_blue_trigger(self):
        """Test WomanInBlueEvent can be instantiated"""
        from events.woman_in_blue import WomanInBlueEvent
        event = WomanInBlueEvent()
        self.assertIsNotNone(event)
        self.assertFalse(event.event_ended)


if __name__ == '__main__':
    unittest.main()
