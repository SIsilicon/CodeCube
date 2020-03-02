extends Control

var level_folders := {
	"Worlds/Sandbox/Scroll/Grid": "user://levels",
	"Worlds/World 1/Scroll/Grid": "res://levels/world 1"
}

var current_level := ""

func _ready() -> void:
	# I don't know why, but the delete dialog tends to center itself back into the window border, which happens to be outside of the viewport. :P
	$DeleteDialog.rect_position.y -= OS.window_size.y
	
	$Worlds.current_tab = 1
	for world in level_folders.size():
		yield(refresh_levels(world), "completed")

func refresh_levels(tab_index : int) -> void:
	var folder_key : String = level_folders.keys()[tab_index]
	
	for child in get_node(folder_key).get_children():
		get_node(folder_key).remove_child(child)
	
	var dir := Directory.new()
	if dir.open(level_folders[folder_key]) == OK:
		$Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		yield(get_tree(), "idle_frame")
		
		dir.list_dir_begin(true)
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var level_path := dir.get_current_dir() + "/" + file_name
				
				$Viewport/GridMap.load_level_json(level_path, true)
				yield(get_tree(), "idle_frame")
				
				var image : Image = $Viewport.get_texture().get_data()
				var texture := ImageTexture.new()
				texture.create_from_image(image, 0)
				
				var button := $Template.duplicate(DUPLICATE_SIGNALS | DUPLICATE_SCRIPTS)
				get_node(folder_key).add_child(button)
				button.can_be_deleted = tab_index == 0
				button.label = file_name.get_basename()
				button.texture = texture
				button.description = $Viewport/GridMap.description
				button.show()
				button.connect("pressed", self, "_on_level_selected", [level_path])
				button.connect("deletion_requested", self, "_on_Delete_pressed", ["delete"])
			
			file_name = dir.get_next()
		$Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	
	if tab_index == 0: # Sandbox tab
		if get_node(folder_key).get_child_count() > 0:
			$Worlds/Sandbox/Scroll/Grid.show()
			$Worlds/Sandbox/Scroll/Label.hide()
		else:
			$Worlds/Sandbox/Scroll/Grid.hide()
			$Worlds/Sandbox/Scroll/Label.show()

func _on_Back_pressed():
	get_parent().move_to(Vector2.ZERO)

func _on_level_selected(level_file_name : String) -> void:
	current_level = level_file_name
	
	if $DeleteDialog.visible:
		return
	
	var loading_screen = preload("res://loading screen/LoadingScreen.tscn").instance()
	loading_screen.initial_load = false
	loading_screen.scene_to_load = "res://Main.tscn"
	loading_screen.connect("scene_loaded", self, "_on_level_loaded", [level_file_name])
	get_tree().root.add_child(loading_screen)

func _on_level_loaded(scene : Node, level_file_name : String) -> void:
	scene.sandbox_mode = not bool($Worlds.current_tab)
	scene.get_node("GridMap").save_file = level_file_name
	$"../..".queue_free()

func _on_New_Level_pressed() -> void:
	_on_level_selected("")

func _on_Delete_pressed(delete_button : String) -> void:
	match delete_button:
		"confirm":
			var dir := Directory.new()
			dir.remove(current_level)
			refresh_levels($Worlds.current_tab)
		"cancel":
			pass
		_:
			$DeleteDialog.show()
