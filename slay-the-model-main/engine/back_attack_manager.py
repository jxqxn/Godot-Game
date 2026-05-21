"""
Back Attack Manager for Act 4 Spire Shield + Spire Spear elite fight.

Manages dynamic BackAttackPower transfer between Shield and Spear.
"""
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from enemies.base import Enemy


class BackAttackManager:
    """Manages BackAttackPower transfer between Spire Shield and Spear.
    
    Rules:
    - Only ONE enemy holds BackAttackPower at a time (starts with Shield)
    - When player targets Shield with card/potion, transfer to Spear
    - When either enemy dies, remove BackAttackPower from survivor and
      Surrounded from player
    """
    
    _instance: Optional["BackAttackManager"] = None
    _shield: Optional["Enemy"]
    _spear: Optional["Enemy"]
    _current_holder: Optional[str]
    
    def __new__(cls):
        if cls._instance is None:
            instance = super().__new__(cls)
            instance._shield = None
            instance._spear = None
            instance._current_holder = None  # "shield" or "spear"
            cls._instance = instance
        return cls._instance
    
    def __init__(self):
        # Instance variables initialized in __new__, this satisfies type checkers
        self._shield: Optional["Enemy"] = getattr(self, "_shield", None)
        self._spear: Optional["Enemy"] = getattr(self, "_spear", None)
        self._current_holder: Optional[str] = getattr(self, "_current_holder", None)
    
    def reset(self):
        """Reset manager state (for new combat)."""
        self._shield = None
        self._spear = None
        self._current_holder = None
    
    def initialize(self, shield: "Enemy", spear: "Enemy") -> None:
        """Initialize with Shield and Spear enemies.
        
        Args:
            shield: SpireShield enemy instance
            spear: SpireSpear enemy instance
        """
        from powers.definitions.back_attack import BackAttackPower
        
        self._shield = shield
        self._spear = spear
        self._current_holder = "shield"
        
        # Grant BackAttack to Shield initially
        shield.add_power(BackAttackPower(owner=shield))
    
    def transfer_to_spear(self) -> bool:
        """Transfer BackAttack from Shield to Spear.
        
        Returns:
            True if transfer happened, False if not applicable
        """
        if self._current_holder != "shield":
            return False
        
        from powers.definitions.back_attack import BackAttackPower
        
        # Remove from Shield
        if self._shield and getattr(self._shield, "is_alive", False):
            self._shield.remove_power("Back Attack")
        
        # Add to Spear
        if self._spear and getattr(self._spear, "is_alive", False):
            self._spear.add_power(BackAttackPower(owner=self._spear))
        
        self._current_holder = "spear"
        return True
    
    def transfer_to_shield(self) -> bool:
        """Transfer BackAttack from Spear to Shield.
        
        Returns:
            True if transfer happened, False if not applicable
        """
        if self._current_holder != "spear":
            return False
        
        from powers.definitions.back_attack import BackAttackPower
        
        # Remove from Spear
        if self._spear and getattr(self._spear, "is_alive", False):
            self._spear.remove_power("Back Attack")
        
        # Add to Shield
        if self._shield and getattr(self._shield, "is_alive", False):
            self._shield.add_power(BackAttackPower(owner=self._shield))
        
        self._current_holder = "shield"
        return True
    
    def maybe_transfer_on_target(self, target) -> bool:
        """Transfer BackAttack if target is the current holder.
        
        Used when player targets an enemy with card/potion.
        Transfers BackAttack to the OTHER enemy.
        
        Args:
            target: The enemy being targeted by player
            
        Returns:
            True if transfer happened, False otherwise
        """
        if target == self._shield and self._current_holder == "shield":
            return self.transfer_to_spear()
        elif target == self._spear and self._current_holder == "spear":
            return self.transfer_to_shield()
        return False
    
    def on_enemy_death(self, enemy: "Enemy") -> None:
        """Called when Shield or Spear dies.
        
        Removes BackAttack from survivor and Surrounded from player.
        
        Args:
            enemy: The enemy that just died
        """
        from engine.game_state import game_state
        
        # Remove BackAttack from surviving enemy if any
        if enemy == self._shield:
            if self._spear and getattr(self._spear, "is_alive", False):
                self._spear.remove_power("Back Attack")
        elif enemy == self._spear:
            if self._shield and getattr(self._shield, "is_alive", False):
                self._shield.remove_power("Back Attack")
        
        # Remove Surrounded from player
        player = getattr(game_state, "player", None)
        if player:
            player.remove_power("Surrounded")
        
        # Clear references
        self._shield = None
        self._spear = None
        self._current_holder = None
    
    def is_shield_targeted(self, target) -> bool:
        """Check if Shield is being targeted and should trigger transfer.
        
        Args:
            target: Target being attacked/used on
            
        Returns:
            True if Shield is targeted and holds BackAttack
        """
        return (
            target == self._shield 
            and self._current_holder == "shield"
        )
    
    @property
    def current_holder(self) -> Optional[str]:
        """Return current holder of BackAttackPower: "shield", "spear", or None."""
        return self._current_holder
    
    @property
    def shield(self) -> Optional["Enemy"]:
        return self._shield
    
    @property
    def spear(self) -> Optional["Enemy"]:
        return self._spear


# Singleton accessor
back_attack_manager = BackAttackManager()
