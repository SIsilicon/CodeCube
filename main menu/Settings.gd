extends Control

var settings := {
	graphics = {
		container = "Graphics/Scroll/VBox",
		"Ambient Particles": {type = TYPE_BOOL, value = true},
		"Shadow Quality": {type = TYPE_INT, value = 2, hint = PROPERTY_HINT_ENUM, hint_string = "Disabled,Low,Medium,High"},
		"Fullscreen": {type = TYPE_BOOL, value = false}
	},
	sound = {
		container = "Audio/Scroll/VBox",
		"Music": {type = TYPE_REAL, value = 80, hint = PROPERTY_HINT_RANGE, hint_string = "0,100"},
		"SFX": {type = TYPE_REAL, value = 100, hint = PROPERTY_HINT_RANGE, hint_string = "0,100"}
	}
}

var old_settings : Dictionary

func _ready() -> void:
	var file := File.new()
	if file.file_exists("user://settings.json"):
		if not file.open("user://settings.json", File.READ):
			merge_dir(settings, Global.godotify(file.get_line()))
	
	for i in settings.size():
		refresh_settings(i)

func refresh_settings(setting_idx : int) -> void:
	var sub_settings : Dictionary = settings.values()[setting_idx]
	var container : Control = get_node("Panel/TabContainer/" + sub_settings.container)
	
	for child in container.get_children():
		container.remove_child(child)
	
	for key in sub_settings.keys():
		if key == "container":
			continue
		
		var control : Control
		var setting : Dictionary = sub_settings[key]
		var label := Label.new()
		label.text = key + ": "
		
		if setting.type == TYPE_BOOL:
			control = HBoxContainer.new()
			control.add_child(label)
			var check_box := CheckBox.new()
			check_box.connect("toggled", self, "_on_Setting_pressed", [key, setting])
			check_box.pressed = setting.value
			control.add_child(check_box)
		
		elif setting.type == TYPE_INT:
			control = HBoxContainer.new()
			control.add_child(label)
			if setting.hint == PROPERTY_HINT_ENUM:
				var options : PoolStringArray = setting.hint_string.split(",")
				
				var options_control := OptionButton.new()
				for i in options.size():
					options_control.add_item(options[i], i)
				options_control.connect("item_selected", self, "_on_Setting_pressed", [key, setting])
				options_control.selected = setting.value
				
				control.add_child(Label.new())
				control.add_child(options_control)
		
		if setting.type == TYPE_REAL:
			control = HBoxContainer.new()
			control.add_child(label)
			
			if setting.hint == PROPERTY_HINT_RANGE:
				var slider := HSlider.new()
				slider.size_flags_horizontal = SIZE_EXPAND_FILL
				slider.connect("value_changed", self, "_on_Setting_pressed", [key, setting])
				slider.value = setting.value
				
				var params : PoolStringArray = setting.hint_string.split(",")
				slider.min_value = float(params[0])
				slider.max_value = float(params[1])
				if params.size() > 2:
					slider.step = float(params[2])
				control.add_child(slider)
		
		_on_Setting_pressed(setting.value, key, setting)
		if control:
			control.size_flags_horizontal = SIZE_EXPAND_FILL
			container.add_child(control)

func _on_Setting_pressed(value, name : String, setting : Dictionary) -> void:
	match name:
		"Ambient Particles":
			Global.particles_enabled = value
			$"../../CamRoot/Camera/CPUParticles".visible = value
			$"../../CamRoot/Camera/CPUParticles".emitting = value
		"Shadow Quality":
			ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", value)
			Global.shadows_enabled = bool(value)
			var size := 1024
			match value:
				1:
					size = 512
				2:
					size = 1024
				3:
					size = 2048
			ProjectSettings.set_setting("rendering/quality/shadow_atlas/size", size)
		"Fullscreen":
			OS.window_fullscreen = value
		"Music":
			AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index("Music"), linear2db(value / 100.0)
			)
		"SFX":
			AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index("SFX"), linear2db(value / 100.0)
			)
	
	setting.value = value

func _on_Back_pressed() -> void:
	get_parent().move_to(Vector2.ZERO)
	settings = old_settings
	
	for i in settings.size():
		refresh_settings(i)

func _on_Save_pressed() -> void:
	var file := File.new()
	if file.open("user://settings.json", File.WRITE):
		return
	file.store_line(Global.jsonify(settings))
	file.close()
	
	get_parent().move_to(Vector2.ZERO)

# Code by Zylann from
# https://godotengine.org/qa/8024/update-dictionary-method?show=8049#c8049
static func merge_dir(target : Dictionary, patch : Dictionary) -> void:
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dir(tv, patch[key])
			else:
				target[key] = patch[key]
		else:
			target[key] = patch[key]
