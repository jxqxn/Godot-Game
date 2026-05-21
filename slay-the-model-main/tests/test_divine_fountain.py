from actions.display import DisplayTextAction, InputRequestAction
from cards.colorless.doubt import Doubt
from engine.game_state import game_state
from events.divine_fountain import DivineFountain
from player.player_factory import create_player


def test_divine_fountain_trigger_queues_choice_without_unboundlocalerror():
    game_state.action_queue.clear()
    player = create_player("ironclad")
    player.deck.append(Doubt())
    game_state.player = player

    event = DivineFountain()
    event.trigger()

    queued = list(game_state.action_queue.queue)
    assert len(queued) == 2
    assert isinstance(queued[0], DisplayTextAction)
    assert isinstance(queued[1], InputRequestAction)
    assert event.event_ended is True
