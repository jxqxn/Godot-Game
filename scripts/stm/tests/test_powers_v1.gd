extends GutTest

const PlayerScript := preload("res://scripts/stm/player/player.gd")
const EnemyScript := preload("res://scripts/stm/enemies/enemy.gd")
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
	# Then：力量按强度叠加，易伤按持续时间叠加，并能生成策划可读的摘要。
	assert_eq(player.get_power("strength").amount, 5)
	assert_eq(enemy.get_power("vulnerable").duration, 5)
	assert_true(player.power_summary_text().contains("力量 5"))
	assert_true(enemy.power_summary_text().contains("易伤 5"))


func test_strength_increases_attack_damage() -> void:
	# Given：玩家拥有 2 点力量，敌人有 20 点生命。
	var player = PlayerScript.new([])
	var enemy = EnemyScript.new(20, "测试敌人", 0)
	player.add_power(StrengthScript.new(2))
	# When：玩家执行一次基础 6 点伤害的攻击。
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
	# Then：应先完成两侧修正再统一下限钳制，最终仅造成 6 点伤害。
	assert_eq(target.hp, 14)
