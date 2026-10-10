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

@onready var anchor: Node3D = $CharacterAnchor
@onready var camera: Camera3D = $Camera3D

var yaw: float = 0.0
var pitch: float = -0.10
var target_yaw: float = 0.0
var target_pitch: float = -0.10
var initialized: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch -= event.relative.y * mouse_sensitivity
		target_pitch = clamp(
			target_pitch,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)

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
