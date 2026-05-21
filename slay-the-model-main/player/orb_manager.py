"""Orb management for the player."""
from engine.runtime_api import add_action, add_actions

from typing import List, Optional
from orbs.base import Orb
from actions.base import Action

class OrbManager:
    """Manages orbs for the player."""

    MAX_ORB_SLOTS = 10

    def __init__(self, max_orb_slots: int = 1) -> None:
        self._orbs: List[Orb] = []
        self._max_orb_slots = max_orb_slots

    @property
    def orbs(self) -> List[Orb]:
        return self._orbs

    @property
    def max_orb_slots(self) -> int:
        return self._max_orb_slots

    @max_orb_slots.setter
    def max_orb_slots(self, value: int) -> None:
        value = min(self.MAX_ORB_SLOTS, max(0, int(value)))
        if value < self._max_orb_slots:
            self._orbs = self._orbs[:value]
        self._max_orb_slots = value

    def add_orb(self, orb: Orb):
        """Add an orb. If max slots exceeded, evoke leftmost orb first.
        
        Args:
            orb: Orb instance to add
            
        Returns:
            List[Action]: List of actions to execute (evoke actions if slot full)
        """
        if self._max_orb_slots <= 0:
            return
            
        if len(self._orbs) >= self._max_orb_slots:
            # Evoke leftmost orb first
            self.evoke_orb(index=0)
            
        self._orbs.append(orb)
        return

    def evoke_orb(self, index: int = 0, times: int = 1):
        """Evoke an orb from slot, calling its on_evoke method.

        Args:
            index (int): Orb index to evoke (defaults to 0, leftmost). Use -1 for rightmost.
            times (int): Number of times to evoke (default 1)

        Returns:
            List[Action]: List of actions from the orb's on_evoke method
        """
        if not self._orbs:
            return
            
        # Handle negative index (rightmost)
        if index < 0:
            index = len(self._orbs) + index
            
        if index < 0 or index >= len(self._orbs):
            return
            
        orb = self._orbs.pop(index)
        
        # Call orb's on_evoke method multiple times if specified
        for _ in range(times):
            try:
                orb_actions = orb.on_evoke()
                if orb_actions:
                    from engine.game_state import game_state
                    if isinstance(orb_actions, list):
                        add_actions(orb_actions)
                    else:
                        add_action(orb_actions)
            except NotImplementedError:
                pass
        return

    def remove_orb(self, index: int = 0) -> Optional[Orb]:
        """Remove an orb at specific index without evoking. Defaults to rightmost orb.
        
        Args:
            index (int): Orb index to remove. Use -1 for rightmost.
            
        Returns:
            Optional[Orb]: The removed orb, or None if invalid index
        """
        if not self._orbs:
            return None
            
        # Handle negative index (rightmost)
        if index < 0:
            index = len(self._orbs) + index
            
        if index < 0 or index >= len(self._orbs):
            return None
            
        return self._orbs.pop(index)

    def clear_all(self) -> None:
        """Remove all orbs without evoking."""
        self._orbs.clear()
        
    def evoke_all(self):
        """Evoke all orbs from slots, calling their on_evoke methods.

        Returns:
            List[Action]: List of actions from all orbs' on_evoke methods
        """
        if not self._orbs:
            return
            
        # Get all orbs before clearing
        orbs_to_evoke = list(self._orbs)
        self._orbs.clear()
        
        # Evoke each orb
        for orb in orbs_to_evoke:
            try:
                orb_actions = orb.on_evoke()
                if orb_actions:
                    from engine.game_state import game_state
                    if isinstance(orb_actions, list):
                        add_actions(orb_actions)
                    else:
                        add_action(orb_actions)
            except NotImplementedError:
                pass
        return

    def get_orb_count(self) -> int:
        """Get current number of orbs."""
        return len(self._orbs)

    def trigger_passives(self, timing: str):
        """Trigger passives for all orbs with matching timing.

        Args:
            timing (str): Timing to trigger ("turn_start", "turn_end", etc.)

        Returns:
            List[Action]: List of actions from orbs' on_passive methods
        """
        for orb in self._orbs:
            if getattr(orb, "passive_timing", None) == timing:
                try:
                    orb_actions = orb.on_passive()
                    if orb_actions:
                        from engine.game_state import game_state
                        if isinstance(orb_actions, list):
                            add_actions(orb_actions)
                        else:
                            add_action(orb_actions)
                except NotImplementedError:
                    pass
        return
