"""
Test for Tiny Chest relic functionality.
"""
import pytest
from unittest.mock import patch, MagicMock
from utils.types import RoomType


class TestTinyChestRelic:
    """Test Tiny Chest relic."""

    @patch('map.map_manager.MapManager._player_has_relic')
    def test_tiny_chest_forces_treasure_every_4th_room(self, mock_has_relic):
        """Test that Tiny Chest forces Treasure room every 4th ? room."""
        # Mock that player has Tiny Chest relic
        mock_has_relic.side_effect = lambda relic_name: relic_name in ["tiny_chest", "tinychest"]

        from map.map_manager import MapManager

        # Create map manager with player having Tiny Chest
        map_manager = MapManager(seed=42, act_id=1)

        # Track what types we get for unknown rooms
        results = []
        for i in range(10):
            room_type = map_manager._resolve_unknown_type(floor=5)
            results.append(room_type)

        # Verify every 4th room (indices 3, 7) is Treasure
        for i, room_type in enumerate(results):
            if (i + 1) % 4 == 0:
                assert room_type == RoomType.TREASURE, f"Visit {i+1} should be Treasure but got {room_type.value}"

    @patch('map.map_manager.MapManager._player_has_relic')
    def test_tiny_chest_resets_treasure_counter(self, mock_has_relic):
        """Test that Tiny Chest resets the treasure visit counter."""
        # Mock that player has Tiny Chest relic
        mock_has_relic.side_effect = lambda relic_name: relic_name in ["tiny_chest", "tinychest"]

        from map.map_manager import MapManager

        # Create map manager with player having Tiny Chest
        map_manager = MapManager(seed=42, act_id=1)

        # Get treasure counter before any visits
        initial_counter = map_manager.unknown_room_visits[RoomType.TREASURE]
        assert initial_counter == 0, "Initial treasure counter should be 0"

        # Visit unknown rooms 3 times (not forcing treasure yet)
        for i in range(3):
            map_manager._resolve_unknown_type(floor=5)

        # Treasure counter should have been incremented 3 times
        assert map_manager.unknown_room_visits[RoomType.TREASURE] == 3, "Treasure counter should be 3 after 3 non-treasure visits"

        # 4th visit should force treasure and reset counter
        room_type = map_manager._resolve_unknown_type(floor=5)
        assert room_type == RoomType.TREASURE, "4th visit should force Treasure"
        assert map_manager.unknown_room_visits[RoomType.TREASURE] == 0, "Treasure counter should be reset to 0 after forcing treasure"

    @patch('map.map_manager.MapManager._player_has_relic')
    def test_no_tiny_chest_normal_behavior(self, mock_has_relic):
        """Test normal behavior when player doesn't have Tiny Chest."""
        # Mock that player doesn't have Tiny Chest relic
        mock_has_relic.return_value = False

        from map.map_manager import MapManager

        # Create map manager without Tiny Chest
        map_manager = MapManager(seed=42, act_id=1)

        # Track what types we get for unknown rooms
        results = []
        for i in range(20):
            room_type = map_manager._resolve_unknown_type(floor=5)
            results.append(room_type)

        # Without Tiny Chest, we shouldn't get Treasure at regular intervals
        treasure_count = sum(1 for r in results if r == RoomType.TREASURE)
        print(f"Treasure rooms: {treasure_count}/20 (random, not forced)")

        # Should have some random treasure rooms due to bad luck protection
        # but not at fixed intervals
        assert 0 <= treasure_count <= 5, f"Expected 0-5 treasure rooms, got {treasure_count}"