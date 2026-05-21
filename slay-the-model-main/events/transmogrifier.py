"""Event: Transmogrifier - Shrine Event (All Acts)

A shrine that allows transforming a card into a random card.
"""
from engine.runtime_api import add_action, add_actions, publish_message, request_input, set_terminal_state

from events.base_event import Event
from events.event_pool import register_event
from actions.display import InputRequestAction, DisplayTextAction
from actions.card import ChooseTransformCardAction
from localization import LocalStr
from utils.option import Option


@register_event(event_id='transmogrifier', acts='shared', weight=100)
class Transmogrifier(Event):
    """Transmogrifier shrine - transform a card."""
    
    def trigger(self) -> None:
        actions = []
        
        # Display event description
        actions.append(DisplayTextAction(
            text_key='events.transmogrifier.description'
        ))
        
        # Build options
        options = [
            Option(
                name=LocalStr('events.transmogrifier.pray'),
                actions=[ChooseTransformCardAction()]
            ),
            Option(
                name=LocalStr('events.transmogrifier.leave'),
                actions=[]
            )
        ]
        
        actions.append(InputRequestAction(
            title=LocalStr('events.transmogrifier.title'),
            options=options
        ))
        
        self.end_event()
        from engine.game_state import game_state
        add_actions(actions)
