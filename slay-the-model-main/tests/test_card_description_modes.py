from cards.ironclad.bash import Bash
from engine.game_state import game_state
from player.player import Player
from powers.definitions.strength import StrengthPower
from powers.definitions.vulnerable import VulnerablePower


class _PreviewEnemy:
    def __init__(self):
        self.hp = 30
        self.max_hp = 30
        self.block = 0
        self.powers = []

    def get_damage_taken_multiplier(self):
        multiplier = 1.0
        for power in self.powers:
            hook = getattr(power, "get_damage_taken_multiplier", None)
            if hook is not None:
                multiplier *= hook()
        return multiplier


def test_card_description_uses_base_values_outside_combat():
    player = Player()
    player.powers = [StrengthPower(amount=3, owner=player)]
    game_state.player = player

    card = Bash()

    assert str(card.description) == "Deal 8 damage. Apply 2 Vulnerable."
    assert str(card.combat_description) == "Deal 11 damage. Apply 2 Vulnerable."


def test_targeted_combat_description_uses_target_modifiers():
    player = Player()
    player.powers = [StrengthPower(amount=3, owner=player)]
    game_state.player = player

    enemy = _PreviewEnemy()
    enemy.powers = [VulnerablePower(amount=1, duration=1, owner=enemy)]

    card = Bash()

    assert card.get_combat_description(target=enemy).resolve() == "Deal 16 damage. Apply 2 Vulnerable."
