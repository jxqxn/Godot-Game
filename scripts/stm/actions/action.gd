class_name StmAction
extends RefCounted


func execute(_game_state) -> int:
	push_error("StmAction.execute() 必须由子类实现")
	return StmTypes.TerminalResult.NONE
