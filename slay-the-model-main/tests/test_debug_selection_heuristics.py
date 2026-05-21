from actions.combat import EndTurnAction, PlayCardAction
from cards.ironclad.strike import Strike
from engine.game_state import GameState
from engine.input_protocol import InputRequest
from utils.option import Option
from typing import Any, cast


class _DummyCombat:
    pass


def test_debug_selection_prefers_attack_over_end_turn_in_combat():
    gs = GameState()
    cast(Any, gs).current_combat = _DummyCombat()

    request = InputRequest(
        options=[
            Option(name='End', actions=[EndTurnAction()]),
            Option(name='Strike', actions=[PlayCardAction(Strike())]),
        ],
        max_select=1,
    )

    assert gs._resolve_debug_selection(request) == [1]


def test_debug_selection_honors_game_state_score_override():
    gs = GameState()
    cast(Any, gs).current_combat = _DummyCombat()

    seen = []

    def fake_score(option):
        seen.append(str(option.name))
        return 100 if str(option.name) == "End" else 0

    gs._score_debug_option = fake_score

    request = InputRequest(
        options=[
            Option(name="End", actions=[EndTurnAction()]),
            Option(name="Strike", actions=[PlayCardAction(Strike())]),
        ],
        max_select=1,
    )

    assert gs._resolve_debug_selection(request) == [0]
    assert seen == ["End", "Strike"]


def test_debug_selection_honors_class_level_score_override(monkeypatch):
    gs = GameState()
    cast(Any, gs).current_combat = _DummyCombat()

    seen = []

    def fake_score(self, option):
        seen.append(str(option.name))
        return 100 if str(option.name) == "End" else 0

    monkeypatch.setattr(GameState, "_score_debug_option", fake_score)

    request = InputRequest(
        options=[
            Option(name="End", actions=[EndTurnAction()]),
            Option(name="Strike", actions=[PlayCardAction(Strike())]),
        ],
        max_select=1,
    )

    assert gs._resolve_debug_selection(request) == [0]
    assert seen == ["End", "Strike"]


def test_debug_selection_heuristics_override_can_return_none(monkeypatch):
    gs = GameState()
    cast(Any, gs).current_combat = _DummyCombat()
    gs.config.debug["select_type"] = "random"

    seen = []

    def fake_heuristics(self, options, actual_max_select):
        seen.append((len(options), actual_max_select))
        return None

    monkeypatch.setattr(GameState, "_resolve_debug_selection_with_heuristics", fake_heuristics)
    monkeypatch.setattr("engine.runtime_context.rd.sample", lambda population, sample_size: [0])

    request = InputRequest(
        options=[
            Option(name="End", actions=[EndTurnAction()]),
            Option(name="Strike", actions=[PlayCardAction(Strike())]),
        ],
        max_select=1,
    )

    assert gs._resolve_debug_selection(request) == [0]
    assert seen == [(2, 1)]
