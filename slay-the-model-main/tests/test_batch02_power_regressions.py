from actions.combat import ApplyPowerAction
from actions.combat_damage import DealDamageAction, LoseHPAction
from engine.messages import PlayerTurnEndedMessage
from powers.base import Power, StackType
from powers.definitions.artifact import ArtifactPower
from powers.definitions.buffer import BufferPower
from powers.definitions.intangible import IntangiblePower
from powers.definitions.no_draw import NoDrawPower
from powers.definitions.strength import StrengthPower
from powers.definitions.strength_down import StrengthDownPower
from powers.definitions.the_bomb import TheBombPower
from powers.definitions.weak import WeakPower
from tests.test_combat_utils import create_test_helper


class _NoOpEnemy:
    def __init__(self, hp: int = 40):
        from enemies.base import Enemy

        class _Enemy(Enemy):
            def __init__(self, hp_value: int):
                super().__init__(max_hp=hp_value, name="Target Dummy")

            def determine_next_intention(self, floor: int = 1):
                class _Intent:
                    name = "Idle"
                    description = "Idle"

                    def execute(self):
                        return None

                return _Intent()

        self.instance = _Enemy(hp)


class _SharedDisplayNamePowerA(Power):
    name = "Shared Display Name"
    stack_type = StackType.INTENSITY


class _SharedDisplayNamePowerB(Power):
    name = "Shared Display Name"
    stack_type = StackType.INTENSITY


def _enemy(hp: int = 40):
    return _NoOpEnemy(hp).instance


def test_artifact_consumes_one_stack_and_then_allows_next_debuff():
    helper = create_test_helper()
    player = helper.create_player()
    helper.start_combat([_enemy()])
    player.add_power(ArtifactPower(amount=1, owner=player))

    ApplyPowerAction(WeakPower(duration=2, owner=player), player).execute()
    helper.game_state.drive_actions()

    assert player.get_power("Artifact") is None
    assert player.get_power("Weak") is None

    ApplyPowerAction(WeakPower(duration=2, owner=player), player).execute()
    helper.game_state.drive_actions()

    weak = player.get_power("Weak")
    assert weak is not None
    assert weak.duration == 2


def test_buffer_does_not_trigger_when_block_absorbs_all_damage():
    helper = create_test_helper()
    player = helper.create_player(hp=80, max_hp=80)
    enemy = _enemy()
    helper.start_combat([enemy])
    player.block = 8
    player.add_power(BufferPower(amount=1, owner=player))

    DealDamageAction(damage=5, target=player, source=enemy).execute()
    helper.game_state.drive_actions()

    buffer = player.get_power("Buffer")
    assert buffer is not None
    assert buffer.amount == 1
    assert player.block == 3
    assert player.hp == 80


def test_strength_down_returns_negative_strength_at_turn_end():
    helper = create_test_helper()
    player = helper.create_player()
    helper.start_combat([_enemy()])
    player.add_power(StrengthPower(amount=3, owner=player))
    down = StrengthDownPower(amount=3, owner=player)
    player.add_power(down)

    helper.game_state.publish_message(
        PlayerTurnEndedMessage(owner=player, enemies=[], hand_cards=[]),
    )
    helper.game_state.drive_actions()

    assert player.strength == 0
    assert player.get_power("Strength Down") is None


def test_lose_hp_is_capped_by_intangible():
    helper = create_test_helper()
    player = helper.create_player(hp=20, max_hp=20)
    helper.start_combat([_enemy()])
    player.add_power(IntangiblePower(duration=1, owner=player))

    LoseHPAction(amount=5, target=player).execute()
    helper.game_state.drive_actions()

    assert player.hp == 19


def test_expiring_multi_instance_power_removes_only_that_instance():
    helper = create_test_helper()
    player = helper.create_player()
    combat = helper.start_combat([_enemy()])
    expiring = TheBombPower(amount=40, duration=1, owner=player)
    remaining = TheBombPower(amount=50, duration=3, owner=player)
    player.add_power(expiring)
    player.add_power(remaining)

    combat._end_player_phase()
    helper.game_state.drive_actions()

    bombs = [power for power in player.powers if isinstance(power, TheBombPower)]
    assert len(bombs) == 1
    assert bombs[0] is remaining
    assert bombs[0].duration == 2


def test_add_power_uses_identity_not_display_name_for_merging():
    creature = _enemy(hp=30)

    creature.add_power(_SharedDisplayNamePowerA(amount=1, owner=creature))
    creature.add_power(_SharedDisplayNamePowerB(amount=2, owner=creature))

    assert len(creature.powers) == 2
    assert sum(power.amount for power in creature.powers) == 3


def test_no_draw_is_debuff():
    power = NoDrawPower(duration=1)
    assert power.is_buff is False
