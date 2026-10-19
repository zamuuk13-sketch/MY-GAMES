extends Node2D

const PLAYER_SIZE := Vector2(34, 52)
const GRAVITY := 1500.0
const RUN_SPEED := 360.0
const JUMP_SPEED := -610.0

var player: CharacterBody2D
var camera: Camera2D
var status_label: Label
var finish_x := 999999.0
var respawn_point := Vector2(640, 480)

func _ready() -> void:
	_build_background()
	_build_level()
	_build_player()
	_build_hud()

func _build_background() -> void:
	# Detailed pixel-art rooftop scene; the artwork is authored at 320x180.
	var rooftop := preload("res://rooftop_start.tscn").instantiate()
	rooftop.scale = Vector2(4.0, 4.0)
	rooftop.z_index = -20
	add_child(rooftop)

func _build_level() -> void:
	# Invisible collision follows the artwork so the detailed pixel floor stays visible.
	var rooftop_floor := StaticBody2D.new()
	rooftop_floor.position = Vector2(640, 660)
	rooftop_floor.collision_layer = 1
	rooftop_floor.collision_mask = 1
	add_child(rooftop_floor)

	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(1280, 120)
	floor_collision.shape = floor_shape
	rooftop_floor.add_child(floor_collision)
	finish_x = 999999.0

func _add_platform(center: Vector2, dimensions: Vector2, tint: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	shape.shape = rectangle
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.color = tint
	visual.size = dimensions
	visual.position = -dimensions / 2.0
	body.add_child(visual)

	var top_line := ColorRect.new()
	top_line.color = Color("#e6fbff")
	top_line.size = Vector2(dimensions.x, 4)
	top_line.position = Vector2(-dimensions.x / 2.0, -dimensions.y / 2.0)
	body.add_child(top_line)

func _add_finish_flag(at: Vector2) -> void:
	var pole := ColorRect.new()
	pole.color = Color("#f3f6ff")
	pole.position = at + Vector2(0, -90)
	pole.size = Vector2(7, 115)
	add_child(pole)

	var flag := ColorRect.new()
	flag.color = Color("#ff4f81")
	flag.position = at + Vector2(7, -90)
	flag.size = Vector2(65, 34)
	add_child(flag)

	var label := Label.new()
	label.text = "FIM"
	label.position = at + Vector2(10, -87)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = respawn_point
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = PLAYER_SIZE
	collision.shape = shape
	player.add_child(collision)

	# 8-frame idle sprite animation, each cell is 48x64 pixels.
	var idle := Sprite2D.new()
	idle.name = "IdleSprite"
	idle.texture = load("res://idle_spritesheet.svg")
	idle.hframes = 8
	idle.vframes = 1
	idle.frame = 0
	idle.position = Vector2(0, -6)
	idle.z_index = 10
	idle.visible = true
	idle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(idle)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 4100
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)
	camera.make_current()

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var title := Label.new()
	title.text = "KINGS PARKOUR"
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#19c6b4"))
	hud.add_child(title)

	status_label = Label.new()
	status_label.text = "A/D ou ←/→: correr     ESPAÇO/W/↑: pular"
	status_label.position = Vector2(30, 62)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color("#e6ecff"))
	hud.add_child(status_label)

func _process(delta: float) -> void:
	if player == null:
		return
	var idle := player.get_node_or_null("IdleSprite") as Sprite2D
	if idle == null:
		return
	# Play the breathing/blinking idle only while the player is standing still.
	if absf(Input.get_axis("move_left", "move_right")) > 0.01:
		idle.frame = 0
		idle.set_meta("frame_clock", 0.0)
		return
	idle.set_meta("frame_clock", float(idle.get_meta("frame_clock", 0.0)) + delta)
	var clock := float(idle.get_meta("frame_clock"))
	if clock >= 0.12:
		idle.set_meta("frame_clock", fmod(clock, 0.12))
		idle.frame = (idle.frame + 1) % 8

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction := Input.get_axis("move_left", "move_right")
	var idle := player.get_node_or_null("IdleSprite") as Sprite2D
	if idle != null and absf(direction) > 0.01:
		idle.flip_h = direction < 0.0
	player.velocity.x = direction * RUN_SPEED

	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		player.velocity.y = JUMP_SPEED

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = JUMP_SPEED

	player.move_and_slide()

	if player.position.y > 950:
		player.position = respawn_point
		player.velocity = Vector2.ZERO

