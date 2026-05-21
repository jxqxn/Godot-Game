"""Event: Duplicator - Shrine Event (All Acts)

A shrine that allows the player to duplicate a card in their deck.
"""
from engine.runtime_api import add_action, add_actions, publish_message, request_input, set_terminal_state

from events.base_event import Event
from events.event_pool import register_event
from actions.display import InputRequestAction, DisplayTextAction
from actions.card import ChooseCopyCardAction
from localization import LocalStr
from utils.option import Option


@register_event(event_id='duplicator', acts='shared', weight=100)
class Duplicator(Event):
    """Duplicator shrine - allows duplicating a card."""
    
    def trigger(self) -> None:
        actions = []
        
        # Display event description
        actions.append(DisplayTextAction(
            text_key='events.duplicator.description'
        ))
        
        # Build options
        options = [
            Option(
                name=LocalStr('events.duplicator.pray'),
                actions=[ChooseCopyCardAction()]
            ),
            Option(
                name=LocalStr('events.duplicator.leave'),
                actions=[]
            )
        ]
        
        actions.append(InputRequestAction(
            title=LocalStr('events.duplicator.title'),
            options=options
        ))
        
        self.end_event()
        from engine.game_state import game_state
        add_actions(actions)
