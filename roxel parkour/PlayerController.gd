extends CharacterBody3D
## Roxel Parkour player movement and Mixamo animation loader.
## WASD movement is camera-relative; turning is eased for a natural parkour feel.

@export var walk_speed: float = 4.2
@export var run_speed: float = 7.5
@export var ground_acceleration: float = 14.0
@export var air_acceleration: float = 4.0
@export var jump_velocity: float = 5.6
@export var turn_smoothness: float = 5.0
@export var animation_fade: float = 0.18

@onready var model: Node3D = $Model
@onready var camera: Camera3D = get_node("../CameraRig/Camera3D")

var animation_player: AnimationPlayer
var animation_names: Dictionary = {}
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var jump_animation_active: bool = false
var facing_yaw: float = 0.0


func _ready() -> void:
	animation_player = _find_animation_player(model)
	_load_mixamo_animation("Idle", "res://assets/Breathing Idle.fbx", true)
	_load_mixamo_animation("Walk", "res://assets/Walking.fbx", true)
	_load_mixamo_animation("Run", "res://assets/Running.fbx", true)
	_load_mixamo_animation("Backwards", "res://assets/Walking Backwards.fbx", true)
	_load_mixamo_animation("Jump", "res://assets/Jump.fbx", false)
	_load_mixamo_animation("RunJump", "res://assets/Running Jump.fbx", false)

	if animation_player != null:
		_play_animation("Idle")
	facing_yaw = rotation.y


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		jump_animation_active = false

	var x_input := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var z_input := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_vector := Vector2(x_input, z_input)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var camera_forward := -camera.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var move_direction := (camera_right * input_vector.x) + (camera_forward * -input_vector.y)
	move_direction.y = 0.0
	if move_direction.length() > 0.001:
		move_direction = move_direction.normalized()

	var running := Input.is_key_pressed(KEY_SHIFT)
	var desired_speed := run_speed if running else walk_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	var target_horizontal_velocity := move_direction * desired_speed
	velocity.x = move_toward(velocity.x, target_horizontal_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_horizontal_velocity.z, acceleration * delta)

	# When walking backwards only, keep facing forward and use the backwards cycle.
	var backwards_only := Input.is_key_pressed(KEY_S) and not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_D)
	if move_direction.length() > 0.1 and not backwards_only:
		var desired_yaw := atan2(-move_direction.x, -move_direction.z)
		var turn_weight := 1.0 - exp(-turn_smoothness * delta)
		facing_yaw = lerp_angle(facing_yaw, desired_yaw, turn_weight)
		rotation.y = facing_yaw

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
		jump_animation_active = true
		_play_animation("RunJump" if running and move_direction.length() > 0.1 else "Jump")

	move_and_slide()
	_update_animation(running, move_direction.length() > 0.1, backwards_only)


func _update_animation(running: bool, moving: bool, backwards_only: bool) -> void:
	if jump_animation_active and not is_on_floor():
		return
	if not moving:
		_play_animation("Idle")
	elif backwards_only:
		_play_animation("Backwards")
	elif running:
		_play_animation("Run")
	else:
		_play_animation("Walk")


func _play_animation(key: String) -> void:
	if animation_player == null or not animation_names.has(key):
		return
	var animation_name: StringName = animation_names[key]
	if animation_player.current_animation == animation_name and animation_player.is_playing():
		return
	animation_player.play(animation_name, animation_fade)


func _load_mixamo_animation(key: String, path: String, loop: bool) -> void:
	if animation_player == null or not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Could not load animation scene: " + path)
		return
	var source_root := packed.instantiate()
	var source_player := _find_animation_player(source_root)
	if source_player == null:
		source_root.queue_free()
		push_warning("No AnimationPlayer found in: " + path)
		return

	var chosen_animation: Animation
	for candidate in source_player.get_animation_list():
		var animation := source_player.get_animation(candidate)
		if animation != null and candidate != &"RESET" and animation.length > 0.0:
			chosen_animation = animation.duplicate(true)
			break
	if chosen_animation != null:
		chosen_animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		var library_name := &"roxel_moves"
		var library: AnimationLibrary
		if animation_player.has_animation_library(library_name):
			library = animation_player.get_animation_library(library_name)
		else:
			library = AnimationLibrary.new()
			animation_player.add_animation_library(library_name, library)
		var safe_name := StringName(key)
		if library.has_animation(safe_name):
			library.remove_animation(safe_name)
		var error := library.add_animation(safe_name, chosen_animation)
		if error == OK:
			animation_names[key] = String(library_name) + "/" + String(safe_name)
		else:
			push_warning("Could not register animation " + key + ": " + str(error))
	source_root.free()


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
