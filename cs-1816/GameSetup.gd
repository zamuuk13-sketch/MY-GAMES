extends Node3D

func _ready() -> void:
	var team := str(get_tree().root.get_meta("cs1816_team", "terrorists"))
	var player := get_node_or_null("Player") as CharacterBody3D
	if player:
		if team == "counter_terrorists":
			player.position = Vector3(34, 1.2, 0)
			player.rotation.y = PI / 2.0
		else:
			player.position = Vector3(-38, 1.2, 0)
			player.rotation.y = -PI / 2.0
	_add_objective_hud(team)

func _add_objective_hud(team: String) -> void:
	var layer := CanvasLayer.new()
	layer.name = "ObjectiveHUD"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(350, 84)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var team_label := Label.new()
	var objective := Label.new()
	if team == "counter_terrorists":
		team_label.text = "CONTRA-TERRORISTAS  /  DEFESA"
		objective.text = "Objetivo: impedir o plantio ou desarmar a bomba."
		team_label.add_theme_color_override("font_color", Color("#79bfff"))
	else:
		team_label.text = "TERRORISTAS  /  ATAQUE"
		objective.text = "Objetivo: plantar a bomba no local A ou B."
		team_label.add_theme_color_override("font_color", Color("#e5b16d"))
	column.add_child(team_label)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(objective)
