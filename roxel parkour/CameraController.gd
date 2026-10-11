extends Node3D
## Roxel Parkour — smooth, player-mounted third-person camera with restrained look limits.

@export var mouse_sensitivity: float = 0.0020
@export var rotation_smoothness: float = 12.0
@export_range(60.0, 150.0, 5.0) var horizontal_limit_degrees: float = 105.0
@export_range(15.0, 60.0, 1.0) var look_up_limit_degrees: float = 42.0
@export_range(15.0, 60.0, 1.0) var look_down_limit_degrees: float = 38.0
@export var camera_distance: float = 3.4

@export_group("Motion blur")
@export_range(0.0, 0.08, 0.002) var max_blur_uv: float = 0.025
@export_range(1.0, 30.0, 0.5) var blur_fade_speed: float = 12.0
@export_range(0.0, 1.0, 0.05) var blur_intensity: float = 0.65

@onready var anchor: CharacterBody3D = get_parent() as CharacterBody3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var blur_overlay: ColorRect = get_node_or_null("../../MotionBlurLayer/BlurOverlay")

# World yaw is read by PlayerController for camera-relative movement.
var yaw: float = 0.0
var yaw_offset: float = 0.0
var target_yaw_offset: float = 0.0
var pitch: float = 0.0
var target_pitch: float = 0.0
var blur_vector: Vector2 = Vector2.ZERO
var blur_level: float = 0.0


func _ready() -> void:
	camera.current = true
	spring_arm.spring_length = camera_distance
	if anchor != null:
		# Prevent the camera arm from colliding with the player's own physics body.
		spring_arm.add_excluded_object(anchor.get_rid())
		yaw = anchor.global_rotation.y
	rotation = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if blur_overlay != null and blur_overlay.material is ShaderMaterial:
		blur_overlay.material.set_shader_parameter("blur_amount", 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw_offset -= event.relative.x * mouse_sensitivity
		var horizontal_limit := deg_to_rad(horizontal_limit_degrees)
		target_yaw_offset = clampf(target_yaw_offset, -horizontal_limit, horizontal_limit)

		# A small, deliberate vertical range: look up/down without tipping the view over.
		target_pitch -= event.relative.y * mouse_sensitivity
		target_pitch = clampf(
			target_pitch,
			deg_to_rad(-look_down_limit_degrees),
			deg_to_rad(look_up_limit_degrees)
		)

		var viewport_size := get_viewport().get_visible_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			blur_vector = Vector2(-event.relative.x / viewport_size.x, -event.relative.y / viewport_size.y) * max_blur_uv
			blur_level = minf(blur_intensity, blur_level + event.relative.length() * 0.0018)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_TAB:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-rotation_smoothness * delta)
	yaw_offset = lerpf(yaw_offset, target_yaw_offset, weight)
	pitch = lerpf(pitch, target_pitch, weight)

	# Keep the camera's horizontal range relative to the character, not to the map.
	if anchor != null:
		yaw = anchor.global_rotation.y + yaw_offset
	rotation.y = yaw_offset
	rotation.x = pitch

	blur_level = move_toward(blur_level, 0.0, blur_fade_speed * delta)
	if blur_overlay != null and blur_overlay.material is ShaderMaterial:
		blur_overlay.material.set_shader_parameter("blur_vector", blur_vector)
		blur_overlay.material.set_shader_parameter("blur_amount", blur_level)
