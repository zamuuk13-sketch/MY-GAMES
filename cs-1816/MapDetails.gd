extends Node3D
## Adds low-cost desert materials and set dressing to the CS-1816 blockout.
## Kept procedural so the map stays lightweight and easy to edit.

var sand_mat: StandardMaterial3D
var stone_mat: StandardMaterial3D
var pale_stone_mat: StandardMaterial3D
var dark_stone_mat: StandardMaterial3D
var wood_mat: StandardMaterial3D
var metal_mat: StandardMaterial3D
var paint_a_mat: StandardMaterial3D
var paint_b_mat: StandardMaterial3D
var dark_mat: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_style_existing_geometry()
	_add_spawn_details()
	_add_mid_details()
	_add_sites()
	_add_stairs()
	_add_desert_props()

func _make_materials() -> void:
	sand_mat = _material(Color("#c9a66b"), 1.0)
	stone_mat = _material(Color("#b68d58"), 0.95)
	pale_stone_mat = _material(Color("#d4b783"), 0.92)
	dark_stone_mat = _material(Color("#80613f"), 1.0)
	wood_mat = _material(Color("#79502f"), 0.92)
	metal_mat = _material(Color("#54534e"), 0.72, 0.25)
	paint_a_mat = _material(Color("#d8a83e"), 0.9)
	paint_b_mat = _material(Color("#e5e0d0"), 0.9)
	dark_mat = _material(Color("#282a29"), 0.9)

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	mat.albedo_texture = texture
	return mat

func _style_existing_geometry() -> void:
	var ground := get_parent().get_node_or_null("Ground")
	if ground is CSGBox3D:
		ground.material = sand_mat
	for node in get_parent().find_children("*", "CSGBox3D", true, false):
		if node.name.contains("Cover"):
			node.material = wood_mat
		elif node.name.contains("Platform"):
			node.material = pale_stone_mat
		else:
			node.material = stone_mat
	if get_parent().has_node("WorldEnvironment"):
		var env_node: WorldEnvironment = get_parent().get_node("WorldEnvironment")
		if env_node.environment:
			env_node.environment.ambient_light_color = Color("#e4c99c")

func _add_spawn_details() -> void:
	# Stacked masonry and low wooden cover at the western spawn.
	_box("SpawnBlockA", Vector3(-37, 0.65, -5), Vector3(3.2, 1.3, 1.2), stone_mat, true)
	_box("SpawnBlockB", Vector3(-33, 0.45, 5), Vector3(2.2, 0.9, 1.1), wood_mat, true)
	_box("SpawnCrateTop", Vector3(-33, 1.15, 5), Vector3(1.7, 0.12, 0.9), pale_stone_mat, false)
	_label("WESTERN DEPOT", Vector3(-39, 3.7, -10), 26, Color("#f3dfb4"))

func _add_mid_details() -> void:
	# Raised curbs, broken stone blocks, and route arrows make the middle readable.
	_box("MidCurbNorth", Vector3(-7, 0.15, -8.5), Vector3(12, 0.3, 0.45), dark_stone_mat, true)
	_box("MidCurbSouth", Vector3(-7, 0.15, 8.5), Vector3(12, 0.3, 0.45), dark_stone_mat, true)
	_box("MidBrokenWall1", Vector3(-7, 0.8, -3.5), Vector3(2.6, 1.6, 1.1), pale_stone_mat, true)
	_box("MidBrokenWall2", Vector3(5, 0.55, 4.5), Vector3(2.2, 1.1, 1.0), stone_mat, true)
	_label("MID", Vector3(-1.0, 3.6, -10.3), 34, Color("#f5dfb2"))

func _add_sites() -> void:
	# Painted floor borders and center symbols; these are visual markings, not bomb logic yet.
	_site_paint("A", Vector3(27, 0.27, -7), paint_a_mat)
	_site_paint("B", Vector3(27, 0.27, 7), paint_b_mat)
	_label("A  /  PLANT ZONE", Vector3(27, 0.42, -7), 22, Color("#f2c85f"))
	_label("B  /  PLANT ZONE", Vector3(27, 0.42, 7), 22, Color("#f4eee0"))
	# Industrial crates, with visible bands.
	for i in range(3):
		var z := -10.0 + float(i) * 2.0
		_box("A_Crate_%d" % i, Vector3(33.0, 0.9, z), Vector3(1.5, 1.8, 1.5), wood_mat, true)
		_box("A_CrateBand_%d" % i, Vector3(32.22, 0.9, z), Vector3(0.06, 1.65, 1.55), metal_mat, false)
	for i in range(2):
		var z := 6.0 + float(i) * 2.1
		_box("B_Crate_%d" % i, Vector3(20.5, 0.8, z), Vector3(1.5, 1.6, 1.5), wood_mat, true)
		_box("B_CrateBand_%d" % i, Vector3(19.72, 0.8, z), Vector3(0.06, 1.45, 1.55), metal_mat, false)

func _site_paint(site: String, center: Vector3, mat: Material) -> void:
	# Four flat stripes form a clear painted rectangle around the planting area.
	var w := 5.6
	var d := 3.6
	_box(site + "_PaintFront", center + Vector3(0, 0, -d * 0.5), Vector3(w, 0.025, 0.12), mat, false)
	_box(site + "_PaintBack", center + Vector3(0, 0, d * 0.5), Vector3(w, 0.025, 0.12), mat, false)
	_box(site + "_PaintLeft", center + Vector3(-w * 0.5, 0, 0), Vector3(0.12, 0.025, d), mat, false)
	_box(site + "_PaintRight", center + Vector3(w * 0.5, 0, 0), Vector3(0.12, 0.025, d), mat, false)
	_box(site + "_PaintCenter", center + Vector3(0, 0.018, 0), Vector3(0.7, 0.03, 0.7), mat, false)

func _add_stairs() -> void:
	# Two compact stair runs to elevated defensive ledges.
	for i in range(6):
		var h := 0.22 * float(i + 1)
		_box("NorthStair_%d" % i, Vector3(8.0 + float(i) * 0.85, h * 0.5, -24.0), Vector3(0.9, h, 2.4), pale_stone_mat, true)
		_box("SouthStair_%d" % i, Vector3(8.0 + float(i) * 0.85, h * 0.5, 24.0), Vector3(0.9, h, 2.4), pale_stone_mat, true)
	_box("NorthLanding", Vector3(14.0, 1.35, -24.0), Vector3(3.0, 0.3, 3.2), stone_mat, true)
	_box("SouthLanding", Vector3(14.0, 1.35, 24.0), Vector3(3.0, 0.3, 3.2), stone_mat, true)

func _add_desert_props() -> void:
	# Simple wall-mounted lamps and metal pipes for an industrial desert outpost.
	for x in [-29.0, -17.0, 3.0, 17.0, 35.0]:
		_box("WallLampMount_%d" % int(x), Vector3(x, 3.25, -11.0), Vector3(0.35, 0.22, 0.3), metal_mat, false)
		_box("WallLamp_%d" % int(x), Vector3(x, 3.05, -10.8), Vector3(0.48, 0.12, 0.42), paint_a_mat, false)
	_box("PipeNorth", Vector3(1.0, 0.35, -27.0), Vector3(20.0, 0.25, 0.25), metal_mat, false)
	_box("PipeSouth", Vector3(1.0, 0.35, 27.0), Vector3(20.0, 0.25, 0.25), metal_mat, false)
	# Sandstone building faces, dark windows and lintels.
	_building_face("OldWorkshop", Vector3(-20, 0, -29), Vector3(12, 6, 1.2))
	_building_face("SouthMarket", Vector3(-18, 0, 29), Vector3(14, 5.2, 1.2))
	_box("AntennaPole", Vector3(37, 3.4, 1), Vector3(0.16, 6.8, 0.16), metal_mat, true)
	_box("AntennaCrossbar", Vector3(37, 5.7, 1), Vector3(1.8, 0.12, 0.12), metal_mat, false)

func _building_face(label: String, center: Vector3, size: Vector3) -> void:
	_box(label + "_Facade", center + Vector3(0, size.y * 0.5, 0), size, stone_mat, true)
	for i in range(3):
		var wx := center.x - size.x * 0.28 + float(i) * size.x * 0.28
		_box(label + "_Window_%d" % i, Vector3(wx, center.y + 2.5, center.z - 0.64), Vector3(1.25, 1.1, 0.08), dark_mat, false)
		_box(label + "_Lintel_%d" % i, Vector3(wx, center.y + 3.12, center.z - 0.7), Vector3(1.55, 0.16, 0.16), pale_stone_mat, false)
	_label(label.to_upper(), Vector3(center.x, center.y + size.y + 0.3, center.z - 0.8), 20, Color("#f4dfb7"))

func _box(label: String, pos: Vector3, size: Vector3, mat: Material, collision: bool) -> void:
	var root: Node3D
	if collision:
		var body := StaticBody3D.new()
		body.name = label
		root = body
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	else:
		root = Node3D.new()
		root.name = label
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	root.add_child(mesh_instance)
	root.position = pos
	add_child(root)

func _label(value: String, pos: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = font_size
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(label)
