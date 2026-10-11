extends CharacterBody3D
## Responsive third-person controller. Animations intentionally remain disabled.

@export var walk_speed: float = 6.0
@export var run_speed: float = 10.5
@export var ground_acceleration: float = 30.0
@export var air_acceleration: float = 10.0
@export var jump_velocity: float = 5.8
@export var turn_smoothness: float = 10.0

@onready var camera: Camera3D = get_node("CameraRig/Camera3D")
@onready var camera_rig: Node3D = get_node("CameraRig")

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

	print("Roxel Parkour: imported FBX bounds = ", bounds)
	var target_height := 1.7
	var fit_scale := target_height / bounds.size.y
	model.scale = Vector3.ONE * fit_scale
	var bounds_center_x := bounds.position.x + bounds.size.x * 0.5
	var bounds_center_z := bounds.position.z + bounds.size.z * 0.5
	model.position = Vector3(
		-bounds_center_x * fit_scale,
		-bounds.position.y * fit_scale,
		-bounds_center_z * fit_scale
	)
	# The imported FBX faces the opposite local direction to Godot's -Z forward.
	# Rotate only the visual model; keep the physics body and movement axes consistent.
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

	var x_input := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var forward_input := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var input_vector := Vector2(x_input, forward_input)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	# Use the camera rig's yaw only, so looking up/down never weakens movement.
	var camera_yaw := float(camera_rig.get("yaw"))
	var move_forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw))
	var move_right := Vector3(cos(camera_yaw), 0.0, sin(camera_yaw))
	var move_direction := move_right * input_vector.x + move_forward * input_vector.y
	if move_direction.length() > 0.001:
		move_direction = move_direction.normalized()

	var running := Input.is_key_pressed(KEY_SHIFT)
	var desired_speed := run_speed if running else walk_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	var target_velocity := move_direction * desired_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if move_direction.length() > 0.1:
		var desired_yaw := atan2(-move_direction.x, -move_direction.z)
		var turn_weight := 1.0 - exp(-turn_smoothness * delta)
		facing_yaw = lerp_angle(facing_yaw, desired_yaw, turn_weight)
		rotation.y = facing_yaw

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	move_and_slide()
