"""Event: Cursed Tome - Act 2 Event

HP for random boss relic (book type).
"""
from engine.runtime_api import add_action, add_actions, publish_message, request_input, set_terminal_state

from events.base_event import Event
from events.event_pool import register_event
from actions.display import InputRequestAction, DisplayTextAction
from actions.reward import AddRandomRelicAction
from utils.types import RarityType
from actions.combat import LoseHPAction
from actions.base import LambdaAction
from localization import LocalStr
from utils.option import Option
from engine.game_state import game_state


@register_event(event_id='cursed_tome', acts=[2], weight=100)
class CursedTome(Event):
    """
    Cursed Tome - HP for boss relic (book).
    
    Sequential state machine:
    - [Read] -> [Continue] Lose 1 HP -> repeat with 2 HP, 3 HP
    - After 3 reads: [Take] Lose 10 (15) HP -> Get Enchiridion/Nilry's Codex/Necronomicon
    - After 3 reads: [Stop] Lose 3 HP
    - [Leave] Nothing happens (available at any time)
    """
    
    # Boss relics that are "books" (card manipulation powers)
    BOOK_RELICS = ['Enchiridion', "Nilry's Codex", 'Necronomicon']
    
    def __init__(self):
        super().__init__()
        self.read_count = 0
    
    def trigger(self) -> None:
        actions = []
        
        # Display event description
        actions.append(DisplayTextAction(
            text_key='events.cursed_tome.description'
        ))
        
        # HP cost for Take: 10 normal, 15 on A15+
        take_hp_cost = 15 if game_state.ascension >= 15 else 10
        
        # Build options based on state
        options = []
        
        if self.read_count < 3:
            # Reading phase: show Continue option
            read_hp = self.read_count + 1  # 1, 2, 3
            options.append(Option(
                name=LocalStr('events.cursed_tome.continue'),
                actions=[
                    LoseHPAction(amount=read_hp),
                    LambdaAction(lambda: self.trigger()),
                ]
            ))
            # Increment read count for next trigger
            self.read_count += 1
        else:
            # After 3 reads, show Take and Stop options
            # Take: Get a random book boss relic
            options.append(Option(
                name=LocalStr('events.cursed_tome.take'),
                actions=[
                    LoseHPAction(amount=take_hp_cost),
                    AddRandomRelicAction(
                        pool=self.BOOK_RELICS,
                        rarities=[RarityType.BOSS]
                    ),
                    LambdaAction(lambda: self.end_event()),
                ]
            ))
            # Stop: Just lose 3 HP
            options.append(Option(
                name=LocalStr('events.cursed_tome.stop'),
                actions=[
                    LoseHPAction(amount=3),
                    LambdaAction(lambda: self.end_event()),
                ]
            ))
        
        # Leave option always available
        options.append(Option(
            name=LocalStr('events.cursed_tome.leave'),
            actions=[LambdaAction(lambda: self.end_event())]
        ))
        
        actions.append(InputRequestAction(
            title=LocalStr('events.cursed_tome.title'),
            options=options
        ))
        
        add_actions(actions)
