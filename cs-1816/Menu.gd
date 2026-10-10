extends Control

const GAME_SCENE = "res://Main.tscn"

var current_page = "main"
var settings = {
	"crosshair_color": Color(0.35, 1.0, 0.38, 1.0),
	"crosshair_size": 8.0,
	"crosshair_gap": 5.0
}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_settings()
	_show_main_menu()

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://cs1816_settings.cfg") == OK:
		settings["crosshair_color"] = cfg.get_value("crosshair", "color", settings["crosshair_color"])
		settings["crosshair_size"] = float(cfg.get_value("crosshair", "size", settings["crosshair_size"]))
		settings["crosshair_gap"] = float(cfg.get_value("crosshair", "gap", settings["crosshair_gap"]))
		if settings["crosshair_color"] is String:
			settings["crosshair_color"] = Color.from_string(settings["crosshair_color"], Color.GREEN)

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.load("user://cs1816_settings.cfg")
	cfg.set_value("crosshair", "color", settings["crosshair_color"].to_html(false))
	cfg.set_value("crosshair", "size", settings["crosshair_size"])
	cfg.set_value("crosshair", "gap", settings["crosshair_gap"])
	var err = cfg.save("user://cs1816_settings.cfg")
	if err != OK:
		push_warning("CS-1816: não foi possível salvar as configurações.")

func _clear_page():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _make_background():
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#11161b")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _make_root():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	return column

func _make_label(parent, text_value, font_size = 18, color_value = Color("#f3f5f7")):
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color_value)
	parent.add_child(label)
	return label

func _make_button(parent, caption, callback):
	var button = Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(300, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_main_menu():
	current_page = "main"
	_clear_page()
	_make_background()
	var column = _make_root()
	_make_label(column, "CS-1816", 38)
	_make_label(column, "FPS TÁTICO  /  PRÉ-ALPHA", 16, Color("#a5afb9"))
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 12
	column.add_child(spacer)
	_make_button(column, "JOGAR", _show_team_select)
	_make_button(column, "CONFIGURAÇÕES", _show_settings)
	_make_button(column, "SAIR", _quit_game)
	_make_label(column, "Menu de inicialização", 14, Color("#84909b"))
	print("CS-1816: menu principal carregado.")

func _show_team_select():
	current_page = "team"
	_clear_page()
	_make_background()
	var column = _make_root()
	_make_label(column, "ESCOLHA SUA EQUIPE", 30)
	_make_label(column, "A equipe determina o ponto de spawn e o objetivo.", 16, Color("#a5afb9"))
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 16
	column.add_child(spacer)
	_make_button(column, "TERRORISTAS  —  ATAQUE", func(): _choose_team("terrorists"))
	_make_button(column, "CONTRA-TERRORISTAS  —  DEFESA", func(): _choose_team("counter_terrorists"))
	_make_button(column, "VOLTAR", _show_main_menu)

func _choose_team(team_id):
	get_tree().root.set_meta("cs1816_team", team_id)
	_save_settings()
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("CS-1816: erro ao abrir Main.tscn: " + str(error))
		_show_team_select()

func _show_settings():
	current_page = "settings"
	_clear_page()
	_make_background()
	var column = _make_root()
	_make_label(column, "CONFIGURAÇÕES", 30)
	_make_label(column, "PERSONALIZAÇÃO DA MIRA", 16, Color("#7fe58b"))
	_make_label(column, "Cor da mira", 15)
	var color_button = ColorPickerButton.new()
	color_button.color = settings["crosshair_color"]
	color_button.custom_minimum_size = Vector2(300, 42)
	color_button.color_changed.connect(_on_crosshair_color_changed)
	column.add_child(color_button)
	_make_label(column, "Tamanho da mira", 15)
	var size_slider = HSlider.new()
	size_slider.min_value = 2
	size_slider.max_value = 20
	size_slider.step = 1
	size_slider.value = settings["crosshair_size"]
	size_slider.custom_minimum_size.x = 320
	size_slider.value_changed.connect(_on_crosshair_size_changed)
	column.add_child(size_slider)
	_make_label(column, "Espaçamento da mira", 15)
	var gap_slider = HSlider.new()
	gap_slider.min_value = 0
	gap_slider.max_value = 16
	gap_slider.step = 1
	gap_slider.value = settings["crosshair_gap"]
	gap_slider.custom_minimum_size.x = 320
	gap_slider.value_changed.connect(_on_crosshair_gap_changed)
	column.add_child(gap_slider)
	_make_button(column, "SALVAR CONFIGURAÇÕES", _save_settings)
	_make_button(column, "VOLTAR AO MENU", _show_main_menu)

func _on_crosshair_color_changed(value):
	settings["crosshair_color"] = value
	_save_settings()

func _on_crosshair_size_changed(value):
	settings["crosshair_size"] = value
	_save_settings()

func _on_crosshair_gap_changed(value):
	settings["crosshair_gap"] = value
	_save_settings()

func _quit_game():
	get_tree().quit()
