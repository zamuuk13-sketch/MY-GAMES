extends Control

@export var preview_mode: bool = false

var settings := {
	"color": Color(0.35, 1.0, 0.38, 1.0),
	"size": 8.0,
	"gap": 5.0,
	"thickness": 2.0,
	"dot": false,
	"outline": true,
	"static": true,
	"opacity": 1.0
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not preview_mode:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_settings()
	queue_redraw()

func _process(_delta: float) -> void:
	if not preview_mode and not bool(settings.get("static", true)):
		queue_redraw()

func apply_settings(values: Dictionary) -> void:
	for key in values:
		settings[key] = values[key]
	queue_redraw()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://cs1816_settings.cfg") == OK:
		for key in settings.keys():
			var value = cfg.get_value("crosshair", key, settings[key])
			if key == "color" and value is String:
				value = Color.from_string(value, settings[key])
			settings[key] = value

func _draw() -> void:
	var center := size / 2.0
	if preview_mode:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#20262d"), true)
	var cross_color: Color = settings.get("color", Color.GREEN)
	cross_color.a = float(settings.get("opacity", 1.0))
	var arm_size := float(settings.get("size", 8.0))
	var gap := float(settings.get("gap", 5.0))
	var thickness := float(settings.get("thickness", 2.0))
	if not bool(settings.get("static", true)) and not preview_mode:
		var movement := Vector2(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"), Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")).length()
		gap += movement * 3.0
	if bool(settings.get("outline", true)):
		var outline_color := Color(0.02, 0.02, 0.02, cross_color.a)
		_draw_cross(center, arm_size, gap, thickness + 2.0, outline_color)
	_draw_cross(center, arm_size, gap, thickness, cross_color)
	if bool(settings.get("dot", false)):
		if bool(settings.get("outline", true)):
			draw_circle(center, maxf(2.0, thickness * 1.1), Color(0.02, 0.02, 0.02, cross_color.a))
		draw_circle(center, maxf(1.0, thickness * 0.45), cross_color)

func _draw_cross(center: Vector2, arm_size: float, gap: float, thickness: float, color: Color) -> void:
	var half := thickness / 2.0
	draw_rect(Rect2(center.x - half, center.y - gap - arm_size, thickness, arm_size), color, true)
	draw_rect(Rect2(center.x - half, center.y + gap, thickness, arm_size), color, true)
	draw_rect(Rect2(center.x - gap - arm_size, center.y - half, arm_size, thickness), color, true)
	draw_rect(Rect2(center.x + gap, center.y - half, arm_size, thickness), color, true)
