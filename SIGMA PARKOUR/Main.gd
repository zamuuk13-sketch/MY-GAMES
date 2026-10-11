extends Node3D

# SIGMA PARKOUR — greybox environment prototype.
# All geometry is generated at runtime so the first map needs no external assets.

const BLUE := Color(0.055, 0.30, 0.78)
const BLUE_LIGHT := Color(0.12, 0.48, 0.95)
const BLUE_DARK := Color(0.025, 0.12, 0.36)
const WHITE := Color(0.88, 0.94, 1.0)

var mat_ground: StandardMaterial3D
var mat_platform: StandardMaterial3D
var mat_accent: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_cloud: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_make_environment()
	_make_lighting()
	_make_map()
	_make_clouds()
	_make_preview_camera()

func _make_materials() -> void:
	mat_ground = _material(Color(0.045, 0.20, 0.52), 0.82)
	mat_platform = _material(BLUE, 0.72)
	mat_accent = _material(BLUE_LIGHT, 0.62)
	mat_dark = _material(BLUE_DARK, 0.78)
	mat_cloud = _material(Color(0.96, 0.98, 1.0), 0.95)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness_value
	return m

func _make_environment() -> void:
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.10, 0.34, 0.78)
	sky_mat.sky_horizon_color = Color(0.66, 0.82, 1.0)
	sky_mat.ground_bottom_color = Color(0.13, 0.20, 0.30)
	sky_mat.ground_horizon_color = Color(0.64, 0.78, 0.90)
	sky_mat.sun_angle_max = 18.0
	sky_mat.use_debanding = true
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.glow_enabled = false

	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = env
	add_child(world)

func _make_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sunlight"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 100.0
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.82
	add_child(sun)

func _make_map() -> void:
	# Large blue base; the raised platforms form a simple parkour route.
	_make_platform("BlueBase", Vector3(0, -0.55, 0), Vector3(42, 1, 42), mat_ground)

	# Main route: progressively raised platforms with safe gaps.
	_make_platform("StartPlatform", Vector3(0, 0.15, 8), Vector3(7, 0.3, 5), mat_platform)
	_make_platform("Step01", Vector3(0, 0.65, 3.2), Vector3(3.4, 0.6, 2.8), mat_accent)
	_make_platform("Step02", Vector3(-2.1, 1.25, -0.7), Vector3(3.0, 0.5, 3.0), mat_platform)
	_make_platform("Step03", Vector3(1.2, 1.85, -4.2), Vector3(3.2, 0.5, 2.7), mat_accent)
	_make_platform("HighPlatform", Vector3(4.4, 2.55, -8.1), Vector3(5.0, 0.7, 4.0), mat_platform)

	# Lateral precision-jump line.
	_make_platform("SideJumpA", Vector3(-6.2, 0.65, 1.2), Vector3(2.6, 0.6, 2.6), mat_accent)
	_make_platform("SideJumpB", Vector3(-9.4, 1.15, -1.8), Vector3(2.6, 0.6, 2.6), mat_platform)
	_make_platform("SideJumpC", Vector3(-6.4, 1.7, -5.1), Vector3(2.8, 0.6, 2.8), mat_accent)

	# Wide training blocks and low walls for future vault / climb mechanics.
	_make_platform("VaultBlock", Vector3(7.5, 0.55, 3.0), Vector3(4.0, 1.1, 1.0), mat_dark)
	_make_platform("LowWall", Vector3(11.0, 0.65, 6.0), Vector3(1.0, 1.3, 5.0), mat_accent)
	_make_platform("LongRunUp", Vector3(8.0, 0.15, 10.0), Vector3(8.0, 0.3, 4.0), mat_platform)

	# Three blocks make a visible staircase for testing approach and landing.
	_make_platform("Stair01", Vector3(-12.0, 0.25, 8.0), Vector3(3.0, 0.5, 3.0), mat_platform)
	_make_platform("Stair02", Vector3(-12.0, 0.75, 4.4), Vector3(3.0, 0.5, 3.0), mat_accent)
	_make_platform("Stair03", Vector3(-12.0, 1.25, 0.8), Vector3(3.0, 0.5, 3.0), mat_platform)

	# Small colored markers give the prototype scale and orientation.
	_make_platform("MarkerNorth", Vector3(0, 0.02, -15.0), Vector3(0.35, 0.08, 3.0), mat_accent, false)
	_make_platform("MarkerWest", Vector3(-15.0, 0.02, 0), Vector3(3.0, 0.08, 0.35), mat_accent, false)
	_make_platform("MarkerEast", Vector3(15.0, 0.02, 0), Vector3(3.0, 0.08, 0.35), mat_accent, false)

	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0, 0.5, 9.0)
	add_child(spawn)

func _make_platform(label: String, pos: Vector3, dimensions: Vector3, material: Material, collision_enabled: bool = true) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh_instance)

	if collision_enabled:
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape"
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)

func _make_clouds() -> void:
	# Lightweight stylized cloud puffs, placed far beyond the playable area.
	var cloud_groups := [
		Vector3(-24, 17, -28), Vector3(4, 20, -34), Vector3(29, 16, -22),
		Vector3(-32, 19, 4), Vector3(32, 21, 9), Vector3(-18, 18, 29),
		Vector3(17, 19, 30)
	]
	for i in range(cloud_groups.size()):
		var center: Vector3 = cloud_groups[i]
		var cloud := Node3D.new()
		cloud.name = "Cloud_%02d" % i
		cloud.position = center
		add_child(cloud)
		var puff_data := [
			[Vector3(-1.8, 0.0, 0.0), Vector3(2.8, 1.1, 1.5)],
			[Vector3(0.0, 0.45, 0.0), Vector3(3.5, 1.5, 1.8)],
			[Vector3(1.9, 0.05, 0.1), Vector3(2.6, 1.0, 1.4)],
			[Vector3(0.5, -0.25, 0.7), Vector3(3.0, 0.9, 1.4)]
		]
		for puff in puff_data:
			var puff_mesh := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			sphere.radial_segments = 12
			sphere.rings = 6
			puff_mesh.mesh = sphere
			puff_mesh.position = puff[0]
			puff_mesh.scale = puff[1]
			puff_mesh.material_override = mat_cloud
			puff_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff_mesh)

func _make_preview_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "MapPreviewCamera"
	camera.position = Vector3(18.0, 15.5, 22.0)
	camera.fov = 62.0
	camera.near = 0.1
	camera.far = 250.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.current = true
