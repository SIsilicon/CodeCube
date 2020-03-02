extends CanvasLayer

signal scene_loaded(scene)

onready var tween := $Tween

export var initial_load := false
export var scene_to_load := "res://main menu/Menu.tscn"

var loading = false

func _ready() -> void:
	$Godot.modulate = Color.transparent
	$Background.color = ProjectSettings.get("application/boot_splash/bg_color")
	
	if initial_load:
		tween.interpolate_property($Godot, "modulate", Color.transparent, Color.white, 0.5)
		tween.interpolate_property($Godot, "rect_scale", Vector2(0.65, 0.65), Vector2(0.7, 0.7), 1.5)
		tween.interpolate_property($Godot, "modulate", Color.white, Color.transparent, 0.5, 0, 0, 1.0)
		yield(get_tree().create_timer(0.5), "timeout")
		
		tween.start()
		yield(get_tree().create_timer(2.0), "timeout")
	
	$Loading.show()
	AdvancedBackgroundLoader.preload_scene(scene_to_load)
	loading = true

func _process(_delta : float) -> void:
	$Godot.rect_pivot_offset = $Godot.rect_size / 2.0
	
	$Loading/Label.text = "Loading"
	# warning-ignore:integer_division
	for i in (Engine.get_idle_frames() / 8) & 3:
		$Loading/Label.text += "."
	
	if AdvancedBackgroundLoader.can_change and loading:
		loading = false
		
		if initial_load:
			Global.background_music.play()
		
		AdvancedBackgroundLoader.thread.wait_to_finish()
		var main = AdvancedBackgroundLoader.res.instance()
		emit_signal("scene_loaded", main)
		get_parent().add_child(main)
		
		$Transition.show()
		tween.interpolate_property($Transition, "color", Color(0,0,0,0), Color.black, 0.5)
		tween.interpolate_callback($Loading, 0.5, "hide")
		tween.interpolate_callback($Background, 0.5, "hide")
		tween.interpolate_property($Transition, "color", Color.black, Color(0,0,0,0), 0.5, 0, 0, 0.5)
		tween.interpolate_callback(self, 1.0, "queue_free")
		tween.start()

