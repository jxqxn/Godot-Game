from types import SimpleNamespace
from typing import cast

from cards.ironclad.bash import Bash
from cards.ironclad.defend import Defend
from engine.combat import Combat
from engine.game_state import game_state
from player.player import Player
from powers.definitions.frail import FrailPower
from powers.definitions.strength import StrengthPower
from tui.handlers.display_handler import DisplayHandler


class _RecordingApp:
    def __init__(self):
        self.player_info = ""
        self.display_content = ""

    def update_player_info(self, player, gs):
        hp_bar = f"HP: {player.hp}/{player.max_hp}"
        energy_str = f"Energy: {player.energy}/{player.max_energy}"
        gold_str = f"Gold: {player.gold}"
        floor_str = f"Floor: {gs.current_floor + 1}"
        block_str = f"Block: {player.block}"
        self.player_info = f"{hp_bar}\n{energy_str} | {gold_str} | {floor_str} | {block_str}"

    def update_display_content(self, content: str):
        self.display_content = content


def test_display_combat_uses_dynamic_hand_values_and_groups_player_state_first():
    player = Player()
    player.block = 12
    player.powers = [
        StrengthPower(amount=3, owner=player),
        FrailPower(amount=1, duration=1, owner=player),
    ]
    player.card_manager.piles["hand"] = [Bash(), Defend()]
    game_state.player = player

    enemy = SimpleNamespace(
        hp=40,
        max_hp=40,
        block=5,
        powers=[],
        current_intention=None,
        is_dead=lambda: False,
        local=lambda field: SimpleNamespace(resolve=lambda: "Training Dummy"),
    )
    combat = cast(Combat, SimpleNamespace(enemies=[enemy]))

    app = _RecordingApp()
    DisplayHandler(app).display_combat(combat, game_state)

    assert "Block: 12" in app.player_info
    assert "Deal 11 damage" in app.display_content
    assert "Gain 3 Block" in app.display_content
    assert app.display_content.index("Powers") < app.display_content.index("Enemies")
    assert "鈹" not in app.display_content
    assert "鈻" not in app.player_info
    assert "閳" not in app.display_content
