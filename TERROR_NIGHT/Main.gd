extends Node3D

# TERROR NIGHT - complete procedural horror prototype.
# Everything is generated at runtime, so the game has no external asset dependency.

var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var monster: CharacterBody3D
var monster_active := false
var flashlight_on := true
var battery := 100.0
var health := 100.0
var fuses := 0
var has_key := false
var generator_on := false
var game_over := false
var won := false
var objective := "Encontre 3 fusíveis e restaure o gerador."
var hud: Label
var message: Label
var crosshair: Label
var world_time := 0.0
var monster_speed := 2.7
var exit_door: StaticBody3D
var interactables: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 78431
    _build_world()
    _build_player()
    _build_monster()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _show_message("Você acorda sozinho no bloco subterrâneo. Encontre os fusíveis.", 4.0)

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.004, 0.006, 0.009)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.08, 0.09, 0.11)
    environment.ambient_light_energy = 0.28
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)

    _make_box("Floor", Vector3(0,-0.15,0), Vector3(32,0.3,32), Color(0.09,0.09,0.085))
    _make_box("Ceiling", Vector3(0,5.5,0), Vector3(32,0.3,32), Color(0.035,0.035,0.04))
    _make_box("NorthWall", Vector3(0,2.7,-16), Vector3(32,5.4,0.3), Color(0.055,0.055,0.065))
    _make_box("SouthWall", Vector3(0,2.7,16), Vector3(32,5.4,0.3), Color(0.055,0.055,0.065))
    _make_box("WestWall", Vector3(-16,2.7,0), Vector3(0.3,5.4,32), Color(0.055,0.055,0.065))
    _make_box("EastWall", Vector3(16,2.7,0), Vector3(0.3,5.4,32), Color(0.055,0.055,0.065))

    # Corridor-like interior walls.
    _make_box("WallA", Vector3(-5,2.5,-7), Vector3(0.3,5,13), Color(0.045,0.045,0.05))
    _make_box("WallB", Vector3(5,2.5,7), Vector3(0.3,5,13), Color(0.045,0.045,0.05))
    _make_box("WallC", Vector3(0,2.5,2), Vector3(10,5,0.3), Color(0.045,0.045,0.05))

    # Lamps: most are dead, one flickers.
    for p in [Vector3(-11,4.9,-11),Vector3(10,4.9,-11),Vector3(-10,4.9,10),Vector3(10,4.9,10)]:
        var lamp := OmniLight3D.new()
        lamp.position = p
        lamp.omni_range = 5.0
        lamp.light_energy = 0.35
        lamp.light_color = Color(0.55,0.62,0.7)
        add_child(lamp)

    # Objective items.
    _spawn_item("Fusível 1", Vector3(-11,0.5,-11), Color(0.95,0.7,0.2), "fuse")
    _spawn_item("Fusível 2", Vector3(11,0.5,-10), Color(0.95,0.7,0.2), "fuse")
    _spawn_item("Fusível 3", Vector3(10,0.5,11), Color(0.95,0.7,0.2), "fuse")
    _spawn_item("Chave enferrujada", Vector3(-10,0.5,10), Color(0.5,0.65,0.75), "key")
    _spawn_item("Bateria", Vector3(9,0.5,-3), Color(0.25,0.85,0.35), "battery")
    _spawn_item("Bateria", Vector3(-10,0.5,3), Color(0.25,0.85,0.35), "battery")

    # Generator and final exit.
    _make_box("Generator", Vector3(0,1.1,10), Vector3(2.0,2.2,1.2), Color(0.12,0.13,0.14))
    _make_box("GeneratorScreen", Vector3(0,1.5,9.35), Vector3(0.8,0.55,0.04), Color(0.35,0.08,0.05))
    interactables.append({"kind":"generator","pos":Vector3(0,1.0,9.0)})

    exit_door = _make_box("ExitDoor", Vector3(0,2.3,-15.7), Vector3(3.2,4.6,0.3), Color(0.12,0.12,0.13))
    interactables.append({"kind":"exit","pos":Vector3(0,1.2,-14.8)})

    # Scattered crates for atmosphere.
    for p in [Vector3(-12,0.7,-4),Vector3(12,0.7,4),Vector3(-8,0.7,12),Vector3(7,0.7,-12)]:
        _make_box("Crate", p, Vector3(1.4,1.4,1.4), Color(0.12,0.075,0.045))

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0,1.0,13)
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.38
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0,1.55,0)
    camera.current = true
    camera.fov = 78.0
    player.add_child(camera)

    flashlight = SpotLight3D.new()
    flashlight.position = Vector3(0,0,-0.25)
    flashlight.rotation_degrees.x = -3
    flashlight.spot_range = 17.0
    flashlight.spot_angle = 28.0
    flashlight.light_energy = 5.0
    flashlight.shadow_enabled = true
    camera.add_child(flashlight)

func _build_monster() -> void:
    monster = CharacterBody3D.new()
    monster.name = "TheWatcher"
    monster.position = Vector3(12,0,12)
    add_child(monster)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 2.8
    shape.radius = 0.55
    collision.shape = shape
    collision.position.y = 1.4
    monster.add_child(collision)

    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.height = 2.8
    mesh.radius = 0.55
    mesh.radial_segments = 12
    body.mesh = mesh
    body.position.y = 1.4
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.012,0.012,0.015)
    mat.roughness = 0.9
    body.material_override = mat
    monster.add_child(body)

    for x in [-0.18,0.18]:
        var eye := OmniLight3D.new()
        eye.position = Vector3(x,2.05,-0.48)
        eye.light_color = Color(1,0.03,0.02)
        eye.light_energy = 1.8
        eye.omni_range = 1.5
        monster.add_child(eye)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    hud = Label.new()
    hud.position = Vector2(28,24)
    hud.add_theme_font_size_override("font_size",20)
    layer.add_child(hud)

    message = Label.new()
    message.position = Vector2(0,560)
    message.size = Vector2(1280,80)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.add_theme_font_size_override("font_size",22)
    layer.add_child(message)

    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.position = Vector2(635,348)
    crosshair.add_theme_font_size_override("font_size",22)
    layer.add_child(crosshair)

func _process(delta: float) -> void:
    world_time += delta
    _update_hud()
    _update_items()
    _update_monster(delta)
    if flashlight_on:
        battery = max(0.0, battery - delta * 0.75)
        if battery <= 0:
            flashlight_on = false
            flashlight.visible = false
            _show_message("A lanterna morreu. Encontre uma bateria.", 2.5)
    if monster_active and randf() < delta * 0.035:
        _flicker_lights()

func _physics_process(delta: float) -> void:
    if game_over or won:
        return
    var input_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
    var dir := (player.transform.basis * Vector3(input_vec.x,0,input_vec.y)).normalized()
    var speed := 5.0 if not Input.is_action_pressed("sprint") else 7.2
    player.velocity.x = dir.x * speed
    player.velocity.z = dir.z * speed
    player.velocity.y = 0
    player.move_and_slide()
    player.position.x = clamp(player.position.x,-15.2,15.2)
    player.position.z = clamp(player.position.z,-15.2,15.2)
    _check_interaction()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and not (game_over or won):
        player.rotate_y(-event.relative.x * 0.0025)
        camera.rotate_x(-event.relative.y * 0.0025)
        camera.rotation.x = clamp(camera.rotation.x,-1.45,1.45)
    if event.is_action_pressed("flashlight") and not game_over and not won:
        if battery > 0:
            flashlight_on = not flashlight_on
            flashlight.visible = flashlight_on
    if event.is_action_pressed("interact") and not game_over and not won:
        _try_interact()

func _check_interaction() -> void:
    for item in interactables:
        if player.global_position.distance_to(item.pos) < 1.7:
            crosshair.modulate = Color(1,0.8,0.3)
            return
    crosshair.modulate = Color.WHITE

func _try_interact() -> void:
    var closest: Dictionary = {}
    var best := 1.7
    for item in interactables:
        var d: float = player.global_position.distance_to(item.pos)
        if d < best:
            best = d
            closest = item
    if closest.is_empty():
        return
    if closest.kind == "generator":
        if fuses < 3:
            _show_message("O gerador precisa dos 3 fusíveis.",2.0)
        elif not has_key:
            _show_message("O gerador liga, mas a saída está trancada. Ache a chave.",2.0)
        else:
            generator_on = true
            monster_active = true
            objective = "O gerador está ligado. CORRA PARA A SAÍDA!"
            _show_message("ALGO ACORDOU. SAIA AGORA.",3.0)
    elif closest.kind == "exit":
        if generator_on and has_key:
            _win()
        elif not generator_on:
            _show_message("A porta não tem energia.",2.0)
        else:
            _show_message("A porta está trancada. Você precisa da chave.",2.0)

func _update_items() -> void:
    for i in range(interactables.size()-1,-1,-1):
        var item := interactables[i]
        if not item.has("node"):
            continue
        var node: Node3D = item.node
        if player.global_position.distance_to(node.global_position) < 1.15:
            if item.kind == "fuse":
                fuses += 1
                _show_message("Fusível encontrado. (%d/3)" % fuses,1.6)
            elif item.kind == "key":
                has_key = true
                _show_message("Você encontrou a chave da saída.",2.0)
            elif item.kind == "battery":
                battery = min(100.0,battery+45.0)
                _show_message("Bateria recarregada. (F para lanterna)",1.5)
            node.queue_free()
            interactables.remove_at(i)
            if fuses == 3 and not generator_on:
                objective = "Os 3 fusíveis estão prontos. Vá ao gerador."
            elif has_key and fuses == 3 and not generator_on:
                objective = "Você tem tudo. Vá ao gerador."

func _update_monster(delta: float) -> void:
    if not monster_active or game_over or won:
        return
    var target := player.global_position
    var flat := Vector3(target.x,0,target.z) - Vector3(monster.global_position.x,0,monster.global_position.z)
    if flat.length() > 0.1:
        monster.velocity = flat.normalized() * monster_speed
        monster.look_at(Vector3(target.x,monster.global_position.y,target.z),Vector3.UP)
        monster.move_and_slide()
    var distance := monster.global_position.distance_to(player.global_position)
    if distance < 1.5:
        health -= delta * 48.0
        camera.fov = lerp(camera.fov,88.0,delta*8.0)
    else:
        camera.fov = lerp(camera.fov,78.0,delta*4.0)
    if distance < 0.9:
        _lose("A criatura alcançou você.")

func _update_hud() -> void:
    if hud == null:
        return
    hud.text = "OBJETIVO: %s\nFusíveis: %d/3   Chave: %s   Vida: %d%%   Lanterna: %d%% [F]" % [objective,fuses,"SIM" if has_key else "NÃO",int(health),int(battery)]
    if health <= 0 and not game_over:
        _lose("Você não resistiu aos ferimentos.")

func _spawn_item(item_name:String, pos:Vector3, color:Color, kind:String) -> void:
    var body := StaticBody3D.new()
    body.name = item_name
    body.position = pos
    add_child(body)
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.28
    sphere.height = 0.56
    mesh.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color * 0.55
    mesh.material_override = mat
    body.add_child(mesh)
    interactables.append({"kind":kind,"pos":pos,"node":body,"name":item_name})

func _make_box(n:String,pos:Vector3,size:Vector3,color:Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = n
    body.position = pos
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    mesh.material_override = mat
    body.add_child(mesh)
    return body

func _show_message(text_value:String,duration:float) -> void:
    if message == null:
        return
    message.text = text_value
    await get_tree().create_timer(duration).timeout
    if message.text == text_value:
        message.text = ""

func _flicker_lights() -> void:
    for child in get_children():
        if child is WorldEnvironment:
            continue
        if child is OmniLight3D and child != monster:
            child.visible = false
    await get_tree().create_timer(0.08).timeout
    for child in get_children():
        if child is OmniLight3D:
            child.visible = true

func _lose(reason:String) -> void:
    if game_over or won:
        return
    game_over = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    objective = "FIM DE JOGO"
    message.text = reason + "\n\nVOCÊ MORREU\nPressione F5 para tentar novamente."

func _win() -> void:
    won = true
    monster_active = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    objective = "ESCAPOU"
    message.text = "A porta se abre para a madrugada.\n\nVOCÊ SOBREVIVEU.\nPressione F5 para jogar novamente."
