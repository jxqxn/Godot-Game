class_name StmTypes
extends RefCounted


enum TargetType {
	NONE,
	SELF,
	ENEMY,
	ALL_ENEMIES,
	ALL,
}

enum PilePosType {
	TOP,
	BOTTOM,
	RANDOM,
}

enum CardType {
	ATTACK,
	SKILL,
	POWER,
	STATUS,
	CURSE,
}

enum RarityType {
	BASIC,
	COMMON,
	UNCOMMON,
	RARE,
	SPECIAL,
}

enum CombatType {
	NORMAL,
	ELITE,
	BOSS,
	EVENT,
}

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS,
	MINION,
}

enum TerminalResult {
	NONE,
	COMBAT_WIN,
	GAME_LOSE,
	COMBAT_ESCAPE,
	COMBAT_LOSE = GAME_LOSE,
	EVENT_COMPLETE = 4,
}
