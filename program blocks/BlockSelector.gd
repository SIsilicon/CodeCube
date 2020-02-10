extends ScrollContainer

export var button_theme : Theme

var button_group : ButtonGroup
var blocks := {}

func update_list(block_paths : Array) -> void:
	for button in $Margin/VBox.get_children():
		button.queue_free()
	
	for file in block_paths:
		var block : PackedScene = load(file + ".tscn")
		blocks[file.get_file()] = block
		
		var button := Button.new()
		button.icon = load(file + ".svg")
		button.group = button_group
		button.text = file.get_file()
		button.focus_mode = Control.FOCUS_NONE
		button.enabled_focus_mode = Control.FOCUS_NONE
		button.theme = button_theme
		button.rect_min_size.y = 40
		$Margin/VBox.add_child(button)
		button.connect("button_down", self, "_element_pressed", [button])

func _element_pressed(button : Button) -> void:
	var block : ProgramBlock = blocks[button.text].instance()
	call_deferred("force_drag", block, block)
	button.release_focus()
	button.pressed = false

func get_dir_contents(path: String) -> Array:
	var files = []
	var directories = []
	var dir = Directory.new()
	
	if dir.open(path) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
	else:
		push_error("An error occurred when trying to access the path.")
	
	return [files, directories]

func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()
	
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
	
		if dir.current_is_dir():
#			print("Found dir: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		else:
#			print("Found file: %s" % path)
			files.append(path)
	
		file_name = dir.get_next()
	
	dir.list_dir_end()
