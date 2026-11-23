extends SceneTree
## Offline rebuild from actual integrated collision geometry; never modify production.
const STEP := 1.0
const MIN_X := -10
const MAX_X := 178
const MIN_Z := -6
const MAX_Z := 6
func _initialize() -> void:
	call_deferred("_build")
func _build() -> void:
	var world := (load("res://game/network/online_world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in range(80):
		await physics_frame
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.2
	mesh.cell_height = 0.1
	mesh.agent_radius = 0.48
	var vertices := PackedVector3Array()
	var polygons: Array[PackedInt32Array] = []
	var cells := 0
	for x in range(MIN_X, MAX_X):
		for z in range(MIN_Z, MAX_Z):
			var safe := true
			for offset in [Vector2(0.1, 0.1), Vector2(0.1, 0.5), Vector2(0.1, 0.9), Vector2(0.5, 0.1), Vector2(0.5, 0.5), Vector2(0.5, 0.9), Vector2(0.9, 0.1), Vector2(0.9, 0.5), Vector2(0.9, 0.9)]:
				var px: float = float(x) + offset.x
				var pz: float = float(z) + offset.y
				var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(px, 1.1, pz), Vector3(px, 0.25, pz)))
				if not hit.is_empty():
					safe = false
					break
			if not safe:
				continue
			var base := vertices.size()
			vertices.append_array(PackedVector3Array([Vector3(x, 0.2, z), Vector3(x+1, 0.2, z), Vector3(x+1, 0.2, z+1), Vector3(x, 0.2, z+1)]))
			polygons.append(PackedInt32Array([base, base+1, base+2]))
			polygons.append(PackedInt32Array([base, base+2, base+3]))
			cells += 1
	mesh.vertices = vertices
	mesh.polygons = polygons
	var result := ResourceSaver.save(mesh, "res://game/world/rebuilt_world_navigation.tres")
	print("WORLD_NAV_REBUILD=", result, " free_cells=", cells, " vertices=", vertices.size())
	quit(0 if result == OK else 1)
