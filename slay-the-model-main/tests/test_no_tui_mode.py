import types

from engine.runtime_context import configure_noninteractive_cli_mode, is_stdin_interactive


class _DummyStdin:
    def __init__(self, interactive):
        self._interactive = interactive

    def isatty(self):
        return self._interactive


class _DummyStdout(_DummyStdin):
    pass


class _InvalidTty(_DummyStdin):
    def fileno(self):
        return 0


class _DummyConfig:
    def __init__(self):
        self.mode = "human"
        self.auto_select = False
        self.debug = {"select_type": "random"}


class _DummyGameState:
    def __init__(self):
        self.config = _DummyConfig()


def test_is_stdin_interactive_uses_isatty():
    assert is_stdin_interactive(_DummyStdin(True), _DummyStdout(True)) is True
    assert is_stdin_interactive(_DummyStdin(True), _DummyStdout(False)) is False
    assert is_stdin_interactive(_DummyStdin(False), _DummyStdout(True)) is False


def test_is_stdin_interactive_rejects_invalid_tty_handles(monkeypatch):
    monkeypatch.setattr("engine.runtime_context.os.get_terminal_size", lambda _fd: (_ for _ in ()).throw(OSError("bad handle")))
    assert is_stdin_interactive(_InvalidTty(True), _InvalidTty(True)) is False


def test_configure_noninteractive_cli_mode_switches_to_debug():
    game_state = _DummyGameState()

    switched = configure_noninteractive_cli_mode(
        game_state,
        stdin=_DummyStdin(False),
        stdout=_DummyStdout(False),
    )

    assert switched is True
    assert game_state.config.mode == "debug"
    assert game_state.config.auto_select is True
    assert game_state.config.debug["select_type"] == "first"


def test_configure_noninteractive_cli_mode_keeps_interactive_mode():
    game_state = _DummyGameState()

    switched = configure_noninteractive_cli_mode(
        game_state,
        stdin=_DummyStdin(True),
        stdout=_DummyStdout(True),
    )

    assert switched is False
    assert game_state.config.mode == "human"
    assert game_state.config.auto_select is False
    assert game_state.config.debug["select_type"] == "random"
