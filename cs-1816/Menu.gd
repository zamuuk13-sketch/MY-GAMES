extends Control

const CROSSHAIR_SCRIPT = preload("res://CrosshairDisplay.gd")
const GAME_SCENE := "res://Main.tscn"

var page: Control
var preview: Control
var color_picker: OptionButton
var custom_color_button: ColorPickerButton
var size_slider: HSlider
var gap_slider: HSlider
var thickness_slider: HSlider
var opacity_slider: HSlider
var dot_toggle: CheckButton
var outline_toggle: CheckButton
var static_toggle: CheckButton
var status_label: Label
var profile_picker: OptionButton
var profile_name_input: LineEdit
var crosshair_values := {
	"color": Color(0.35, 1.0, 0.38, 1.0),
	"size": 8.0,
	"gap": 5.0,
	"thickness": 2.0,
	"dot": false,
	"outline": true,
	"static": true,
	"opacity": 1.0
}

const COLORS := {
	"Verde": "#59ff62",
	"Ciano": "#42e8ff",
	"Branco": "#ffffff",
	"Vermelho": "#ff4d5e",
	"Amarelo": "#ffe45c",
	"Roxo": "#c18aff",
	"Rosa": "#ff86d7"
}

func _ready() -> void:
	# Build the first frame immediately so the window never stays visually empty.
	visible = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_settings()
	_build_menu()
	print("CS-1816: menu initialized")

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://cs1816_settings.cfg") == OK:
		for key in crosshair_values.keys():
			var fallback = crosshair_values[key]
			var value = cfg.get_value("crosshair", key, fallback)
			if key == "color" and value is String:
				value = Color.from_string(value, fallback)
			crosshair_values[key] = value

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://cs1816_settings.cfg")
	for key in crosshair_values:
		var value = crosshair_values[key]
		if key == "color":
			value = value.to_html(false)
		cfg.set_value("crosshair", key, value)
	cfg.save("user://cs1816_settings.cfg")

func _build_menu() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.name = "MenuBackground"
	bg.color = Color("#11161b")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	add_child(margin)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	var brand := Label.new()
	brand.text = "CS-1816"
	brand.add_theme_font_size_override("font_size", 36)
	brand.add_theme_color_override("font_color", Color("#f3f5f7"))
	page.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = "TACTICAL FPS  /  PRE-ALPHA"
	subtitle.add_theme_color_override("font_color", Color("#a5afb9"))
	page.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 14
	page.add_child(spacer)
	_add_button("JOGAR", _show_team_select)
	_add_button("CONFIGURAÇÕES", _show_settings)
	_add_button("SAIR", _quit_game)
	status_label = Label.new()
	status_label.text = "Protótipo em desenvolvimento"
	status_label.add_theme_color_override("font_color", Color("#84909b"))
	page.add_child(status_label)

func _add_button(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(280, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	page.add_child(button)


func _show_team_select() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("#11161b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 48)
	outer.add_theme_constant_override("margin_right", 48)
	outer.add_theme_constant_override("margin_top", 36)
	outer.add_theme_constant_override("margin_bottom", 36)
	add_child(outer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	outer.add_child(column)
	var title := Label.new()
	title.text = "ESCOLHA SUA EQUIPE"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Sua equipe define seu ponto de entrada e seu objetivo nesta rodada."
	subtitle.add_theme_color_override("font_color", Color("#a5afb9"))
	column.add_child(subtitle)
	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 20)
	column.add_child(cards)
	_add_team_card(cards, "TERRORISTAS", "ATAQUE", "Nasça no lado oeste. Plante a bomba no local A ou B.", Color("#e5b16d"), "terrorists")
	_add_team_card(cards, "CONTRA-TERRORISTAS", "DEFESA", "Nasça no lado leste. Impeça o plantio ou desarme a bomba.", Color("#79bfff"), "counter_terrorists")
	var back := Button.new()
	back.text = "VOLTAR AO MENU"
	back.custom_minimum_size = Vector2(220, 44)
	back.pressed.connect(_build_menu)
	column.add_child(back)

func _add_team_card(parent: HBoxContainer, title_text: String, role_text: String, description: String, accent: Color, team_id: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var accent_label := Label.new()
	accent_label.text = role_text
	accent_label.add_theme_color_override("font_color", accent)
	accent_label.add_theme_font_size_override("font_size", 16)
	content.add_child(accent_label)
	var team_title := Label.new()
	team_title.text = title_text
	team_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_title.add_theme_font_size_override("font_size", 24)
	content.add_child(team_title)
	var detail := Label.new()
	detail.text = description
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_color_override("font_color", Color("#c3cbd2"))
	content.add_child(detail)
	var choose := Button.new()
	choose.text = "JOGAR NESTA EQUIPE"
	choose.custom_minimum_size.y = 48
	choose.pressed.connect(func(): _choose_team(team_id))
	content.add_child(choose)

func _choose_team(team_id: String) -> void:
	get_tree().root.set_meta("cs1816_team", team_id)
	_save_settings()
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("CS-1816: não foi possível abrir Main.tscn. Código: %s" % error)
		_build_menu()

func _show_settings() -> void:
	for child in get_children():
		child.queue_free()
	var background := ColorRect.new()
	background.color = Color("#11161b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 32)
	outer.add_theme_constant_override("margin_right", 32)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	outer.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "CONFIGURAÇÕES  /  MIRA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size.x = 120
	back.pressed.connect(_build_menu)
	header.add_child(back)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	root.add_child(content)
	var settings_panel := PanelContainer.new()
	settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_panel.size_flags_stretch_ratio = 1.1
	content.add_child(settings_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	settings_panel.add_child(margin)
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	margin.add_child(controls)
	_add_section_title(controls, "PERSONALIZAÇÃO")
	color_picker = OptionButton.new()
	color_picker.add_item("Verde")
	for color_name in COLORS.keys():
		if color_name != "Verde":
			color_picker.add_item(color_name)
	var color_names := COLORS.keys()
	color_picker.select(color_names.find(_color_name_from_value()))
	color_picker.item_selected.connect(_on_color_selected)
	_add_labeled_control(controls, "Cor predefinida", color_picker)
	custom_color_button = ColorPickerButton.new()
	custom_color_button.color = crosshair_values.color
	custom_color_button.text = "Escolher cor personalizada"
	custom_color_button.custom_minimum_size.y = 38
	custom_color_button.color_changed.connect(func(value: Color): _set_value("color", value))
	controls.add_child(custom_color_button)
	size_slider = _add_slider(controls, "Tamanho", 2, 20, 1, float(crosshair_values["size"]))
	gap_slider = _add_slider(controls, "Espaçamento", 0, 16, 1, float(crosshair_values.gap))
	thickness_slider = _add_slider(controls, "Espessura", 1, 6, 0.5, float(crosshair_values.thickness))
	opacity_slider = _add_slider(controls, "Opacidade", 0.2, 1.0, 0.05, float(crosshair_values.opacity))
	dot_toggle = CheckButton.new()
	dot_toggle.text = "Ponto central"
	dot_toggle.button_pressed = bool(crosshair_values.dot)
	dot_toggle.toggled.connect(func(value: bool): _set_value("dot", value))
	controls.add_child(dot_toggle)
	outline_toggle = CheckButton.new()
	outline_toggle.text = "Contorno preto"
	outline_toggle.button_pressed = bool(crosshair_values.outline)
	outline_toggle.toggled.connect(func(value: bool): _set_value("outline", value))
	controls.add_child(outline_toggle)
	static_toggle = CheckButton.new()
	static_toggle.text = "Mira estática"
	static_toggle.button_pressed = bool(crosshair_values.static)
	static_toggle.toggled.connect(func(value: bool): _set_value("static", value))
	controls.add_child(static_toggle)

	_add_section_title(controls, "PERFIS DE MIRA")
	profile_picker = OptionButton.new()
	profile_picker.add_item("CS clássico")
	profile_picker.add_item("Ponto pequeno")
	profile_picker.add_item("Mira aberta")
	profile_picker.add_item("Minha mira salva")
	_populate_custom_profiles()
	_add_labeled_control(controls, "Predefinição", profile_picker)
	var load_profile_button := Button.new()
	load_profile_button.text = "APLICAR PERFIL"
	load_profile_button.pressed.connect(_apply_selected_profile)
	controls.add_child(load_profile_button)
	profile_name_input = LineEdit.new()
	profile_name_input.placeholder_text = "Nome do perfil personalizado"
	controls.add_child(profile_name_input)
	var save_profile_button := Button.new()
	save_profile_button.text = "SALVAR PERFIL ATUAL"
	save_profile_button.pressed.connect(_save_custom_profile)
	controls.add_child(save_profile_button)

	var reset := Button.new()
	reset.text = "RESTAURAR PADRÃO"
	reset.pressed.connect(_reset_crosshair)
	controls.add_child(reset)
	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_stretch_ratio = 0.9
	content.add_child(preview_panel)
	var preview_column := VBoxContainer.new()
	preview_column.add_theme_constant_override("separation", 12)
	preview_panel.add_child(preview_column)
	var preview_title := Label.new()
	preview_title.text = "PRÉVIA AO VIVO"
	preview_title.add_theme_font_size_override("font_size", 18)
	preview_column.add_child(preview_title)
	preview = CROSSHAIR_SCRIPT.new()
	preview.preview_mode = true
	preview.custom_minimum_size = Vector2(280, 300)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_column.add_child(preview)
	var hint := Label.new()
	hint.text = "A prévia muda na hora conforme você ajusta os controles."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("#a5afb9"))
	preview_column.add_child(hint)
	_update_preview()

func _add_section_title(parent: VBoxContainer, caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", Color("#7fe58b"))
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)

func _add_labeled_control(parent: VBoxContainer, caption: String, control: Control) -> void:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	parent.add_child(control)

func _add_slider(parent: VBoxContainer, caption: String, minimum: float, maximum: float, step: float, initial: float) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = caption
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.x = 280
	slider.value_changed.connect(func(value: float):
		var key := {"Tamanho": "size", "Espaçamento": "gap", "Espessura": "thickness", "Opacidade": "opacity"}[caption]
		_set_value(key, value)
	)
	row.add_child(slider)
	parent.add_child(row)
	return slider



func _populate_custom_profiles() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://cs1816_settings.cfg") != OK:
		return
	for section in cfg.get_sections():
		if section.begins_with("profile_"):
			var profile_name := section.trim_prefix("profile_")
			if profile_name not in ["CS clássico", "Ponto pequeno", "Mira aberta", "Minha mira salva"]:
				profile_picker.add_item(profile_name)

func _apply_selected_profile() -> void:
	var selected := profile_picker.get_item_text(profile_picker.selected)
	var preset := {}
	match selected:
		"CS clássico":
			preset = {"color": Color("#59ff62"), "size": 7.0, "gap": 4.0, "thickness": 2.0, "dot": false, "outline": true, "static": true, "opacity": 1.0}
		"Ponto pequeno":
			preset = {"color": Color("#ffffff"), "size": 2.0, "gap": 0.0, "thickness": 2.0, "dot": true, "outline": true, "static": true, "opacity": 1.0}
		"Mira aberta":
			preset = {"color": Color("#42e8ff"), "size": 12.0, "gap": 8.0, "thickness": 2.0, "dot": false, "outline": true, "static": true, "opacity": 1.0}
		"Minha mira salva":
			preset = _read_profile("Minha mira salva")
		_:
			preset = _read_profile(selected)
	if preset.is_empty():
		return
	for key in preset:
		crosshair_values[key] = preset[key]
	_save_settings()
	_show_settings()

func _save_custom_profile() -> void:
	var profile_name := profile_name_input.text.strip_edges()
	if profile_name.is_empty():
		profile_name = "Minha mira salva"
	var cfg := ConfigFile.new()
	cfg.load("user://cs1816_settings.cfg")
	var section := "profile_" + profile_name
	for key in crosshair_values:
		var value = crosshair_values[key]
		if key == "color":
			value = value.to_html(false)
		cfg.set_value(section, key, value)
	cfg.save("user://cs1816_settings.cfg")
	_show_settings()

func _read_profile(profile_name: String) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load("user://cs1816_settings.cfg") != OK:
		return {}
	var section := "profile_" + profile_name
	if not cfg.has_section(section):
		return {}
	var result := {}
	for key in ["color", "size", "gap", "thickness", "dot", "outline", "static", "opacity"]:
		if cfg.has_section_key(section, key):
			var value = cfg.get_value(section, key)
			if key == "color" and value is String:
				value = Color.from_string(value, Color.GREEN)
			result[key] = value
	return result

func _color_name_from_value() -> String:
	var target: Color = crosshair_values.color
	for name in COLORS:
		if Color.from_string(COLORS[name], Color.WHITE).is_equal_approx(target):
			return name
	return "Verde"

func _on_color_selected(index: int) -> void:
	var name := COLORS.keys()[index]
	_set_value("color", Color.from_string(COLORS[name], Color.GREEN))

func _set_value(key: String, value: Variant) -> void:
	crosshair_values[key] = value
	_save_settings()
	_update_preview()

func _update_preview() -> void:
	if is_instance_valid(preview):
		preview.apply_settings(crosshair_values)

func _reset_crosshair() -> void:
	crosshair_values = {
		"color": Color(0.35, 1.0, 0.38, 1.0),
		"size": 8.0,
		"gap": 5.0,
		"thickness": 2.0,
		"dot": false,
		"outline": true,
		"static": true,
		"opacity": 1.0
	}
	_save_settings()
	_show_settings()

func _start_game() -> void:
	_save_settings()
	get_tree().change_scene_to_file(GAME_SCENE)

func _quit_game() -> void:
	get_tree().quit()
