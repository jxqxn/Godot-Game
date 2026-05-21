"""
Base event definitions for new architecture.
Events use global action queue - they represent random encounters in Unknown Rooms.
"""
from localization import Localizable


class Event(Localizable):
    """
    Base event class - represents a random event in Unknown Rooms.
    
    Events are triggered when entering an Unknown Room that resolves
    to an EVENT type. Events can provide rewards, trigger combat,
    or offer choices to the player.
    """
    
    def __init__(self, **kwargs):
        self.kwargs = kwargs
        
        # Control flag for ending event
        self.event_ended = False
    
    def trigger(self) -> None:
        """
        Trigger and execute the event.

        This method should implement the event's main logic,
        building and executing actions as needed.
        """
        raise NotImplementedError(f"{self.__class__.__name__} must implement trigger()")
    
    def end_event(self) -> None:
        """End the event and return to room flow"""
        self.event_ended = True
        try:
            from engine.game_state import game_state
            from rooms.event import EventRoom
        except Exception:
            return

        current_room = getattr(game_state, "current_room", None)
        if current_room is not None and isinstance(current_room, EventRoom) and getattr(current_room, "triggered_event", None) is self:
            current_room.should_leave = True
    
    def __str__(self):
        return f"{self.__class__.__name__}()"
