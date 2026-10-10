extends Node3D
## Roxel Parkour — third-person camera controller.
## CharacterAnchor is only a placeholder; no character is instantiated.

@export var mouse_sensitivity: float = 0.0022
@export var follow_smoothness: float = 7.0
@export var rotation_smoothness: float = 8.0
@export var camera_distance: float = 6.2
@export var camera_height: float = 2.15
@export var camera_right_offset: float = 2.0
@export var look_ahead: float = 1.4
@export var min_pitch_degrees: float = -35.0
@export var max_pitch_degrees: float = 22.0

@export_group("Motion blur")
@export_range(0.0, 0.08, 0.002) var max_blur_uv: float = 0.025
@export_range(1.0, 30.0, 0.5) var blur_fade_speed: float = 12.0
@export_range(0.0, 1.0, 0.05) var blur_intensity: float = 0.65

@onready var anchor: Node3D = $CharacterAnchor
@onready var camera: Camera3D = $Camera3D
@onready var blur_overlay: ColorRect = get_node_or_null("../MotionBlurLayer/BlurOverlay")

var yaw: float = 0.0
var pitch: float = -0.10
var target_yaw: float = 0.0
var target_pitch: float = -0.10
var initialized: bool = false
var blur_vector: Vector2 = Vector2.ZERO
var blur_level: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	if blur_overlay != null and blur_overlay.material is ShaderMaterial:
		blur_overlay.material.set_shader_parameter("blur_amount", 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch -= event.relative.y * mouse_sensitivity
		target_pitch = clamp(
			target_pitch,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)

		var viewport_size := get_viewport().get_visible_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			# A subtle screen-space trail follows camera rotation, then quickly fades.
			blur_vector = Vector2(
				-event.relative.x / viewport_size.x,
				-event.relative.y / viewport_size.y
			) * max_blur_uv
			blur_level = min(blur_intensity, blur_level + event.relative.length() * 0.0018)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_TAB:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	# Exponential smoothing gives the camera a little physical weight.
	var rotation_weight := 1.0 - exp(-rotation_smoothness * delta)
	yaw = lerp_angle(yaw, target_yaw, rotation_weight)
	pitch = lerp(pitch, target_pitch, rotation_weight)

	var anchor_position: Vector3 = anchor.global_position
	var yaw_basis := Basis(Vector3.UP, yaw)
	var horizontal_back := yaw_basis * Vector3(0.0, 0.0, camera_distance)
	var right := yaw_basis * Vector3.RIGHT * camera_right_offset
	var desired_position := anchor_position + horizontal_back + right
	desired_position.y += camera_height + sin(pitch) * camera_distance * 0.25

	if not initialized:
		camera.global_position = desired_position
		initialized = true
	else:
		var follow_weight := 1.0 - exp(-follow_smoothness * delta)
		camera.global_position = camera.global_position.lerp(desired_position, follow_weight)

	var aim_point := anchor_position + Vector3(0.0, 1.25, 0.0)
	aim_point += yaw_basis * Vector3(0.0, 0.0, -look_ahead)
	aim_point.y += sin(pitch) * 2.0
	camera.look_at(aim_point, Vector3.UP)

	blur_level = move_toward(blur_level, 0.0, blur_fade_speed * delta)
	if blur_overlay != null and blur_overlay.material is ShaderMaterial:
		blur_overlay.material.set_shader_parameter("blur_vector", blur_vector)
		blur_overlay.material.set_shader_parameter("blur_amount", blur_level)
