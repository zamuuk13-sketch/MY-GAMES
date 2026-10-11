extends CharacterBody3D
class_name SigmaPlayerController

const CHARACTER_PATH := "res://assets/players ou personagens/personagem.fbx"
const IDLE_PATH := "res://assets/animações/Breathing Idle.fbx"

@export var walk_speed := 4.8
@export var sprint_speed := 7.2
@export var ground_acceleration := 12.0
@export var ground_deceleration := 15.0
@export var air_acceleration := 3.5
@export var jump_velocity := 4.8
@export var mouse_sensitivity := 0.0018
@export var camera_smoothness := 11.0
@export var turn_smoothness := 8.0
@export var camera_distance := 3.8
@export var camera_height := 1.45

var visual: Node3D
var animation_player: AnimationPlayer
var camera_rig: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var blur_rect: ColorRect
var blur_material: ShaderMaterial

var camera_yaw := 0.0
var camera_pitch := -0.12
var camera_motion := Vector2.ZERO
var blur_amount := 0.0
var vertical_velocity := 0.0
var move_blend := Vector3.ZERO

func _ready() -> void:
	name = "Player"
	_setup_collision()
	_setup_character()
	_setup_camera()
	_setup_motion_blur()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_collision() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	var shape_node := CollisionShape3D.new()
	shape_node.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	shape_node.shape = capsule
	shape_node.position.y = 0.9
	add_child(shape_node)

func _setup_character() -> void:
	var packed := load(CHARACTER_PATH) as PackedScene
	if packed == null:
		push_error("Sigma Parkour: não foi possível importar personagem.fbx: " + CHARACTER_PATH)
		return
	visual = packed.instantiate() as Node3D
	if visual == null:
		push_error("Sigma Parkour: a cena importada do personagem não tem raiz Node3D.")
		return
	visual.name = "CharacterVisual"
	add_child(visual)
	# Muitos FBX do Mixamo olham para +Z; a rotação visual é corrigida sem inverter o movimento.
	visual.rotation.y = PI
	animation_player = _find_animation_player(visual)
	_link_idle_animation()

func _link_idle_animation() -> void:
	var idle_packed := load(IDLE_PATH) as PackedScene
	if idle_packed == null:
		push_warning("Sigma Parkour: Breathing Idle.fbx ainda não foi importado pelo Godot.")
		return
	var idle_root := idle_packed.instantiate()
	var source_player := _find_animation_player(idle_root)
	if source_player == null:
		push_warning("Sigma Parkour: o FBX Breathing Idle não expôs um AnimationPlayer importado.")
		idle_root.queue_free()
		return
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		visual.add_child(animation_player)
	var library_name := "sigma_idle"
	var library := AnimationLibrary.new()
	var idle_names: Array[StringName] = []
	for source_library_name in source_player.get_animation_library_list():
		var source_library: AnimationLibrary = source_player.get_animation_library(source_library_name)
		for animation_name in source_library.get_animation_list():
			var animation: Animation = source_library.get_animation(animation_name).duplicate(true)
			var unique_name := String(animation_name)
			if library.has_animation(unique_name):
				unique_name = String(source_library_name) + "_" + unique_name
			library.add_animation(unique_name, animation)
			if "idle" in unique_name.to_lower() or "breathing" in unique_name.to_lower():
				idle_names.append(StringName(unique_name))
	if library.get_animation_list().is_empty():
		push_warning("Sigma Parkour: nenhuma animação foi encontrada no FBX de idle.")
	else:
		if animation_player.has_animation_library(library_name):
			animation_player.remove_animation_library(library_name)
		animation_player.add_animation_library(library_name, library)
		var chosen := StringName(library.get_animation_list()[0])
		if not idle_names.is_empty():
			chosen = idle_names[0]
		animation_player.play(StringName(library_name + "/" + String(chosen)))
		animation_player.speed_scale = 1.0
	idle_root.free()

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _setup_camera() -> void:
	camera_rig = Node3D.new()
	camera_rig.name = "SmoothCameraRig"
	get_parent().add_child.call_deferred(camera_rig)
	camera_rig.position = global_position + Vector3(0.0, camera_height, 0.0)
	camera_rig.rotation.y = camera_yaw

	spring_arm = SpringArm3D.new()
	spring_arm.name = "CameraSpringArm"
	spring_arm.spring_length = camera_distance
	spring_arm.margin = 0.18
	spring_arm.collision_mask = 1
	camera_rig.add_child(spring_arm)

	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 76.0
	camera.near = 0.08
	camera.far = 180.0
	spring_arm.add_child(camera)
	camera.current = true

func _setup_motion_blur() -> void:
	var shader := load("res://CameraMotionBlur.gdshader") as Shader
	if shader == null:
		return
	blur_material = ShaderMaterial.new()
	blur_material.shader = shader
	blur_rect = ColorRect.new()
	blur_rect.name = "CameraMotionBlur"
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.material = blur_material
	var layer := CanvasLayer.new()
	layer.name = "MotionBlurLayer"
	layer.layer = 20
	layer.add_child(blur_rect)
	get_parent().add_child.call_deferred(layer)
	blur_material.set_shader_parameter("blur_direction", Vector2.ZERO)
	blur_material.set_shader_parameter("blur_strength", 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := (event as InputEventMouseMotion).relative
		camera_yaw -= motion.x * mouse_sensitivity
		camera_pitch -= motion.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-58.0), deg_to_rad(38.0))
		camera_motion = camera_motion.lerp(Vector2(-motion.x, -motion.y), 0.65)

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Also read physical WASD so keyboard layout changes won't invert the controls.
	var raw := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if raw.length_squared() > 1.0:
		raw = raw.normalized()
	elif raw.length_squared() < 0.001 and input_2d.length_squared() > 0.001:
		raw = input_2d

	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var desired := (right * raw.x + forward * -raw.y)
	if desired.length_squared() > 1.0:
		desired = desired.normalized()

	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	var target_velocity := desired * speed
	var accel := ground_acceleration if desired.length_squared() > 0.001 else ground_deceleration
	if not is_on_floor():
		accel = air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.15
		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_velocity

	move_and_slide()
	_update_facing(desired, delta)
	_update_camera(delta)
	_update_blur(delta)

func _update_facing(direction: Vector3, delta: float) -> void:
	if visual == null or direction.length_squared() < 0.015:
		return
	# Visual forward is corrected for the common +Z-facing FBX export.
	var target_yaw := atan2(-direction.x, -direction.z) + PI
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-turn_smoothness * delta))

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera_rig):
		return
	var target_position := global_position + Vector3(0.0, camera_height, 0.0)
	var follow_weight := 1.0 - exp(-camera_smoothness * delta)
	camera_rig.global_position = camera_rig.global_position.lerp(target_position, follow_weight)
	camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, camera_yaw, follow_weight)
	camera_rig.rotation.x = lerp_angle(camera_rig.rotation.x, camera_pitch, follow_weight)

func _update_blur(delta: float) -> void:
	if blur_material == null:
		return
	var angular_strength := clamp(camera_motion.length() / 32.0, 0.0, 1.0)
	blur_amount = lerp(blur_amount, angular_strength * 0.72, 1.0 - exp(-10.0 * delta))
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		var direction := Vector2(camera_motion.x / viewport_size.x, camera_motion.y / viewport_size.y)
		blur_material.set_shader_parameter("blur_direction", direction)
		blur_material.set_shader_parameter("blur_strength", blur_amount)
	camera_motion = camera_motion.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
