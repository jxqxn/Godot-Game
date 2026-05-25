extends GutTest

const PlayerScript := preload("res://scripts/stm/player/player.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
const GameStateScript := preload("res://scripts/stm/engine/game_state.gd")
const CardScript := preload("res://scripts/stm/cards/card.gd")
const CombatActionsScript := preload("res://scripts/stm/actions/combat_actions.gd")
const StrengthScript := preload("res://scripts/stm/powers/strength.gd")
const VulnerableScript := preload("res://scripts/stm/powers/vulnerable.gd")


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
