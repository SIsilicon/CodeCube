tool
extends GridMap

func _ready():
	for pos in get_used_cells():
		if get_cell_item(pos.x, pos.y, pos.z) == 5:
			var portal_particles = preload("res://particle systems/Portal.tscn").instance()
			portal_particles.transform = Transform().translated(pos)
			add_child(portal_particles)
	

