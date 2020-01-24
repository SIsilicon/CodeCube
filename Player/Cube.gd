extends Spatial

signal finished_moving
signal died

export var manual_control := false

var moving := false setget set_moving
var executing := false

var linear_velocity := Vector3()
var tile : Tile

onready var anim_player := $AnimationPlayer
onready var tween := $Tween

export var code := [
	"move",
	"move",
	"turn left",
	"jump",
	"move"
]

var turn_direction : int

func teleport(position) -> void:
	tile = position
	$FSM.go_to("teleport_end")

func execute() -> void:
	executing = true
	
	var line_num := 0
	while executing:
		var expression : String = code[line_num]
		match expression:
			"move":
				$FSM.go_to("rolling")
			"turn left":
				turn_direction = 1
				$FSM.go_to("turning")
			"turn right":
				turn_direction = -1
				$FSM.go_to("turning")
			"jump":
				$FSM.go_to("jumping")
			"stop":
				break
		
		yield(self, "finished_moving")
		line_num += 1
	
	executing = false

func _ready() -> void:
	$Cube/Glow.material_override = $Cube/Glow.material_override.duplicate()
	translation = translation.round()
	rotation.y = stepify(rotation.y, PI/2)

func _physics_process(delta : float) -> void:
	$CollisionShape.transform = $Cube.transform
	
	if tile != null:
		if not weakref(tile).get_ref():
			tile = null
	
	if not moving:
		if manual_control:
			if Input.is_action_pressed("ui_up"):
				$FSM.go_to("rolling")
			elif Input.is_action_just_pressed("jump"):
				$FSM.go_to("jumping")
			elif Input.is_action_pressed("ui_left"):
				turn_direction = 1
				$FSM.go_to("turning")
			elif Input.is_action_pressed("ui_right"):
				turn_direction = -1
				$FSM.go_to("turning")
	
	translation += linear_velocity * delta
	if translation.y < -25.0:
		die()

func show_loading_icon() -> void:
	$LoadingIcon.show()
	$LoadingIcon/AnimationPlayer.play("interpreting")

func hide_loading_icon() -> void:
	$LoadingIcon.hide()
	$LoadingIcon/AnimationPlayer.stop()

func die() -> void:
	var explosion : Spatial = preload("res://particle systems/Explode.tscn").instance()
	explosion.translation = $Cube.global_transform.origin
	get_parent().add_child(explosion)
	emit_signal("died")
	
	hide()
	set_physics_process(false)
	$FSM.set_physics_process(false)
	
	$Tween.interpolate_property($ColorRect, "color", Color(1, 0, 0, 0.6), Color.transparent, 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.7, "queue_free")
	$Tween.start()

func play_anim(anim : String) -> void:
	if anim_player.is_playing() and anim_player.current_animation == anim:
		anim_player.seek(0.0, true)
	else:
		anim_player.play(anim)

func floor_position() -> Vector3:
	return translation * Vector3(1, 0, 1)

func get_tile(position : Vector3) -> Tile:
	if $FSM.active_state in ["jumping", "falling"]:
		$FloorCast.translation = Vector3(0, 0.4, 0)
	else:
		$FloorCast.translation = Vector3(0, 0.1, 0)
	$FloorCast.force_raycast_update()
	
	var collider : Tile = $FloorCast.get_collider()
	tile = collider
	if collider is preload("res://tiles/Tile.gd"):
		return collider
	
	return null

func check_wall(dir : float) -> bool:
	$WallCast.cast_to = Vector3(0,0,-1.2).rotated(Vector3.UP, dir)
	$WallCast.force_raycast_update()
	
	var collider : Object = $WallCast.get_collider()
	tile = collider
	if collider is preload("res://tiles/Tile.gd"):
		return collider.is_wall
	
	return false

func check_tile() -> void:
	var tile := get_tile(floor_position())
	
	if tile == null:
		if $FSM.active_state != "jumping":
			$FSM.go_to("falling")
		return
	elif tile.is_wall:
		die()
		return
	
	match tile.type:
		1: die() # spikes
		2: $FSM.go_to("teleport_begin") # goal
		_: $FSM.go_to("idle")

func get_dir() -> Vector3:
	return -transform.basis.z

func set_moving(value : bool) -> void:
	if moving != value and value == false and anim_player.current_animation != "Cube-teleport":
		moving = value
		emit_signal("finished_moving")
		return
	moving = value

