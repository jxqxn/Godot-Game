"""Defect character configuration."""
from player.character_config import register_character


@register_character(
    name="defect",
    display_name="Defect",
    max_hp=75,
    energy=3,
    gold=99,
    deck=[
        "defect.strike",
        "defect.strike",
        "defect.strike",
        "defect.strike",
        "defect.defend",
        "defect.defend",
        "defect.defend",
        "defect.defend",
        "defect.zap",
        "defect.dualcast",
    ],
    starting_relics=["CrackedCore"],
    orb_slots=3,
    potion_limit=3,
    draw_count=5,
    playable=True,
)
class DefectConfig:
    """Defect character configuration."""

    pass
