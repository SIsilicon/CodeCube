extends Scriptable

signal finished_moving
signal died

export var manual_control := false

onready var anim_player := $AnimationPlayer
onready var tween := $Tween

var moving := false setget set_moving

var linear_velocity := Vector3()
var turn_direction : int
var face_state := 0 setget set_face_state
var tile : Tile

func custom_execute(expression : String) -> bool:
	match expression:
		"move":
			$FSM.go_to("rolling")
			yield(self, "finished_moving")
		"turn left":
			turn_direction = 1
			$FSM.go_to("turning")
			yield(self, "finished_moving")
		"turn right":
			turn_direction = -1
			$FSM.go_to("turning")
			yield(self, "finished_moving")
		"jump":
			$FSM.go_to("jumping")
			yield(self, "finished_moving")
		_:
			return false
	return true

func _ready() -> void:
	custom_insruction_set = funcref(self, "custom_execute")
	custom_blocks = [
		"res://program blocks/Blocks/Action Blocks/Jump Block",
		"res://program blocks/Blocks/Action Blocks/Move Block",
		"res://program blocks/Blocks/Action Blocks/Turn Block"
	]
	
	$Cube/Glow.material_override = $Cube/Glow.material_override.duplicate()
	translation = translation.round()
	rotation.y = stepify(rotation.y, PI/2)

func _unhandled_input(event : InputEvent) -> void:
	if not moving:
		if manual_control:
			if event.is_action_pressed("ui_up"):
				$FSM.go_to("rolling")
			elif event.is_action_pressed("jump"):
				$FSM.go_to("jumping")
			elif event.is_action_pressed("ui_left"):
				turn_direction = 1
				$FSM.go_to("turning")
			elif event.is_action_pressed("ui_right"):
				turn_direction = -1
				$FSM.go_to("turning")

func _physics_process(delta : float) -> void:
	$CollisionShape.transform = $Cube.transform
	
	if tile != null:
		if not weakref(tile).get_ref():
			tile = null
	
	translation += linear_velocity * delta
	if translation.y < -25.0:
		die()

func _exit_tree() -> void:
	set_face_state(0)

func show_loading_icon() -> void:
	$LoadingIcon.show()
	$LoadingIcon/AnimationPlayer.play("interpreting")

func hide_loading_icon() -> void:
	$LoadingIcon.hide()
	$LoadingIcon/AnimationPlayer.stop()

func teleport(position) -> void:
	tile = position
	$FSM.go_to("teleport_end")

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

# warning-ignore:unused_argument
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
	# warning-ignore:shadowed_variable
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

func set_face_state(value : int) -> void:
	face_state = value
	
	var eye_offset := Vector3()
	eye_offset.x += 0.25 * face_state
	$Cube.mesh.surface_get_material(0).uv1_offset = eye_offset

func _on_Blink_timeout():
	if face_state == 0:
		set_face_state(1)
	elif face_state == 1:
		set_face_state(0)
	
	if face_state:
		$Blink.wait_time = rand_range(0.08, 0.2)
	else:
		$Blink.wait_time = rand_range(0.3, 3.0)
	$Blink.start()
