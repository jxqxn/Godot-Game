from engine.messages import PlayerTurnEndedMessage, PlayerTurnStartedMessage
from engine.subscriptions import MessagePriority, subscribe
from localization import Localizable
from utils.types import TargetType

class Orb(Localizable):
    localization_prefix = "orbs"
    passive_timing = "turn_end"
    target_type = TargetType.SELF
    
    def __init__(self):
        pass

    def on_passive(self) -> None:
        """Queue this orb's passive effect directly."""
        raise NotImplementedError

    def on_evoke(self) -> None:
        """Queue this orb's evoke effect directly."""
        raise NotImplementedError

    @subscribe(PlayerTurnStartedMessage, priority=MessagePriority.REACTION)
    def on_turn_start(self) -> None:
        if self.passive_timing == "turn_start":
            self.on_passive()

    @subscribe(PlayerTurnEndedMessage, priority=MessagePriority.REACTION)
    def on_turn_end(self) -> None:
        if self.passive_timing == "turn_end":
            self.on_passive()
