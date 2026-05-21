"""Hexaghost (Boss) specific intentions."""
from engine.runtime_api import add_action, add_actions

from typing import List, TYPE_CHECKING

from enemies.intention import Intention

if TYPE_CHECKING:
    from enemies.base import Enemy
    from actions.base import Action


class ActivateIntention(Intention):
    """Activate - Does nothing."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("activate", enemy)
    
    def execute(self) -> None:
        """Execute Activate: does nothing."""
class DividerIntention(Intention):
    """Divider - Deals (N+1)×6 damage where N = Player HP / 12."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("divider", enemy)
    
    def execute(self) -> None:
        """Execute Divider: damage based on player's HP."""
        from actions.combat import AttackAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        # Calculate damage based on player's HP
        player_hp = game_state.player.hp
        n = player_hp // 12
        damage = n + 1

        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
            for _ in range(6)
        ]
        )
    
    @property
    def description(self):
        """Custom description for Divider."""
        from engine.game_state import game_state

        if game_state and game_state.player:
            player_hp = game_state.player.hp
            n = player_hp // 12
            damage = n + 1
        else:
            damage = 6

        return self.local(
            "description",
            damage=damage,
            attack_times=6,
        )


class SearIntention(Intention):
    """Sear - Deals 6 damage and adds 1 Burn to discard (2 Burns on A19+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("sear", enemy)
        self.base_damage = 6
        self._burn_count = 1
    
    def execute(self) -> None:
        """Execute Sear: deals 6 damage and adds Burn cards."""
        from actions.combat import AttackAction
        from actions.card import AddCardAction
        from engine.game_state import game_state
        from utils.registry import get_registered
        
        if not game_state or not game_state.player:
            return
        actions = [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
        ]
        
        # Add Burn cards
        try:
            BurnCard = get_registered("card", "Burn")
            if BurnCard:
                for _ in range(self._burn_count):
                    burn = BurnCard()
                    # If Inferno has been used, upgrade the Burn card
                    if getattr(self.enemy, '_used_inferno', False):
                        if hasattr(burn, 'upgrade'):
                            burn.upgrade()
                    actions.append(AddCardAction(card=burn, dest_pile="discard_pile"))
        except Exception:
            raise ValueError("Cannot Get Burn Card!")
        
        from engine.game_state import game_state
        
        add_actions(actions)
        
class TackleIntention(Intention):
    """Tackle - Deals 5 damage 2 times (6×2 on A4+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("tackle", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 6 if ascension >= 4 else 5
        self._hits = 2
    
    def execute(self) -> None:
        """Execute Tackle: deals damage multiple times."""
        from actions.combat import AttackAction
        from engine.game_state import game_state
        
        if not game_state or not game_state.player:
            return
        from engine.game_state import game_state
        add_actions(
        [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
            for _ in range(self._hits)
        ]
        )


class InflameIntention(Intention):
    """Inflame - Gains 12 Block and 2 Strength (3 Strength on A19+)."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("inflame", enemy)
        self.base_block = 12
        self.base_strength_gain = 2
    
    def execute(self) -> None:
        """Execute Inflame: gains Block and Strength."""
        from actions.combat import GainBlockAction, ApplyPowerAction
        
        from engine.game_state import game_state
        add_actions(
        [
            GainBlockAction(
                block=self.base_block,
                target=self.enemy
            ),
            ApplyPowerAction(
                power="strength",
                target=self.enemy,
                amount=self.base_strength_gain,
                duration=-1
            )
        ]
        )


class InfernoIntention(Intention):
    """Inferno - Deals 2×6 damage (3×6 on A4+), adds 3 Burn+ to discard."""
    
    def __init__(self, enemy: 'Enemy'):
        super().__init__("inferno", enemy)
        from engine.game_state import game_state

        ascension = getattr(game_state, "ascension", 0)
        self.base_damage = 3 if ascension >= 4 else 2
        self._hits = 6
        self._burn_count = 3
    
    def execute(self) -> None:
        """Execute Inferno: deals damage and adds upgraded Burn cards."""
        from actions.combat import AttackAction
        from actions.card import AddCardAction
        from engine.game_state import game_state
        from utils.registry import get_registered
        
        if not game_state or not game_state.player:
            return
        actions = [
            AttackAction(
                damage=self.base_damage,
                target=game_state.player,
                source=self.enemy,
                damage_type="attack",
            )
            for _ in range(self._hits)
        ]
        
        # Add Burn+ cards
        try:
            BurnCard = get_registered("card", "Burn")
            if BurnCard:
                for _ in range(self._burn_count):
                    burn = BurnCard()
                    if hasattr(burn, 'upgrade'):
                        burn.upgrade()
                    actions.append(AddCardAction(card=burn, dest_pile="discard_pile"))
        except Exception:
            pass
        
        # Mark that Inferno has been used - subsequent Sear Burns will be upgraded
        self.enemy._used_inferno = True
        
        from engine.game_state import game_state
        
        add_actions(actions)
        
