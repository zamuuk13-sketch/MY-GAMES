extends CharacterBody3D
## Standard third-person controller: camera-relative WASD, smooth turning and jumping.

@export var walk_speed: float = 6.0
@export var run_speed: float = 10.5
@export var ground_acceleration: float = 28.0
@export var air_acceleration: float = 8.0
@export var jump_velocity: float = 5.8
@export var turn_smoothness: float = 12.0

@onready var camera_rig: Node3D = $CameraRig

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var facing_yaw: float = 0.0


func _ready() -> void:
	facing_yaw = rotation.y
	call_deferred("_fit_character_model")


func _fit_character_model() -> void:
	var model := get_node_or_null("Model") as Node3D
	if model == null:
		push_warning("Roxel Parkour: node Model was not found under Player.")
		return
	model.visible = true
	_set_tree_visible(model)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model, meshes)
	print("Roxel Parkour: FBX descendants = ", model.get_child_count(), "; mesh nodes found = ", meshes.size())
	if meshes.is_empty():
		push_error("Roxel Parkour: personagem.fbx loaded without MeshInstance3D nodes. Reimport the FBX.")
		return

	var bounds := AABB()
	var has_bounds := false
	var model_inverse := model.global_transform.affine_inverse()
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		var mesh_transform := model_inverse * mesh_instance.global_transform
		var mesh_bounds := mesh_instance.get_aabb() * mesh_transform
		if not has_bounds:
			bounds = mesh_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(mesh_bounds)

	if not has_bounds or bounds.size.y <= 0.001:
		push_error("Roxel Parkour: personagem.fbx has no usable mesh bounds.")
		return

	var fit_scale := 1.7 / bounds.size.y
	model.scale = Vector3.ONE * fit_scale
	var center_x := bounds.position.x + bounds.size.x * 0.5
	var center_z := bounds.position.z + bounds.size.z * 0.5
	model.position = Vector3(-center_x * fit_scale, -bounds.position.y * fit_scale, -center_z * fit_scale)
	# This corrects the imported model's facing direction without rotating the physics body.
	model.rotation.y = PI


func _set_tree_visible(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visible = true
	for child in node.get_children():
		_set_tree_visible(child)


func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, result)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Use camera rig's independent world yaw, so turning the character cannot rotate
	# the movement reference and create a spinning/feedback loop.
	var horizontal := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var vertical := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var input_vector := Vector2(horizontal, vertical)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()

	var move_direction := Vector3.ZERO
	if input_vector.length_squared() > 0.001:
		var camera_yaw := camera_rig.global_rotation.y
		var forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw))
		var right := Vector3(cos(camera_yaw), 0.0, sin(camera_yaw))
		move_direction = (right * input_vector.x + forward * input_vector.y).normalized()

	var running := Input.is_key_pressed(KEY_SHIFT)
	var speed := run_speed if running else walk_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	var target_x := move_direction.x * speed
	var target_z := move_direction.z * speed
	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

	# Rotate toward the travel direction only; never spin from camera pitch or input changes.
	if move_direction.length_squared() > 0.001:
		var desired_yaw := atan2(-move_direction.x, -move_direction.z)
		var turn_weight := 1.0 - exp(-turn_smoothness * delta)
		facing_yaw = lerp_angle(facing_yaw, desired_yaw, turn_weight)
		rotation.y = facing_yaw

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
	move_and_slide()
