@tool
extends Node3D

@export_group("Sphere")
@export var radius := 8.0:
	set(new_radius):
		radius = maxf(1.0, new_radius)
		update_terrain()
		update_water()
@export var detail := 64:
	set(new_detail):
		detail = maxi(1, new_detail)
		update_terrain()

@export_group("Terrain")
@export var noise := FastNoiseLite.new()
@export var height := 1.0:
	set(new_height):
		height = maxf(0.0, new_height)
		update_terrain()
		update_water()
@export var terrain_material: ShaderMaterial:
	set(new_terrain_material):
		terrain_material = new_terrain_material
		terrain_mesh.surface_set_material(0, terrain_material)
		update_terrain_shader()

@export_group("Water")
@export_range(0.0, 1.0, 0.05) var water_level := 0.0:
	set(new_water_level):
		water_level = new_water_level
		update_water()
@export var water_detail := 64:
	set(new_water_detail):
		water_detail = new_water_detail
		update_water()
@export var water_material: ShaderMaterial:
	set(new_water_material):
		water_material = new_water_material
		water_mesh.surface_set_material(0, water_material)

var terrain_mesh := ArrayMesh.new()
var water_mesh := ArrayMesh.new()


func _ready() -> void:
	noise.changed.connect(update_terrain)
	$Terrain.mesh = terrain_mesh
	$Water.mesh = water_mesh
	update_terrain()
	update_water()


func get_sphere(sphere_radius: float, sphere_detail: int) -> Array:
	var sphere := SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2.0
	
	sphere.radial_segments = sphere_detail * 2
	sphere.rings = sphere_detail
	
	return sphere.get_mesh_arrays()


func get_noise(vertex: Vector3) -> float:
	return (noise.get_noise_3dv(vertex.normalized() * 2.0) + 1.0) / 2.0 * height


func update_terrain() -> void:
	var sphere_mesh_arrays = get_sphere(radius, detail)
	var vertices: PackedVector3Array = sphere_mesh_arrays[ArrayMesh.ARRAY_VERTEX]
	for i: int in vertices.size():
		var vertex := vertices[i]
		vertex += vertex.normalized() * get_noise(vertex)
		vertices[i] = vertex

	terrain_mesh.clear_surfaces()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sphere_mesh_arrays)
	terrain_mesh.surface_set_material(0, terrain_material)
	update_terrain_shader()


func update_water() -> void:
	if water_level == 0.0:
		$Water.visible = false
		return
		
	$Water.visible = true
	var water_radius := lerpf(radius, radius + height, water_level)
	var sphere_mesh_arrays := get_sphere(water_radius, water_detail)
	
	water_mesh.clear_surfaces()
	water_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sphere_mesh_arrays)
	water_mesh.surface_set_material(0, water_material)
	update_water_shader()


func update_terrain_shader() -> void:
	#terrain_material.set_shader_parameter("radius", radius)
	#terrain_material.set_shader_parameter("height", height)
	pass


func update_water_shader() -> void:
	#water_material.set_shader_parameter("radius", radius)
	#water_material.set_shader_parameter("level", radius + height / 2.0)
	pass
