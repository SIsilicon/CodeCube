tool
extends Button

signal deletion_requested

export var texture : Texture setget set_texture
export var label := "" setget set_label
export var description := "" setget set_description
export var can_be_deleted := false

var retracted : int
var extended : int

func _ready() -> void:
	retracted = 7
	extended = rect_size.y / 2 - $Name.rect_size.y / 2 - 7
	
	if self != get_tree().edited_scene_root or not Engine.editor_hint:
		set_label(label)
		set_description(description)
		$Name.margin_top = extended
		$Description.modulate = Color.transparent
		$Delete.disabled = true
		$Delete.modulate = Color.transparent

func set_texture(value : Texture) -> void:
	texture = value
	if is_inside_tree():
		$TextureRect.texture = texture

func set_label(value : String) -> void:
	label = value
	if is_inside_tree():
		$Name.text = label

func set_description(value : String) -> void:
	description = value
	if is_inside_tree():
		$Description.text = description

func _on_mouse_entered() -> void:
	if can_be_deleted:
		$Delete.disabled = false
		$Tween.interpolate_property($Delete, "modulate", $Delete.modulate, Color.white, 0.2)
	if not description.empty():
		$Tween.interpolate_property($Name, "margin_top", $Name.margin_top, retracted, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.interpolate_property($Description, "modulate", $Description.modulate, Color.white, 0.5)
	$Tween.start()

func _on_mouse_exited() -> void:
	if can_be_deleted:
		$Delete.disabled = true
		$Tween.interpolate_property($Delete, "modulate", $Delete.modulate, Color.transparent, 0.2)
	if not description.empty():
		$Tween.interpolate_property($Name, "margin_top", $Name.margin_top, extended, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.interpolate_property($Description, "modulate", $Description.modulate, Color.transparent, 0.5)
	$Tween.start()

func _on_resized() -> void:
	extended = rect_size.y / 2 - $Name.rect_size.y - retracted

func _on_Delete_pressed() -> void:
	emit_signal("deletion_requested")
