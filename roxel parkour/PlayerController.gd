extends CharacterBody3D
## Basic Roxel Parkour player controller.
## This version intentionally does not load or play any animations yet.

@export var walk_speed: float = 4.2
@export var run_speed: float = 7.5
@export var ground_acceleration: float = 14.0
@export var air_acceleration: float = 4.0
@export var jump_velocity: float = 5.6
@export var turn_smoothness: float = 5.0

@onready var camera: Camera3D = get_node("../CameraRig/Camera3D")

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var facing_yaw: float = 0.0


func _ready() -> void:
	facing_yaw = rotation.y


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# WASD: diagonals are naturally normalized so W+A / W+D aren't faster.
	var x_input := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var z_input := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_vector := Vector2(x_input, z_input)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	# Movement follows the camera's horizontal direction.
	var camera_forward := -camera.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var move_direction := camera_right * input_vector.x + camera_forward * -input_vector.y
	move_direction.y = 0.0
	if move_direction.length() > 0.001:
		move_direction = move_direction.normalized()

	var running := Input.is_key_pressed(KEY_SHIFT)
	var desired_speed := run_speed if running else walk_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	var target_velocity := move_direction * desired_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	# Turn the whole player smoothly toward movement; backward-only movement
	# preserves the current facing direction for now.
	var backwards_only := Input.is_key_pressed(KEY_S) and not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_D)
	if move_direction.length() > 0.1 and not backwards_only:
		var desired_yaw := atan2(-move_direction.x, -move_direction.z)
		var turn_weight := 1.0 - exp(-turn_smoothness * delta)
		facing_yaw = lerp_angle(facing_yaw, desired_yaw, turn_weight)
		rotation.y = facing_yaw

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	move_and_slide()
