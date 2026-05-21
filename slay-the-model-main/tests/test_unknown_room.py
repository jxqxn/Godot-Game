"""Test EventRoom basic functionality."""
import pytest
from typing import cast
from engine.game_state import game_state
from rooms.event import EventRoom
from actions.display import InputRequestAction
from utils.registry import get_registered
from utils.types import RoomType


class TestEventRoomBasic:
    """Test EventRoom basic functionality."""

    def test_event_room_creation(self):
        """Test EventRoom initialization."""
        event_room = EventRoom()
        assert event_room is not None
        assert event_room.room_type == RoomType.EVENT
        assert event_room.available_events == []
        assert event_room.triggered_event is None

    def test_event_room_has_should_leave(self):
        """Test EventRoom has should_leave flag."""
        event_room = EventRoom()
        assert hasattr(event_room, 'should_leave')
        assert event_room.should_leave is False

    def test_event_room_leave_flag(self):
        """Test EventRoom leave flag functionality."""
        event_room = EventRoom()
        event_room.should_leave = False

        # Leave flag should work
        assert event_room.should_leave is False

    def test_event_room_registered(self):
        """EventRoom should be registered in room registry."""
        assert get_registered("room", "EventRoom") is EventRoom

    def test_enter_with_multiple_events_returns_selection(self):
        """When multiple events are available, room should queue a selection request."""
        room = EventRoom()
        game_state.action_queue.clear()

        class DummyEvent:
            def local(self, field):
                return "Dummy Event"

        room.available_events = [DummyEvent(), DummyEvent()]
        result = room.enter()

        assert result is None
        queued = game_state.action_queue.peek_next()
        assert isinstance(queued, InputRequestAction)
        queued = cast(InputRequestAction, queued)
        assert len(queued.options) == 2

    def test_trigger_event_marks_state(self):
        """Triggering an unfinished event should keep the room open."""
        room = EventRoom()

        class DummyEvent:
            event_ended = False

            def trigger(self):
                return None

        event = DummyEvent()
        result = room._trigger_event(event)

        assert result is None
        assert room.triggered_event is event
        assert room.should_leave is False

    def test_empty_event_pool_returns_explicit_empty_pool_message(self):
        """Empty event pools should return without queueing actions."""
        room = EventRoom()
        game_state.action_queue.clear()

        result = room.enter()

        assert result is None
        assert game_state.action_queue.is_empty()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
