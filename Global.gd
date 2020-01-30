extends Node

func _init() -> void:
	var font := preload("res://fonts/Noto Sans UI/NotoSansUI.tres")
	font.size = OS.window_size.x / 70
	
	var dir := Directory.new()
	if not dir.dir_exists("user://programs"):
		dir.make_dir("user://programs")
	if not dir.dir_exists("user://levels"):
		dir.make_dir("user://levels")
