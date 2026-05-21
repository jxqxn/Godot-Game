import pytest

import engine.game_state as game_state_module
import localization
from config.game_config import GameConfig
from engine.game_flow import GameFlow


def _import_runtime_dependencies():
    import rooms  # noqa: F401
    import relics  # noqa: F401
    import potions  # noqa: F401
    from powers import definitions  # noqa: F401


def _build_runtime_config(character: str, language: str) -> GameConfig:
    return GameConfig(
        mode="debug",
        language=language,
        seed=1,
        character=character,
        ascension=0,
        select_overflow="truncate",
        auto_select=False,
        human={"show_menu_option": False},
        debug={"print": False, "select_type": "first", "god_mode": False},
    )


def test_game_config_load_reads_template_defaults():
    config = GameConfig.load("config/game_config_template.yaml")

    assert config.mode == "debug"
    assert config.language == "en"
    assert config.character == "Ironclad"
    assert config.auto_select is False
    assert config.debug["select_type"] == "random"
    assert config.debug["god_mode"] is False


@pytest.mark.parametrize("character", ["Ironclad", "Silent", "Defect"])
@pytest.mark.parametrize("language", ["en", "zh"])
def test_game_runs_through_initial_flow_for_character_and_language(
    monkeypatch,
    character: str,
    language: str,
):
    _import_runtime_dependencies()
    explicit_config = _build_runtime_config(character=character, language=language)

    monkeypatch.setattr(
        GameConfig,
        "load",
        staticmethod(lambda _path: explicit_config),
    )

    game_state_module.game_state.__init__()
    game_state = game_state_module.game_state

    flow = GameFlow()
    assert flow._execute_init_act_phase(game_state) is None
    assert flow.flow_phase == "neo_room"
    assert game_state.map_manager is not None
    assert game_state.player.character == character
    assert localization.current_language == language

    assert flow._execute_neo_room_phase(game_state) is None
    assert flow.flow_phase == "select_room"
    assert game_state.pending_input_request is None
    assert game_state.terminal_state is None
    assert game_state.player.max_hp > 0
