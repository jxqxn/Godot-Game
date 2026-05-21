"""
Event pool system for managing available events.

This module provides a centralized registry and management system
for all game events, allowing EventRooms to select events
based on configurable rules and weights.

Events are categorized by Act (1, 2, 3) or as 'shared' (appears in all Acts 1-3).
Multi-Act events can appear in multiple specific Acts (e.g., [1, 2] for Acts 1-2).
"""
import random
from typing import Dict, List, Optional, Type, Callable, Any, Union


class EventMetadata:
    """
    Metadata for an event in the pool.
    """
    
    def __init__(
        self,
        event_class: Type,
        event_id: str,
        acts: Union[str, List[int]] = 'shared',
        weight: int = 100,
        requires_condition: Optional[Callable[[], bool]] = None,
        is_unique: bool = False
    ):
        self.event_class = event_class
        self.event_id = event_id
        self.acts = acts  # 'shared', [1], [2], [3], [1, 2], [2, 3], etc.
        self.weight = weight
        self.requires_condition = requires_condition
        self.is_unique = is_unique
        self.has_been_used = False


class EventPool:
    """
    Centralized event pool manager.
    
    Manages available events and provides methods to select events
    based on game state, Act, and other criteria.
    """
    
    def __init__(self):
        # Event registry: maps event class names to their metadata
        self._event_registry: Dict[str, EventMetadata] = {}
        
        # Event pools organized by Act
        # 'shared' events appear in all Acts 1-3
        self._act_pools: Dict[Union[int, str], List[str]] = {
            1: [],         # Act 1 exclusive events
            2: [],         # Act 2 exclusive events
            3: [],         # Act 3 exclusive events
            'shared': []   # Common events (appear in all Acts 1-3)
        }
    
    def register_event(
        self,
        event_class: Type,
        event_id: str,
        acts: Union[str, List[int]] = 'shared',
        weight: int = 100,
        requires_condition: Optional[Callable[[], bool]] = None,
        is_unique: bool = False
    ):
        """
        Register an event to the pool.
        
        Args:
            event_class: The Event class to register
            event_id: Unique identifier for the event
            acts: When this event can appear:
                - 'shared': Appears in all Acts 1-3
                - [1]: Act 1 only
                - [2]: Act 2 only
                - [3]: Act 3 only
                - [1, 2]: Acts 1 and 2 only
                - [2, 3]: Acts 2 and 3 only
            weight: Selection weight (higher = more likely to be chosen)
            requires_condition: Optional function that returns True if event can appear
            is_unique: Whether this event can only appear once per run
        """
        metadata = EventMetadata(
            event_class=event_class,
            event_id=event_id,
            acts=acts,
            weight=weight,
            requires_condition=requires_condition,
            is_unique=is_unique
        )
        
        self._event_registry[event_id] = metadata
        
        # Add to appropriate Act pools
        self._add_to_act_pools(event_id, acts)
    
    def _add_to_act_pools(self, event_id: str, acts: Union[str, List[int]]):
        """
        Add an event to the appropriate Act pools.
        
        Args:
            event_id: Event identifier
            acts: Act specification
        """
        if acts == 'shared':
            # Shared events go to 'shared' pool (included in all Acts 1-3)
            self._act_pools['shared'].append(event_id)
        elif isinstance(acts, list):
            # Multi-Act events: add to each specified Act pool
            for act in acts:
                if act in self._act_pools:
                    self._act_pools[act].append(event_id)
        elif isinstance(acts, int) and acts in self._act_pools:
            # Single Act as int
            self._act_pools[acts].append(event_id)
    
    def get_available_events(self, act: int = 1) -> List[EventMetadata]:
        """
        Get all available events for the current Act.
        
        Args:
            act: Current Act number (1-3)
            
        Returns:
            List of available event metadata
        """
        if act < 1 or act > 3:
            act = 1  # Default to Act 1 if out of range
        
        # Get events for this Act (exclusive + shared + multi-Act that include this act)
        event_ids = set()
        
        # Add Act-exclusive events
        event_ids.update(self._act_pools.get(act, []))
        
        # Add shared events (common to all Acts)
        event_ids.update(self._act_pools.get('shared', []))
        
        # Filter by conditions
        available = []
        for event_id in event_ids:
            metadata = self._event_registry.get(event_id)
            if metadata and self._is_event_available(metadata):
                available.append(metadata)
        
        return available
    
    def get_random_event(self, act: int = 1) -> Optional[Type]:
        """
        Get a random event weighted by their weights.
        
        Args:
            act: Current Act number (1-3)
            
        Returns:
            Event class or None if no events available
        """
        available = self.get_available_events(act)
        
        if not available:
            return None
        
        # Weighted random selection
        events = []
        weights = []
        
        selected_metadata = None
        for metadata in available:
            events.append(metadata.event_class)
            weights.append(metadata.weight)

        selected_event = random.choices(events, weights=weights, k=1)[0]
        for metadata in available:
            if metadata.event_class is selected_event:
                selected_metadata = metadata
                break
        if selected_metadata is not None:
            self.mark_event_used(selected_metadata.event_id)
        return selected_event
    
    def get_event_by_id(self, event_id: str) -> Optional[Type]:
        """
        Get an event class by its ID.
        
        Args:
            event_id: Event identifier
            
        Returns:
            Event class or None if not found
        """
        metadata = self._event_registry.get(event_id)
        return metadata.event_class if metadata else None
    
    def mark_event_used(self, event_id: str):
        """
        Mark a unique event as used.
        
        Args:
            event_id: Event identifier
        """
        if event_id in self._event_registry:
            self._event_registry[event_id].has_been_used = True
    
    def _is_event_available(self, metadata: 'EventMetadata') -> bool:
        """
        Check if an event is currently available.
        
        Args:
            metadata: Event metadata
            
        Returns:
            True if event can appear
        """
        # Check if unique event was already used
        if metadata.has_been_used:
            return False

        can_appear = getattr(metadata.event_class, "can_appear", None)
        if callable(can_appear):
            try:
                if not can_appear():
                    return False
            except Exception:
                return False
        
        # Check custom condition
        if metadata.requires_condition:
            try:
                return metadata.requires_condition()
            except Exception:
                return False
        
        return True
    
    def reset_unique_events(self):
        """Reset all unique events for a new run"""
        for metadata in self._event_registry.values():
            metadata.has_been_used = False
    
    def get_events_by_act(self, act: int) -> List[str]:
        """
        Get list of event IDs available for a specific Act.
        
        Args:
            act: Act number (1-3)
            
        Returns:
            List of event IDs
        """
        event_ids = set()
        event_ids.update(self._act_pools.get(act, []))
        event_ids.update(self._act_pools.get('shared', []))
        return list(event_ids)
    
    def get_all_registered_events(self) -> Dict[str, EventMetadata]:
        """
        Get all registered events.
        
        Returns:
            Dictionary of event_id to EventMetadata
        """
        return self._event_registry.copy()


# Global event pool instance
event_pool = EventPool()


# Decorator for registering events
def register_event(
    event_id: str,
    acts: Union[str, List[int]] = 'shared',
    weight: int = 100,
    requires_condition: Optional[Callable[[], bool]] = None,
    is_unique: bool = False
):
    """
    Decorator to register an event to the global pool.
    
    Args:
        event_id: Unique identifier for the event
        acts: When this event can appear:
            - 'shared': Appears in all Acts 1-3
            - [1]: Act 1 only
            - [2]: Act 2 only
            - [3]: Act 3 only
            - [1, 2]: Acts 1 and 2 only
            - [2, 3]: Acts 2 and 3 only
        weight: Selection weight (higher = more likely)
        requires_condition: Optional function that returns True if event can appear
        is_unique: Whether this event can only appear once per run
    
    Usage:
        @register_event(
            event_id="big_fish",
            acts=[1],
            weight=100
        )
        class BigFishEvent(Event):
            def trigger(self) -> str:
                ...
        
        @register_event(
            event_id="woman_in_blue",
            acts='shared',
            weight=100
        )
        class WomanInBlueEvent(Event):
            def trigger(self) -> str:
                ...
        
        @register_event(
            event_id="face_trader",
            acts=[1, 2],
            weight=100
        )
        class FaceTraderEvent(Event):
            def trigger(self) -> str:
                ...
    """
    def decorator(event_class: Type) -> Type:
        event_pool.register_event(
            event_class=event_class,
            event_id=event_id,
            acts=acts,
            weight=weight,
            requires_condition=requires_condition,
            is_unique=is_unique
        )
        return event_class
    return decorator
