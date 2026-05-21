from types import SimpleNamespace
from typing import Any, cast

from actions.base import LambdaAction
from actions.card_choice import ChooseUpgradeCardAction
from actions.display import InputRequestAction, MenuAction, ResumeInputRequestAction
from actions.combat import UsePotionAction
from cards.ironclad.strike import Strike
from engine.game_state import GameState, game_state
from engine.input_protocol import InputRequest, InputSubmission
from player.player import Player
from engine.runtime_context import RuntimeContext
from localization import LocalStr
from potions.global_potions import BlockPotion, FruitJuice
from potions.ironclad import BloodPotion
from utils.option import Option
from utils.result_types import GameTerminalState


def test_runtime_context_builds_message_participants_including_hand():
    hand = [object()]
    player_power = object()
    player_relic = object()
    enemy_power = object()
    enemy = SimpleNamespace(hp=10, powers=[enemy_power])
    player = SimpleNamespace(
        relics=[player_relic],
        powers=[player_power],
        card_manager=SimpleNamespace(
            get_pile=lambda pile_name: hand if pile_name == "hand" else []
        ),
    )

    ctx = RuntimeContext(player=player)

    assert ctx.message_participants(enemies=[enemy], include_hand=True) == [
        player,
        player_relic,
        player_power,
        enemy,
        enemy_power,
        hand[0],
    ]


def test_game_state_resolve_input_request_delegates_to_runtime_context():
    gs = GameState()
    expected = InputSubmission([])
    seen_requests = []

    class StubRuntimeContext:
        def resolve_input_request(self, request):
            seen_requests.append(request)
            return expected

    cast(Any, gs).runtime_context = StubRuntimeContext()
    request = InputRequest(
        options=[Option(name=LocalStr("ui.menu_return", default="Return"), actions=[])],
        max_select=1,
    )

    assert gs.resolve_input_request(request) is expected
    assert seen_requests == [request]


def test_human_selection_honors_game_state_helper_overrides(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False

    parsed_inputs = []

    def fake_augment(request):
        return [
            Option(
                name=LocalStr("ui.menu_return", default="Return"),
                actions=[LambdaAction(lambda: None)],
            )
        ]

    def fake_parse(raw_input, option_count, max_select, must_select):
        parsed_inputs.append((raw_input, option_count, max_select, must_select))
        return [0]

    gs._augment_human_options = fake_augment
    gs._parse_selection_input = fake_parse
    monkeypatch.setattr("builtins.input", lambda _prompt: "patched-input")

    submission = gs.resolve_input_request(
        InputRequest(
            options=[Option(name="ignored", actions=[LambdaAction(lambda: None)])],
            max_select=1,
        )
    )

    assert len(submission.actions) == 1
    assert parsed_inputs == [("patched-input", 1, 1, True)]


def test_drive_actions_resolves_input_request_in_debug_mode():
    executed = []

    game_state.config.mode = "debug"
    game_state.config.debug["select_type"] = "first"

    game_state.action_queue.add_action(
        InputRequestAction(
            title=LocalStr("ui.choose_blessings"),
            options=[
                Option(
                    name=LocalStr("ui.menu_return", default="Return"),
                    actions=[LambdaAction(lambda: executed.append("picked"))],
                )
            ],
        )
    )

    result = game_state.drive_actions()

    assert result is None
    assert executed == ["picked"]
    assert game_state.action_queue.is_empty()


def test_drive_actions_returns_terminal_state():
    gs = GameState()
    expected = GameTerminalState.GAME_EXIT

    gs.set_terminal_state(expected)

    assert gs.drive_actions() is expected


def test_drive_actions_returns_none_when_queue_drains_without_terminal_state():
    gs = GameState()
    executed = []
    gs.action_queue.add_action(LambdaAction(lambda: executed.append("ran")))

    assert gs.drive_actions() is None
    assert executed == ["ran"]


def test_parse_selection_input_override_can_return_none(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False

    calls = []
    responses = iter(["first", "second"])

    def fake_parse(self, raw_input, option_count, max_select, must_select):
        calls.append((raw_input, option_count, max_select, must_select))
        if raw_input == "first":
            return None
        return [0]

    monkeypatch.setattr(GameState, "_parse_selection_input", fake_parse)
    monkeypatch.setattr("builtins.input", lambda _prompt: next(responses))

    submission = gs.resolve_input_request(
        InputRequest(
            options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
            max_select=1,
        )
    )

    assert len(submission.actions) == 1
    assert calls == [("first", 1, 1, True), ("second", 1, 1, True)]


def test_human_selection_accepts_menu_command_alias(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False

    monkeypatch.setattr("builtins.input", lambda _prompt: "deck")

    submission = gs.resolve_input_request(
        InputRequest(
            options=[
                Option(
                    name=LocalStr("ui.menu_info_deck", default="Info: deck"),
                    actions=[LambdaAction(lambda: None)],
                    commands=["deck"],
                )
            ],
            max_select=1,
            must_select=True,
        )
    )

    assert len(submission.actions) == 1


def test_human_selection_open_menu_returns_menu_action(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False
    gs.config.human["show_menu_option"] = True

    class _InteractiveStream:
        def isatty(self):
            return True

        def write(self, _text):
            return None

        def flush(self):
            return None

    monkeypatch.setattr("sys.stdin", _InteractiveStream())
    monkeypatch.setattr("sys.stdout", _InteractiveStream())
    monkeypatch.setattr("builtins.input", lambda _prompt: "2")
    monkeypatch.setattr("tui.is_tui_mode", lambda: False)
    monkeypatch.setattr("tui.print_utils.tui_print", lambda *_args, **_kwargs: None)

    submission = gs.resolve_input_request(
        InputRequest(
            options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
            max_select=1,
            must_select=True,
        )
    )

    assert len(submission.actions) == 1
    assert isinstance(submission.actions[0], MenuAction)


def test_human_options_include_only_out_of_combat_potions(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False
    gs.player.potions.append(BloodPotion())
    gs.player.potions.append(FruitJuice())
    gs.player.potions.append(BlockPotion())

    class _InteractiveStream:
        def isatty(self):
            return True

        def write(self, _text):
            return None

        def flush(self):
            return None

    monkeypatch.setattr("sys.stdin", _InteractiveStream())
    monkeypatch.setattr("sys.stdout", _InteractiveStream())
    monkeypatch.setattr("tui.is_tui_mode", lambda: False)

    request = InputRequest(
        title=LocalStr("ui.menu_return", default="Choose"),
        options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
        max_select=1,
        must_select=True,
    )

    augmented = gs.runtime_context.default_augment_human_options(request)
    potion_options = [
        option for option in augmented
        if option.actions and isinstance(option.actions[0], UsePotionAction)
    ]

    assert [option.actions[0].potion.__class__.__name__ for option in potion_options] == [
        "BloodPotion",
        "FruitJuice",
    ]
    assert all(isinstance(option.actions[1], ResumeInputRequestAction) for option in potion_options)


def test_human_options_do_not_add_out_of_combat_potions_during_combat(monkeypatch):
    gs = GameState()
    gs.config.mode = "manual"
    gs.config.auto_select = False
    gs.player.potions.append(BloodPotion())
    cast(Any, gs).current_combat = object()

    class _InteractiveStream:
        def isatty(self):
            return True

        def write(self, _text):
            return None

        def flush(self):
            return None

    monkeypatch.setattr("sys.stdin", _InteractiveStream())
    monkeypatch.setattr("sys.stdout", _InteractiveStream())
    monkeypatch.setattr("tui.is_tui_mode", lambda: False)

    request = InputRequest(
        title=LocalStr("ui.menu_return", default="Choose"),
        options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
        max_select=1,
        must_select=True,
    )

    augmented = gs.runtime_context.default_augment_human_options(request)

    assert not any(
        option.actions and isinstance(option.actions[0], UsePotionAction)
        for option in augmented
    )


def test_debug_selection_receives_out_of_combat_potion_options(monkeypatch):
    gs = GameState()
    gs.config.mode = "debug"
    gs.config.auto_select = False
    gs.player.potions.append(BloodPotion())

    seen = {}

    def fake_debug_selection(request):
        seen["options"] = request.options
        return [1]

    gs._resolve_debug_selection = fake_debug_selection

    submission = gs.resolve_input_request(
        InputRequest(
            title=LocalStr("ui.menu_return", default="Choose"),
            options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
            max_select=1,
            must_select=True,
        )
    )

    assert len(seen["options"]) == 2
    assert isinstance(seen["options"][1].actions[0], UsePotionAction)
    assert seen["options"][1].actions[0].potion.__class__.__name__ == "BloodPotion"
    assert isinstance(submission.actions[0], UsePotionAction)


def test_ai_selection_receives_out_of_combat_potion_options():
    gs = GameState()
    gs.config.mode = "ai"
    gs.config.auto_select = False
    gs.player.potions.append(FruitJuice())

    seen = {}

    class StubDecisionEngine:
        def make_decision(self, title, option_text, context, max_select):
            seen["title"] = title
            seen["option_text"] = option_text
            seen["context"] = context
            seen["max_select"] = max_select
            return [1]

    cast(Any, gs).decision_engine = StubDecisionEngine()

    submission = gs.resolve_input_request(
        InputRequest(
            title=LocalStr("ui.menu_return", default="Choose"),
            options=[Option(name="Only", actions=[LambdaAction(lambda: None)])],
            max_select=1,
            must_select=True,
        )
    )

    assert len(seen["option_text"]) == 2
    assert "Fruit Juice" in seen["option_text"][1]
    assert isinstance(submission.actions[0], UsePotionAction)
    selected_action = cast(UsePotionAction, submission.actions[0])
    assert selected_action.potion.__class__.__name__ == "FruitJuice"


def test_choose_upgrade_all_does_not_create_input_request():
    game_state.__init__()
    gs = game_state
    gs.player = Player()
    strike = Strike()
    gs.player.card_manager.piles["hand"].append(strike)

    resolve_calls = []

    class StubRuntimeContext:
        def resolve_input_request(self, request):
            resolve_calls.append(request)
            raise AssertionError("amount=-1 should not create selection requests")

    cast(Any, gs).runtime_context = StubRuntimeContext()
    gs.action_queue.add_action(ChooseUpgradeCardAction(pile="hand", amount=-1))

    result = gs.drive_actions()

    assert result is None
    assert strike.upgrade_level == 1
    assert gs.pending_input_request is None
    assert resolve_calls == []
