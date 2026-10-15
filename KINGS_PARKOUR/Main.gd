extends Node2D

const PLAYER_SIZE := Vector2(34, 52)
const GRAVITY := 1500.0
const RUN_SPEED := 360.0
const JUMP_SPEED := -610.0

var player: CharacterBody2D
var camera: Camera2D
var status_label: Label
var finish_x := 0.0
var respawn_point := Vector2(100, 480)

func _ready() -> void:
	_build_background()
	_build_level()
	_build_player()
	_build_hud()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0b1228")
	bg.position = Vector2(-2000, -1500)
	bg.size = Vector2(9000, 3000)
	bg.z_index = -100
	add_child(bg)

	# Decorative skyline in the distance.
	for i in range(30):
		var building := ColorRect.new()
		var h := 100.0 + float((i * 47) % 190)
		building.color = Color("#111d3b")
		building.position = Vector2(i * 260.0 - 100.0, 600.0 - h)
		building.size = Vector2(130.0, h)
		building.z_index = -50
		add_child(building)

func _build_level() -> void:
	_add_platform(Vector2(300, 620), Vector2(700, 80), Color("#263b5e"))
	_add_platform(Vector2(850, 530), Vector2(180, 28), Color("#19c6b4"))
	_add_platform(Vector2(1110, 450), Vector2(170, 28), Color("#19c6b4"))
	_add_platform(Vector2(1370, 370), Vector2(170, 28), Color("#19c6b4"))
	_add_platform(Vector2(1630, 470), Vector2(190, 28), Color("#ffb84d"))
	_add_platform(Vector2(1930, 390), Vector2(170, 28), Color("#19c6b4"))
	_add_platform(Vector2(2200, 310), Vector2(180, 28), Color("#19c6b4"))
	_add_platform(Vector2(2480, 430), Vector2(240, 28), Color("#ffb84d"))
	_add_platform(Vector2(2810, 350), Vector2(190, 28), Color("#19c6b4"))
	_add_platform(Vector2(3140, 270), Vector2(240, 28), Color("#19c6b4"))
	_add_platform(Vector2(3510, 500), Vector2(650, 80), Color("#263b5e"))
	finish_x = 3750.0
	_add_finish_flag(Vector2(finish_x, 430))

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

	var body := ColorRect.new()
	body.name = "Visual"
	body.color = Color("#f4f7ff")
	body.size = PLAYER_SIZE
	body.position = -PLAYER_SIZE / 2.0
	player.add_child(body)

	var visor := ColorRect.new()
	visor.color = Color("#19c6b4")
	visor.size = Vector2(22, 8)
	visor.position = Vector2(-11, -15)
	player.add_child(visor)

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

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction := Input.get_axis("move_left", "move_right")
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

	if player.position.x >= finish_x - 30:
		status_label.text = "VOCÊ VENCEU! KING DO PARKOUR!  —  Continue correndo para explorar."
