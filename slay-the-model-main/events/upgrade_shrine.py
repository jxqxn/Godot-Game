"""Event: Upgrade Shrine - Shrine Event (All Acts)

A shrine that allows upgrading a card.
"""
from engine.runtime_api import add_action, add_actions, publish_message, request_input, set_terminal_state

from events.base_event import Event
from events.event_pool import register_event
from actions.display import InputRequestAction, DisplayTextAction
from actions.card import ChooseUpgradeCardAction
from localization import LocalStr
from utils.option import Option


@register_event(event_id='upgrade_shrine', acts='shared', weight=100)
class UpgradeShrine(Event):
    """Upgrade shrine - upgrade a card."""
    
    def trigger(self) -> None:
        actions = []
        
        # Display event description
        actions.append(DisplayTextAction(
            text_key='events.upgrade_shrine.description'
        ))
        
        # Build options
        options = [
            Option(
                name=LocalStr('events.upgrade_shrine.pray'),
                actions=[ChooseUpgradeCardAction()]
            ),
            Option(
                name=LocalStr('events.upgrade_shrine.leave'),
                actions=[]
            )
        ]
        
        actions.append(InputRequestAction(
            title=LocalStr('events.upgrade_shrine.title'),
            options=options
        ))
        
        self.end_event()
        from engine.game_state import game_state
        add_actions(actions)
