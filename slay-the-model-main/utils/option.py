from typing import TYPE_CHECKING

from localization import BaseLocalStr

if TYPE_CHECKING:
    from actions.base import Action


class Option:
    """One selectable option in an input request."""

    def __init__(
        self,
        name: BaseLocalStr | str,
        actions: list["Action"],
        enabled: bool = True,
        commands: list[str] | None = None,
        detail: BaseLocalStr | str | None = None,
    ):
        self.name = name
        self.actions = actions
        self.enabled = enabled
        self.commands = [command.strip().lower() for command in (commands or []) if command.strip()]
        self.detail = detail


def match_option_command(raw_input: str, options: list[Option]) -> list[int] | None:
    """Match a textual command alias to a single option selection."""
    normalized = (raw_input or "").strip().lower()
    if not normalized:
        return None

    matches = [
        idx
        for idx, option in enumerate(options)
        if normalized in getattr(option, "commands", [])
    ]
    if len(matches) != 1:
        return None
    return [matches[0]]
