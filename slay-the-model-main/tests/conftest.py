import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG_PATH = (ROOT / "config" / "game_config.yaml").resolve()
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from config.game_config import GameConfig
import engine.game_state as game_state_module


def _build_test_config() -> GameConfig:
    return GameConfig(
        mode="debug",
        language="en",
        seed=1,
        character="Ironclad",
        ascension=0,
        select_overflow="truncate",
        auto_select=False,
        human={"show_menu_option": False},
        debug={"print": False, "select_type": "random", "god_mode": False},
    )


@pytest.fixture(params=[1, 42, 100, 999, 12345, 666, 777, 8888])
def seed(request):
    return request.param


@pytest.fixture(autouse=True)
def reset_global_game_state(monkeypatch):
    """Restore the real engine.game_state module and reset the singleton."""
    original_load = GameConfig.load

    def _load_test_config(config_path):
        if Path(config_path).resolve() == DEFAULT_CONFIG_PATH:
            return _build_test_config()
        return original_load(config_path)

    monkeypatch.setattr(GameConfig, "load", staticmethod(_load_test_config))
    sys.modules["engine.game_state"] = game_state_module
    game_state_module.game_state.__init__()
    yield
    sys.modules["engine.game_state"] = game_state_module
    game_state_module.game_state.__init__()
