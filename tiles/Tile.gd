tool
extends StaticBody
class_name Tile

enum Type {
	Floor,
	Spikes,
	Goal,
	Spawn,
	Wall,
	WallCorner,
	WallInvCorner,
	WallEdge,
	WallPinch
}
const TYPE_COUNT = 9
const WALL_TYPES = [Type.Wall, Type.WallCorner, Type.WallEdge, Type.WallInvCorner, Type.WallPinch]

export(Type) var type : int setget set_type

var tile : MeshInstance
var tile_name : String
var tile_description : String
var is_wall := false

func _ready():
	match type:
		Type.Floor: tile = $"Tile-floor"
		Type.Spikes: tile = $"Tile-spikes"
		Type.Goal: tile = $"Tile-goal"
		Type.Spawn: tile = $"Tile-spawn"
		Type.Wall: tile = $"Wall"
		Type.WallCorner: tile = $"Wall-corner"
		Type.WallInvCorner: tile = $"Wall-inv-corner"
		Type.WallEdge: tile = $"Wall-edge"
		Type.WallPinch: tile = $"Wall-pinch"
	
	if get_tree().edited_scene_root != self:
		for child in get_children():
			if child == tile:
				continue
			child.queue_free()
		
		tile.translation = Vector3()
		for child in tile.get_children():
			tile.remove_child(child)
			add_child(child)

func set_type(value : int) -> void:
	type = value
	if type in WALL_TYPES:
		is_wall = true
	
	match type:
		Type.Floor:
			tile_name = "Floor"
			tile_description = "A standard tile for QBoy to stay on."
		Type.Spikes:
			tile_name = "Spikes"
			tile_description = "A simple hazard to QBoy that destroys him instantly!"
		Type.Goal:
			tile_name = "Goal"
			tile_description = "The place where you want to go. ->"
		Type.Spawn:
			tile_name = "Spawn"
			tile_description = "This is where the QBoy will start."
		Type.Wall:
			tile_name = "Wall"
			tile_description = "Just something to block Q's path."
		Type.WallCorner: tile_name = "Wall Corner"
		Type.WallInvCorner: tile_name = "Wall Inverted Corner"
		Type.WallEdge: tile_name = "Wall Edge"
		Type.WallPinch: tile_name = "Wall Pinch"

func set_material_override(material : Material, node = self) -> void:
	if node is MeshInstance:
		node.material_override = material
	
	for child in node.get_children():
		set_material_override(material, child)
