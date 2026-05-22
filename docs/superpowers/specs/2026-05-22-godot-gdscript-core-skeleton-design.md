# Godot GDScript Core Skeleton Design

## Purpose

Build a Godot-native GDScript skeleton for the `slay-the-model-main` Python project while preserving the original architecture as much as practical. The first stage focuses on stable boundaries, class names, and runtime flow instead of full game content.

The result should make later feature work mostly additive: future cards, enemies, powers, relics, rooms, map logic, and UI can be filled into existing Godot-facing interfaces without a major reshuffle.

## Source Context

The Python source is a logic-first roguelike deck-builder engine. Its important architectural boundaries are:

- `engine/`: global game state, combat loop, combat state, runtime flow.
- `actions/`: queued executable gameplay operations.
- `entities/`: shared creature behavior such as HP, block, powers, and damage.
- `player/`: player state, card piles, energy, deck, orbs, stance, inventory.
- `cards/`: card base class and per-card definitions.
- `enemies/`: enemy base class and per-enemy intention logic.
- `utils/`: enums, registry, random helpers, option/result types.
- Content-heavy modules such as cards, enemies, events, relics, potions, map, localization, AI, and TUI are intentionally not ported in full during this stage.

## Recommended Approach

Use an architecture-first GDScript skeleton, not a mechanical Python-to-GDScript conversion.

The directory and class model should remain close to the Python project, but implementation should be idiomatic enough for Godot 4.6:

- Use `RefCounted` classes for pure rules/data objects.
- Use `Node` only for runtime entry points, scenes, or future UI integration.
- Use simple arrays and dictionaries for card piles, action queues, registries, and test content.
- Keep script files focused and small so later content expansion does not require moving core logic again.
- Avoid porting Python-only patterns such as decorators, dynamic imports, broad global module side effects, and TUI printing.

## Initial Godot File Structure

Create a `scripts/stm/` package-like folder for the converted rules engine:

- `scripts/stm/utils/types.gd`: enum-like constants for target, pile, card, rarity, combat, enemy, and terminal result types.
- `scripts/stm/utils/option.gd`: selectable option object with name and queued actions.
- `scripts/stm/actions/action.gd`: base action class.
- `scripts/stm/actions/action_queue.gd`: queue that executes actions in order.
- `scripts/stm/actions/combat_actions.gd`: minimal combat actions for attack, block, draw, discard, play card, and end turn.
- `scripts/stm/entities/creature.gd`: shared HP, block, death, damage, heal, and power-list behavior.
- `scripts/stm/cards/card.gd`: card base class with cost, damage, block, target type, upgrade data, `can_play`, and `on_play`.
- `scripts/stm/cards/test/strike.gd`: test-only Strike card.
- `scripts/stm/cards/test/defend.gd`: test-only Defend card.
- `scripts/stm/player/card_manager.gd`: deck, draw pile, discard pile, hand, exhaust pile, shuffle, draw, move, discard, exhaust.
- `scripts/stm/player/player.gd`: player creature with energy, deck/card manager, draw count, gold field, relic/potion arrays.
- `scripts/stm/enemies/enemy.gd`: enemy base class with intention fields and minimal intention hooks.
- `scripts/stm/enemies/test/dummy_enemy.gd`: test-only enemy with predictable attack behavior.
- `scripts/stm/engine/combat_state.gd`: per-combat counters and phase state.
- `scripts/stm/engine/combat.gd`: minimal player/enemy turn state machine using `ActionQueue`.
- `scripts/stm/engine/game_state.gd`: global run state, player, current combat, current floor, and queue helpers.
- `scripts/stm/engine/game_bootstrap.gd`: creates a minimal test run with the player, starter test deck, and dummy enemy.
- `scripts/stm/tests/core_skeleton_test.gd`: script-level verification for the first playable rules slice.

## Runtime Design

`GameState` owns the long-lived objects:

- `player`
- `current_combat`
- `action_queue`
- run progress fields such as `current_act`, `floor_in_act`, and `current_floor`

`Combat` owns combat-only flow:

- a list of enemies
- one `CombatState`
- phase transitions: `player_start`, `player_action`, `player_end`, `enemy_action`, `enemy_end`
- methods to start combat, start player turn, play a selected card, end player turn, execute enemy turn, and check terminal states

`ActionQueue` remains the main scheduling mechanism:

- `add_action(action, to_front := false)`
- `add_actions(actions, to_front := false)`
- `execute_next()`
- `execute_all()`
- `is_empty()`

This keeps the Python project's important execution model intact: game logic is expressed as queued actions, not immediate UI callbacks.

## Minimal Content Scope

Only test content is required for this stage:

- `Strike`: cost 1, attack, damage 6, upgrade damage 9.
- `Defend`: cost 1, skill, block 5, upgrade block 8.
- `DummyEnemy`: fixed HP, fixed damage intention, attacks the player during enemy phase.

No full card library, enemy library, powers, relics, potions, events, rooms, map generation, AI, TUI, localization, or reward flow are included in the first implementation.

## Data Flow

1. `GameBootstrap` creates `GameState`.
2. `GameState` creates a `Player` with a small test deck.
3. `GameBootstrap` creates `DummyEnemy` and starts `Combat`.
4. `Combat` resets card piles and prepares the first turn.
5. `CardManager` draws cards into hand.
6. A test or future UI calls a combat method to play a card from hand.
7. `PlayCardAction` checks cost, spends energy, invokes card behavior, and moves the card to discard or exhaust.
8. Damage and block actions mutate `Creature` state.
9. `EndTurnAction` moves combat to player end, discards hand, runs enemy action, and returns to player start unless combat ended.

## Error Handling And Guardrails

The skeleton should fail clearly for invalid rule calls:

- Playing a card not in hand should return `false` or push a readable error.
- Playing without enough energy should return `false`.
- Invalid pile names should use `push_error` and fail without mutating piles.
- Empty draw and discard piles should simply draw fewer cards, not crash.
- Combat should return explicit terminal result constants for win, loss, escape, or no terminal result.

The first version should keep errors local and simple. It should not introduce a full message bus, localization layer, or exception-like abstraction yet.

## Testing Strategy

Use Godot-run script tests first, because the current project has no existing Godot test framework.

The initial test script should verify:

- Player deck resets into draw pile at combat start.
- Drawing moves cards from draw pile to hand.
- Strike spends 1 energy, deals 6 damage, and moves from hand to discard.
- Defend spends 1 energy, gives 5 block, and moves from hand to discard.
- Ending turn discards remaining hand cards.
- Dummy enemy attack is reduced by block before HP loss.
- Combat win is detected when all enemies reach 0 HP.

The test script should be runnable from the Godot CLI with a command equivalent to:

```powershell
& "C:\Users\User\Desktop\Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\User\Documents\GitHub\Godot-Game" --script "res://scripts/stm/tests/core_skeleton_test.gd"
```

## Future Expansion Path

After the skeleton passes, the next layers can be added without changing the core boundaries:

- Add a registry or resource-based catalog for content discovery.
- Add real card batches by character namespace.
- Add enemy intentions and encounter pools.
- Add powers and a lightweight message/event bus.
- Add relics and potions.
- Add rooms, rewards, map flow, and saveable run state.
- Add Godot scenes/UI that read from the rules engine instead of owning rules logic.

## Non-Goals For This Stage

- No full mechanical conversion of all Python files.
- No generated GDScript for every card, enemy, relic, potion, or event.
- No visual UI beyond optional future test/debug scene.
- No AI decision interface.
- No localization parity.
- No compatibility wrapper for running the Python engine inside Godot.
- No attempt to perfectly reproduce every Slay the Spire rule interaction in the first pass.

## Acceptance Criteria

The stage is complete when:

- The Godot project contains the planned `scripts/stm/` architecture skeleton.
- The core class names and responsibilities mirror the Python project closely enough for future porting.
- A headless Godot script test can create a combat, draw cards, play Strike and Defend, end a turn, process a dummy enemy attack, and detect combat win.
- The original `slay-the-model-main` directory remains untouched as the reference implementation.
