extends Node

const DYNAMIC_FONT_SIZE = false

func _init() -> void:
	if DYNAMIC_FONT_SIZE:
		var font := preload("res://fonts/Noto Sans UI/NotoSansUI.tres")
		font.size = OS.window_size.x / 70
	
	var dir := Directory.new()
	if not dir.dir_exists("user://programs"):
		dir.make_dir("user://programs")
	if not dir.dir_exists("user://levels"):
		dir.make_dir("user://levels")

func to_signed8(val : int) -> int:
	if val > 0x7F:
		return -(~val & 0xFF) - 1
	return val

func to_signed16(val : int) -> int:
	if val > 0x7FFF:
		return -(~val & 0xFFFF) - 1
	return val
