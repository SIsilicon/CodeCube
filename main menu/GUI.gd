extends CanvasLayer

onready var camera := $"../CamRoot/Camera"
var cam_pos : Vector3

func _ready() -> void:
	cam_pos = camera.translation

func move_to(new_pos : Vector2) -> void:
	$Tween.interpolate_property(self, "offset", offset, -$MenuHub.rect_size * new_pos, 1.0, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$Tween.interpolate_property(camera, "translation", camera.translation, cam_pos - Vector3(-new_pos.x * 12.0, new_pos.y * 7.0, 0), \
			1.0, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$Tween.start()
