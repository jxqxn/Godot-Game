extends GutTest

const PlayerScript := preload("res://scripts/stm/player/player.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const CombatScript := preload("res://scripts/stm/engine/combat.gd")
const CardScript := preload("res://scripts/stm/cards/card.gd")
const StrikeScript := preload("res://scripts/stm/cards/test/strike.gd")
const DefendScript := preload("res://scripts/stm/cards/test/defend.gd")
const BashScript := preload("res://scripts/stm/cards/test/bash.gd")
const InflameScript := preload("res://scripts/stm/cards/test/inflame.gd")
const ShrugItOffScript := preload("res://scripts/stm/cards/test/shrug_it_off.gd")
const CombatActionsScript := preload("res://scripts/stm/actions/combat_actions.gd")
const TypesScript := preload("res://scripts/stm/utils/types.gd")
const StrengthScript := preload("res://scripts/stm/powers/strength.gd")
const VulnerableScript := preload("res://scripts/stm/powers/vulnerable.gd")
const WeakScript := preload("res://scripts/stm/powers/weak.gd")
const DexterityScript := preload("res://scripts/stm/powers/dexterity.gd")


class DamageTestSource:
	extends RefCounted

	func modify_damage_dealt(value: int, _target = null, _card = null) -> int:
		return value - 5


class DamageTestTarget:
	extends RefCounted

	var hp: int = 20

	func modify_damage_taken(value: int, _source = null, _card = null) -> int:
		return value + 10

	func take_damage(amount, _source = null, _card = null) -> int:
		var damage := int(amount)
		hp -= damage
		return damage


class ChainMinusPower:
	extends "res://scripts/stm/powers/power.gd"

	func _init() -> void:
		power_id = "chain_minus"
		display_name = "链路减伤"

	func modify_damage_dealt(value: int, _target = null, _card = null) -> int:
		return value - 5


class ChainPlusPower:
	extends "res://scripts/stm/powers/power.gd"

	func _init() -> void:
		power_id = "chain_plus"
		display_name = "链路加伤"

	func modify_damage_taken(value: int, _source = null, _card = null) -> int:
		return value + 10


class CardCapturePower:
	extends "res://scripts/stm/powers/power.gd"

	var seen_card = null

	func _init() -> void:
		power_id = "card_capture"
		display_name = "卡牌捕获"

	func modify_damage_dealt(value: int, _target = null, card = null) -> int:
		seen_card = card
		return value


class BlockCapturePower:
	extends "res://scripts/stm/powers/power.gd"

	var seen_source = null
	var seen_card = null

	func _init() -> void:
		power_id = "block_capture"
		display_name = "格挡捕获"

	func modify_block_gained(value: int, source = null, card = null) -> int:
		seen_source = source
		seen_card = card
		return value + 3


class FakePower:
	extends RefCounted

	var power_id := "fake"


class EndTurnDamageAction:
	extends RefCounted

	func execute(game_state) -> int:
		if game_state != null and game_state.player != null:
			game_state.player.take_damage(3)
		return TypesScript.TerminalResult.NONE


class EndTurnTerminalAction:
	extends RefCounted

	var terminal_result: int = TypesScript.TerminalResult.NONE

	func _init(p_terminal_result: int) -> void:
		terminal_result = p_terminal_result

	func execute(_game_state) -> int:
		return terminal_result


class EndTurnActionEnemy:
	extends "res://scripts/stm/enemies/enemy.gd"

	var queued_action = null

	func _init(action_to_queue = null) -> void:
		super(20, "回合结束敌人", 0)
		queued_action = action_to_queue

	func execute_intention(_game_state, _combat) -> Array:
		return []

	func end_turn(game_state, _combat) -> void:
		if queued_action != null:
			game_state.add_action(queued_action)


class DamageIntentionEnemy:
	extends "res://scripts/stm/enemies/enemy.gd"

	func _init() -> void:
		super(20, "意图伤害敌人", 0)

	func execute_intention(_game_state, _combat) -> Array:
		return [EndTurnDamageAction.new()]


class HpObservingEnemy:
	extends "res://scripts/stm/enemies/enemy.gd"

	var observed_player = null
	var observed_hp: int = -1

	func _init(player_ref = null) -> void:
		super(20, "观察敌人", 0)
		observed_player = player_ref

	func determine_next_intention() -> String:
		if observed_player != null:
			observed_hp = int(observed_player.hp)
		return "observe"

	func execute_intention(_game_state, _combat) -> Array:
		return []


func test_bash_deals_damage_and_applies_vulnerable() -> void:
	# Given：玩家准备打出 Bash，敌人有 20 点生命且没有易伤。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	var game_state = GameStateScript.new(player)
	var card = BashScript.new()
	# When：Bash 的动作被依次执行。
	for action in card.play(game_state, null, [enemy]):
		action.execute(game_state)
	# Then：敌人受到 8 点伤害，并获得 2 回合易伤。
	assert_eq(enemy.hp, 12)
	assert_eq(enemy.get_power("vulnerable").duration, 2)


func test_test_cards_use_chinese_display_names() -> void:
	# Given：策划调试牌组使用五张测试卡。
	var strike = StrikeScript.new()
	var defend = DefendScript.new()
	var bash = BashScript.new()
	var inflame = InflameScript.new()
	var shrug = ShrugItOffScript.new()
	# When：读取这些卡牌的显示名称。
	var names := [strike.card_name, defend.card_name, bash.card_name, inflame.card_name, shrug.card_name]
	# Then：测试卡使用中文名称，便于策划在调试界面识别。
	assert_eq(names, ["打击", "防御", "痛击", "燃烧", "耸肩无视"])


func test_inflame_applies_strength_to_player() -> void:
	# Given：玩家准备打出 Inflame。
	var player = PlayerScript.new([])
	var game_state = GameStateScript.new(player)
	var card = InflameScript.new()
	# When：Inflame 的动作被执行。
	for action in card.play(game_state, null, []):
		action.execute(game_state)
	# Then：玩家获得 2 点力量。
	assert_eq(player.get_power("strength").amount, 2)


func test_shrug_it_off_gains_block_and_draws_card() -> void:
	# Given：玩家抽牌堆里有一张 Strike，并准备打出 Shrug It Off。
	var player = PlayerScript.new([])
	player.card_manager.draw_pile = [StrikeScript.new()]
	var game_state = GameStateScript.new(player)
	var card = ShrugItOffScript.new()
	# When：Shrug It Off 的动作被依次执行。
	for action in card.play(game_state, null, []):
		action.execute(game_state)
	# Then：玩家获得 8 点格挡，并抽到一张手牌。
	assert_eq(player.block, 8)
	assert_eq(player.card_manager.hand.size(), 1)
	assert_eq(player.card_manager.hand[0].card_name, "打击")


func test_apply_power_stacks_intensity_or_duration() -> void:
	# Given：玩家和敌人分别准备接收强度型状态与持续型状态。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	var apply_strength = CombatActionsScript.ApplyPowerAction.new(player, StrengthScript.new(2))
	var apply_more_strength = CombatActionsScript.ApplyPowerAction.new(player, StrengthScript.new(3))
	var apply_vulnerable = CombatActionsScript.ApplyPowerAction.new(enemy, VulnerableScript.new(2))
	var apply_more_vulnerable = CombatActionsScript.ApplyPowerAction.new(enemy, VulnerableScript.new(3))
	# When：状态效果通过动作施加到目标身上。
	apply_strength.execute(null)
	apply_more_strength.execute(null)
	apply_vulnerable.execute(null)
	apply_more_vulnerable.execute(null)
	# Then：力量按强度叠加，易伤按持续时间叠加，并能生成摘要。
	assert_eq(player.get_power("strength").amount, 5)
	assert_eq(enemy.get_power("vulnerable").duration, 5)
	assert_true(player.power_summary_text().contains("力量 5"))
	assert_true(enemy.power_summary_text().contains("易伤 5"))


func test_strength_increases_attack_damage() -> void:
	# Given：玩家拥有 2 点力量，敌人有 20 点生命。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(StrengthScript.new(2))
	# When：玩家执行一次基础 6 点伤害攻击。
	var action = CombatActionsScript.AttackAction.new(player, enemy, 6, null)
	action.execute(null)
	# Then：敌人实际损失 8 点生命。
	assert_eq(enemy.hp, 12)


func test_vulnerable_increases_damage_taken() -> void:
	# Given：敌人拥有 2 回合易伤。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	enemy.add_power(VulnerableScript.new(2))
	# When：玩家对敌人造成 6 点基础伤害。
	var action = CombatActionsScript.AttackAction.new(player, enemy, 6, null)
	action.execute(null)
	# Then：易伤使敌人实际损失 9 点生命。
	assert_eq(enemy.hp, 11)


func test_attack_damage_modifiers_apply_before_single_final_clamp() -> void:
	# Given：基础伤害为 1，攻击方先减伤 5，再由受击方加伤 10。
	var source = DamageTestSource.new()
	var target = DamageTestTarget.new()
	var action = CombatActionsScript.AttackAction.new(source, target, 1, null)
	# When：执行一次攻击结算。
	action.execute(null)
	# Then：应先完成两侧修正再统一下限钳制，最终造成 6 点伤害。
	assert_eq(target.hp, 14)


func test_creature_power_chain_clamps_only_after_all_damage_modifiers() -> void:
	# Given：攻击方先减伤 5，受击方再加伤 10。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(ChainMinusPower.new())
	enemy.add_power(ChainPlusPower.new())
	var action = CombatActionsScript.AttackAction.new(player, enemy, 1, null)
	# When：执行 1 点基础伤害攻击。
	action.execute(null)
	# Then：应在全部修正后再统一钳制，最终造成 6 点伤害。
	assert_eq(enemy.hp, 14)


func test_card_attack_passes_card_context_to_damage_modifiers() -> void:
	# Given：玩家拥有会记录 card 的伤害修正状态，且打出一张 3 伤害卡牌。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	var game_state = GameStateScript.new()
	game_state.player = player
	var capture_power = CardCapturePower.new()
	player.add_power(capture_power)
	var card = CardScript.new()
	card.damage = 3
	var actions = card.play(game_state, null, [enemy])
	# When：执行卡牌生成的动作。
	for action in actions:
		action.execute(game_state)
	# Then：伤害修正器应收到当前 card 上下文。
	assert_eq(capture_power.seen_card, card)


func test_card_block_passes_source_and_card_context_to_block_modifiers() -> void:
	# Given：玩家拥有会记录 source/card 的格挡修正状态，且打出一张 5 格挡卡牌。
	var player = PlayerScript.new([])
	var game_state = GameStateScript.new()
	game_state.player = player
	var capture_power = BlockCapturePower.new()
	player.add_power(capture_power)
	var card = CardScript.new()
	card.block = 5
	var actions = card.play(game_state, null, [])
	# When：执行卡牌生成的格挡动作。
	for action in actions:
		action.execute(game_state)
	# Then：应传入 source=player 与 card=当前卡牌，并把格挡修正为 8。
	assert_eq(player.block, 8)
	assert_eq(capture_power.seen_source, player)
	assert_eq(capture_power.seen_card, card)


func test_add_power_ignores_non_power_objects_without_crashing() -> void:
	# Given：玩家尝试添加一个非 StmPower 的伪对象。
	var player = PlayerScript.new([])
	# When：执行 add_power。
	player.add_power(FakePower.new())
	# Then：应忽略该对象，不应出现在状态容器中。
	assert_false(player.has_power("fake"))


func test_add_power_ignores_expired_powers() -> void:
	# Given：一个持续时间为 0 的过期易伤状态。
	var player = PlayerScript.new([])
	var expired_power = VulnerableScript.new(0)
	# When：尝试添加到玩家状态容器。
	player.add_power(expired_power)
	# Then：应忽略该状态，容器摘要保持“无”。
	assert_false(player.has_power("vulnerable"))
	assert_eq(player.power_summary_text(), "无")


func test_builtin_damage_powers_do_not_clamp_before_action_final_clamp() -> void:
	# Given：攻击方先减伤 5，再叠加内置力量 +2；受击方再加伤 10。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(ChainMinusPower.new())
	player.add_power(StrengthScript.new(2))
	enemy.add_power(ChainPlusPower.new())
	var action = CombatActionsScript.AttackAction.new(player, enemy, 1, null)
	# When：执行一次 1 点基础伤害攻击。
	action.execute(null)
	# Then：内置状态节点不应提前钳制，敌人生命应从 20 变为 12。
	assert_eq(enemy.hp, 12)


func test_builtin_vulnerable_does_not_clamp_before_action_final_clamp() -> void:
	# Given：攻击方先把基础伤害压到负数，受击方先应用易伤再通过后续状态加回正数。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(ChainMinusPower.new())
	enemy.add_power(VulnerableScript.new(1))
	enemy.add_power(ChainPlusPower.new())
	var action = CombatActionsScript.AttackAction.new(player, enemy, 1, null)
	# When：执行一次 1 点基础伤害攻击。
	action.execute(null)
	# Then：易伤节点不应提前钳制，最终应只造成 4 点伤害，敌人生命变为 16。
	assert_eq(enemy.hp, 16)


func test_weak_reduces_attack_damage() -> void:
	# Given：玩家拥有 2 回合虚弱。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(WeakScript.new(2))
	# When：玩家执行一次基础 8 点伤害的攻击。
	var action = CombatActionsScript.AttackAction.new(player, enemy, 8, null)
	action.execute(null)
	# Then：虚弱使敌人只损失 6 点生命。
	assert_eq(enemy.hp, 14)


func test_dexterity_increases_block_from_skill() -> void:
	# Given：玩家拥有 2 点敏捷。
	var player = PlayerScript.new([])
	player.add_power(DexterityScript.new(2))
	# When：玩家执行一次基础 5 点格挡动作。
	var action = CombatActionsScript.GainBlockAction.new(player, 5, player, null)
	action.execute(null)
	# Then：玩家实际获得 7 点格挡。
	assert_eq(player.block, 7)


func test_weak_rounds_fractional_damage_down() -> void:
	# Given：玩家拥有 1 回合虚弱，敌人初始生命为 20。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(WeakScript.new(1))
	# When：玩家执行一次基础 7 点伤害的攻击。
	var action = CombatActionsScript.AttackAction.new(player, enemy, 7, null)
	action.execute(null)
	# Then：虚弱按向下取整生效，敌人仅损失 5 点生命。
	assert_eq(enemy.hp, 15)
	# Given：攻击方先减伤 5，再施加 1 回合虚弱；受击方最后加伤 10。
	var player2 = PlayerScript.new([])
	var enemy2 = EnemyScript.new(20, "测试敌人", 0)
	player2.add_power(ChainMinusPower.new())
	player2.add_power(WeakScript.new(1))
	enemy2.add_power(ChainPlusPower.new())
	# When：执行一次基础 2 点伤害攻击。
	var action2 = CombatActionsScript.AttackAction.new(player2, enemy2, 2, null)
	action2.execute(null)
	# Then：虚弱必须按 floor 处理负数小数，敌人生命应从 20 变为 13。
	assert_eq(enemy2.hp, 13)


func test_builtin_weak_does_not_clamp_before_action_final_clamp() -> void:
	# Given：攻击方先减伤 5，再由虚弱缩放，受击方最后加伤 10。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(ChainMinusPower.new())
	player.add_power(WeakScript.new(1))
	enemy.add_power(ChainPlusPower.new())
	# When：执行一次基础 1 点伤害攻击。
	var action = CombatActionsScript.AttackAction.new(player, enemy, 1, null)
	action.execute(null)
	# Then：应先完成链式修正再统一钳制，敌人生命应从 20 变为 13。
	assert_eq(enemy.hp, 13)


func test_power_duration_ticks_at_turn_boundaries() -> void:
	# Given：敌人拥有 2 回合易伤，战斗即将执行敌人回合。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	var combat = CombatScript.new([enemy], "test")
	var game_state = GameStateScript.new(player)
	enemy.add_power(VulnerableScript.new(2))
	# When：敌人回合被执行一次。
	combat.execute_enemy_turn(game_state)
	# Then：敌人身上的易伤在敌人回合结束时减少 1 回合。
	assert_eq(enemy.get_power("vulnerable").duration, 1)


func test_enemy_duration_power_affects_current_action_before_ticking_down() -> void:
	# Given：敌人拥有 1 回合虚弱，并准备造成 8 点基础攻击。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 8)
	var combat = CombatScript.new([enemy], "test")
	var game_state = GameStateScript.new(player)
	enemy.add_power(WeakScript.new(1))
	# When：敌人回合执行攻击并结算回合结束。
	combat.execute_enemy_turn(game_state)
	# Then：虚弱先影响本次攻击，随后持续时间归零并被移除。
	assert_eq(player.hp, 64)
	assert_false(enemy.has_power("weak"))


func test_enemy_end_turn_actions_are_driven_before_enemy_turn_finishes() -> void:
	# Given：敌人的 end_turn 会入队一个让玩家失去 3 点生命的动作。
	var player = PlayerScript.new([])
	var enemy = EndTurnActionEnemy.new(EndTurnDamageAction.new())
	var combat = CombatScript.new([enemy], "test")
	var game_state = GameStateScript.new(player)
	# When：执行敌人回合。
	combat.execute_enemy_turn(game_state)
	# Then：该动作在敌人回合内被结算，且行动队列为空。
	assert_eq(player.hp, 67)
	assert_true(game_state.action_queue.is_empty())


func test_enemy_end_turn_terminal_result_is_returned() -> void:
	# Given：敌人的 end_turn 会入队一个返回 COMBAT_LOSE 的终局动作。
	var player = PlayerScript.new([])
	var enemy = EndTurnActionEnemy.new(
		EndTurnTerminalAction.new(TypesScript.TerminalResult.COMBAT_LOSE)
	)
	var combat = CombatScript.new([enemy], "test")
	var game_state = GameStateScript.new(player)
	# When：执行敌人回合并接收返回值。
	var result = combat.execute_enemy_turn(game_state)
	# Then：敌人回合应返回该终局结果，且不吞掉该结果。
	assert_eq(result, TypesScript.TerminalResult.COMBAT_LOSE)
	assert_true(game_state.action_queue.is_empty())


func test_player_turn_end_ticks_powers_even_without_card_manager() -> void:
	# Given：玩家有 1 回合易伤，但 card_manager 为空且当前阶段是 player_turn。
	var player = PlayerScript.new([])
	player.add_power(VulnerableScript.new(1))
	player.card_manager = null
	var combat = CombatScript.new([], "test")
	var game_state = GameStateScript.new(player)
	combat.combat_state.current_phase = "player_turn"
	# When：执行玩家回合结束。
	combat.execute_player_end(game_state)
	# Then：易伤会被结算移除，且阶段切换到 enemy_turn。
	assert_false(player.has_power("vulnerable"))
	assert_eq(combat.combat_state.current_phase, "enemy_turn")


func test_enemy_turn_continues_when_fallback_action_drive_returns_none() -> void:
	# Given：action_queue 为空实现，两个敌人都会在 end_turn 入队 3 点伤害动作。
	var player = PlayerScript.new([])
	var enemy_a = EndTurnActionEnemy.new(EndTurnDamageAction.new())
	var enemy_b = EndTurnActionEnemy.new(EndTurnDamageAction.new())
	var combat = CombatScript.new([enemy_a, enemy_b], "test")
	var game_state = GameStateScript.new(player)
	game_state.action_queue = null
	# When：执行整轮敌人回合。
	combat.execute_enemy_turn(game_state)
	# Then：两个 end_turn 动作都在该敌人回合内结算，阶段回到 player_start，且后续 drive 不再改变生命。
	assert_eq(player.hp, 64)
	assert_eq(combat.combat_state.current_phase, "player_start")
	var hp_after_enemy_turn = player.hp
	var second_drive_result = game_state.drive_actions()
	assert_eq(player.hp, hp_after_enemy_turn)
	assert_eq(second_drive_result, TypesScript.TerminalResult.NONE)


func test_enemy_turn_queues_all_enemy_actions_before_driving_queue() -> void:
	# Given：敌人 A 会入队 3 点伤害动作，敌人 B 在决定意图时记录玩家生命。
	var player = PlayerScript.new([])
	var enemy_a = DamageIntentionEnemy.new()
	var enemy_b = HpObservingEnemy.new(player)
	var combat = CombatScript.new([enemy_a, enemy_b], "test")
	var game_state = GameStateScript.new(player)
	# When：执行敌人回合。
	combat.execute_enemy_turn(game_state)
	# Then：敌人 B 记录到的应是结算前生命 70，整轮结束后玩家生命为 67。
	assert_eq(enemy_b.observed_hp, 70)
	assert_eq(player.hp, 67)


func test_fallback_action_drive_returns_terminal_result() -> void:
	# Given：action_queue 为空实现，pending 队列中有一个返回 COMBAT_LOSE 的动作。
	var player = PlayerScript.new([])
	var game_state = GameStateScript.new(player)
	game_state.action_queue = null
	game_state.add_action(EndTurnTerminalAction.new(TypesScript.TerminalResult.COMBAT_LOSE))
	# When：执行 fallback 路径的 drive_actions。
	var result = game_state.drive_actions()
	# Then：应返回该终局结果而不是 null。
	assert_eq(result, TypesScript.TerminalResult.COMBAT_LOSE)


func test_fallback_action_drive_preserves_unexecuted_actions_after_terminal() -> void:
	# Given：fallback 队列先入队终局动作，再入队 3 点伤害动作。
	var player = PlayerScript.new([])
	var game_state = GameStateScript.new(player)
	game_state.action_queue = null
	game_state.add_action(EndTurnTerminalAction.new(TypesScript.TerminalResult.COMBAT_LOSE))
	game_state.add_action(EndTurnDamageAction.new())
	# When：第一次执行 drive_actions。
	var first_result = game_state.drive_actions()
	# Then：第一次返回 COMBAT_LOSE，且伤害动作尚未执行。
	assert_eq(first_result, TypesScript.TerminalResult.COMBAT_LOSE)
	assert_eq(player.hp, 70)
	# When：第二次执行 drive_actions。
	var second_result = game_state.drive_actions()
	# Then：第二次返回 NONE，并执行保留的伤害动作。
	assert_eq(second_result, TypesScript.TerminalResult.NONE)
	assert_eq(player.hp, 67)
