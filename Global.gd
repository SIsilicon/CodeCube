extends Node

var undo_redo := UndoRedo.new()

func _init() -> void:
	var font := preload("res://fonts/Noto Sans UI/NotoSansUI.tres")
	font.size = OS.window_size.x / 70
