"""Event: Sensory Stone - Act 3 Event

Colorless cards for HP trade.
"""
from engine.runtime_api import add_action, add_actions, publish_message, request_input, set_terminal_state

from events.base_event import Event
from events.event_pool import register_event
from actions.display import InputRequestAction, DisplayTextAction
from actions.card import AddRandomCardAction
from actions.combat import LoseHPAction
from localization import LocalStr
from utils.option import Option


@register_event(event_id='sensory_stone', acts=[3], weight=100)
class SensoryStone(Event):
    """Sensory Stone - colorless cards for HP."""
    
    def trigger(self) -> None:
        actions = []
        
        # Display event description
        actions.append(DisplayTextAction(
            text_key='events.sensory_stone.description'
        ))
        
        # Build options
        options = [
            Option(
                name=LocalStr('events.sensory_stone.recall_1'),
                actions=[
                    AddRandomCardAction(namespace='colorless')
                ]
            ),
            Option(
                name=LocalStr('events.sensory_stone.recall_2'),
                actions=[
                    LoseHPAction(amount=5),
                    AddRandomCardAction(namespace='colorless'),
                    AddRandomCardAction(namespace='colorless')
                ]
            ),
            Option(
                name=LocalStr('events.sensory_stone.recall_3'),
                actions=[
                    LoseHPAction(amount=10),
                    AddRandomCardAction(namespace='colorless'),
                    AddRandomCardAction(namespace='colorless'),
                    AddRandomCardAction(namespace='colorless')
                ]
            )
        ]
        
        actions.append(InputRequestAction(
            title=LocalStr('events.sensory_stone.title'),
            options=options
        ))
        
        self.end_event()
        from engine.game_state import game_state
        add_actions(actions)
