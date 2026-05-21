import engine.message_bus as message_bus


def test_legacy_boundary_hook_handlers_are_removed():
    assert not hasattr(message_bus, "PlayerTurnStartedHookHandler")
    assert not hasattr(message_bus, "PlayerTurnEndedHookHandler")
    assert not hasattr(message_bus, "CombatStartedHookHandler")
    assert not hasattr(message_bus, "CombatEndedHookHandler")
    assert not hasattr(message_bus, "CardDiscardedHookHandler")
    assert not hasattr(message_bus, "CardDrawnHookHandler")
    assert not hasattr(message_bus, "ShuffleHookHandler")
    assert not hasattr(message_bus, "CardAddedToPileHookHandler")
    assert not hasattr(message_bus, "PowerAppliedHookHandler")
    assert not hasattr(message_bus, "HealedHookHandler")
    assert not hasattr(message_bus, "HpLostHookHandler")
    assert not hasattr(message_bus, "BlockGainedHookHandler")
    assert not hasattr(message_bus, "DamageResolvedHookHandler")
    assert not hasattr(message_bus, "CreatureDiedHookHandler")
    assert not hasattr(message_bus, "CardPlayedHookHandler")
    assert not hasattr(message_bus, "AttackPerformedHookHandler")
    assert not hasattr(message_bus, "FeelNoPainExhaustHandler")
    assert not hasattr(message_bus, "DarkEmbraceExhaustHandler")
    assert not hasattr(message_bus, "CharonsAshesExhaustHandler")
    assert not hasattr(message_bus, "DeadBranchExhaustHandler")
