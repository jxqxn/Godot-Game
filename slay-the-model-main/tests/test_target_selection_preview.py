from typing import cast

from actions.combat_cards import PlayCardAction, PlayCardBHAction
from actions.display import InputRequestAction
from cards.ironclad.bash import Bash
from engine.combat import Combat
from engine.game_state import game_state
from player.player import Player
from powers.definitions.strength import StrengthPower
from powers.definitions.vulnerable import VulnerablePower


class _SingleTargetEnemy:
    def __init__(self, name: str, hp: int = 40, max_hp: int = 40, block: int = 0):
        self.name = name
        self.hp = hp
        self.max_hp = max_hp
        self.block = block
        self.powers = []

    def is_dead(self):
        return self.hp <= 0

    def get_damage_taken_multiplier(self):
        multiplier = 1.0
        for power in self.powers:
            hook = getattr(power, "get_damage_taken_multiplier", None)
            if hook is not None:
                multiplier *= hook()
        return multiplier


def test_single_target_selection_shows_target_specific_damage_and_cancel_option():
    player = Player()
    player.powers = [StrengthPower(amount=3, owner=player)]
    game_state.player = player
    game_state.current_combat = Combat(enemies=[])

    enemy = _SingleTargetEnemy("Slime", block=4)
    enemy.powers = [VulnerablePower(amount=1, duration=1, owner=enemy)]
    game_state.current_combat.enemies = [enemy]
    game_state.action_queue.clear()

    PlayCardAction(Bash()).execute()

    queued = game_state.action_queue.peek_next()
    assert isinstance(queued, InputRequestAction)
    queued = cast(InputRequestAction, queued)
    assert len(queued.request.options) == 2
    option_text = str(queued.request.options[0].name)
    assert "Slime" in option_text
    assert "\n  -> Deal 16 damage. Apply 2 Vulnerable." in option_text
    assert queued.request.options[1].actions == []
    assert "cancel" in str(queued.request.options[1].name).lower()


def test_target_selection_option_executes_selected_target_action():
    player = Player()
    game_state.player = player
    enemy = _SingleTargetEnemy("Cultist")
    combat = Combat(enemies=[enemy])
    game_state.current_combat = combat
    game_state.action_queue.clear()

    PlayCardAction(Bash()).execute()

    request = game_state.action_queue.peek_next()
    assert isinstance(request, InputRequestAction)
    request = cast(InputRequestAction, request)

    selected_action = request.request.options[0].actions[0]
    assert isinstance(selected_action, PlayCardBHAction)
    assert selected_action.targets == [enemy]
