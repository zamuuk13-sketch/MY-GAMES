extends Node3D

# SPIDER CITY - third-person traversal prototype.
# Procedural hero, city, web anchors, climbing and swing physics.
# No external assets are required for the first playable build.

var player: CharacterBody3D
var visual: Node3D
var camera: Camera3D
var anchor: Node3D
var rope: MeshInstance3D
var hud: Label
var state_label: Label
var web_points: Array[Node3D] = []
var velocity := Vector3.ZERO
var gravity := 24.0
var jump_power := 8.0
var run_speed := 13.0
var walk_speed := 7.0
var acceleration := 28.0
var camera_yaw := 0.0
var camera_pitch := -0.18
var swing_length := 18.0
var swinging := false
var climbing := false
var climb_normal := Vector3.ZERO
var climb_cooldown := 0.0
var step_clock := 0.0
var air_time := 0.0
var rng := RandomNumberGenerator.new()
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var torso: Node3D

func _ready() -> void:
    rng.seed = 73129
    _build_environment()
    _build_player()
    _build_city()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_environment() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.34, 0.62, 0.92)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.85, 1.0)
    env.ambient_light_energy = 1.15
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = env
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.5
    sun.shadow_enabled = true
    add_child(sun)

    _make_box("Ground", Vector3(0,-0.5,0), Vector3(180,1,180), Color(0.13,0.15,0.16))

func _build_city() -> void:
    var blocks := [
        Vector3(-42,14,-38), Vector3(-15,24,-43), Vector3(15,17,-40), Vector3(43,30,-39),
        Vector3(-47,20,-8), Vector3(-20,34,-6), Vector3(17,22,-7), Vector3(46,27,-5),
        Vector3(-43,17,29), Vector3(-15,28,31), Vector3(18,19,29), Vector3(45,37,30),
        Vector3(-67,11,-1), Vector3(67,14,2), Vector3(-4,18,52), Vector3(31,23,52)
    ]
    var i := 0
    for p in blocks:
        var w := rng.randf_range(13.0,19.0)
        var d := rng.randf_range(13.0,19.0)
        var h := p.y * 2.0
        var color := Color.from_hsv(0.55 + rng.randf_range(-0.04,0.05),0.12 + rng.randf_range(0.0,0.16),0.45 + rng.randf_range(0.0,0.22))
        _make_building("Building_%02d" % i, Vector3(p.x,h*0.5,p.z), Vector3(w,h,d), color)
        _add_windows(Vector3(p.x,h*0.5,p.z),Vector3(w,h,d))
        _add_anchors(Vector3(p.x,h*0.5,p.z),Vector3(w,h,d))
        i += 1

    # Main streets.
    _make_box("RoadX",Vector3(0,0.02,0),Vector3(180,0.08,11),Color(0.055,0.06,0.065))
    _make_box("RoadZ",Vector3(0,0.03,0),Vector3(11,0.09,180),Color(0.055,0.06,0.065))
    for x in [-32.0,32.0]:
        _make_box("Road",Vector3(x,0.04,0),Vector3(7,0.1,180),Color(0.065,0.07,0.075))
    for z in [-30.0,30.0]:
        _make_box("Road",Vector3(0,0.05,z),Vector3(180,0.1,7),Color(0.065,0.07,0.075))

func _make_building(n:String,pos:Vector3,size:Vector3,color:Color) -> void:
    _make_box(n,pos,size,color)

func _add_windows(center:Vector3,size:Vector3) -> void:
    var floors := int(size.y / 4.0)
    var cols := int(size.x / 4.0)
    for floor in range(1,floors):
        for col in range(-cols/2,cols/2+1):
            if rng.randf() < 0.15:
                continue
            var z := center.z - size.z*0.5 - 0.03
            var x := center.x + col*4.0
            var y := floor*4.0 - 1.2
            var pane := MeshInstance3D.new()
            var box := BoxMesh.new()
            box.size = Vector3(2.1,1.5,0.08)
            pane.mesh = box
            pane.position = Vector3(x,y,z)
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color(0.14,0.25,0.32)
            mat.metallic = 0.15
            mat.roughness = 0.2
            pane.material_override = mat
            add_child(pane)

func _add_anchors(center:Vector3,size:Vector3) -> void:
    var y_top := center.y + size.y*0.5 - 1.0
    var points := [
        Vector3(center.x-size.x*0.43,y_top,center.z-size.z*0.43),
        Vector3(center.x+size.x*0.43,y_top,center.z-size.z*0.43),
        Vector3(center.x-size.x*0.43,y_top,center.z+size.z*0.43),
        Vector3(center.x+size.x*0.43,y_top,center.z+size.z*0.43),
        Vector3(center.x,y_top-6.0,center.z-size.z*0.51),
        Vector3(center.x,y_top-10.0,center.z+size.z*0.51)
    ]
    for p in points:
        var a := Node3D.new()
        a.position = p
        add_child(a)
        var marker := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.16
        sphere.height = 0.32
        marker.mesh = sphere
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.15,0.55,1.0)
        mat.emission_enabled = true
        mat.emission = Color(0.04,0.18,0.55)
        marker.material_override = mat
        a.add_child(marker)
        web_points.append(a)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "SpiderHero"
    player.position = Vector3(0,2.0,14)
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 2.0
    capsule.radius = 0.42
    collision.shape = capsule
    collision.position.y = 1.0
    player.add_child(collision)

    visual = Node3D.new()
    visual.position.y = 1.0
    player.add_child(visual)
    torso = visual

    _part_box("Torso",Vector3(0,0,0),Vector3(0.82,1.15,0.46),Color(0.035,0.055,0.12),visual)
    _part_sphere("Head",Vector3(0,0.78,0),Vector3(0.58,0.58,0.58),Color(0.035,0.045,0.075),visual)
    _part_box("Chest",Vector3(0,0.1,-0.25),Vector3(0.5,0.65,0.06),Color(0.55,0.03,0.04),visual)
    arm_l = _limb("ArmL",Vector3(-0.55,0.12,0),0.75,0.17,Color(0.035,0.05,0.12),visual)
    arm_r = _limb("ArmR",Vector3(0.55,0.12,0),0.75,0.17,Color(0.035,0.05,0.12),visual)
    leg_l = _limb("LegL",Vector3(-0.22,-0.85,0),0.95,0.2,Color(0.035,0.05,0.12),visual)
    leg_r = _limb("LegR",Vector3(0.22,-0.85,0),0.95,0.2,Color(0.035,0.05,0.12),visual)

    camera = Camera3D.new()
    camera.position = Vector3(0,2.7,7.2)
    camera.rotation_degrees.x = -8
    camera.current = true
    camera.fov = 72
    add_child(camera)

func _part_box(n:String,pos:Vector3,size:Vector3,color:Color,parent:Node3D) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.65
    m.material_override = mat
    parent.add_child(m)
    return m

func _part_sphere(n:String,pos:Vector3,size:Vector3,color:Color,parent:Node3D) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    m.mesh = mesh
    m.scale = size
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    m.material_override = mat
    parent.add_child(m)
    return m

func _limb(n:String,pos:Vector3,length:float,width:float,color:Color,parent:Node3D) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = n
    pivot.position = pos
    parent.add_child(pivot)
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = length
    capsule.radius = width
    mesh.mesh = capsule
    mesh.position.y = -length*0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    pivot.add_child(mesh)
    return pivot

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(28,24)
    hud.add_theme_font_size_override("font_size",18)
    layer.add_child(hud)
    state_label = Label.new()
    state_label.position = Vector2(28,55)
    state_label.add_theme_font_size_override("font_size",16)
    layer.add_child(state_label)

func _process(delta:float) -> void:
    if climb_cooldown > 0:
        climb_cooldown -= delta
    _find_best_anchor()
    _update_rope()
    _animate_hero(delta)
    _update_camera(delta)
    _update_ui()
    if player.position.y < -30:
        player.position = Vector3(0,4,14)
        velocity = Vector3.ZERO

func _physics_process(delta:float) -> void:
    var input_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
    var cam_basis := Basis(Vector3.UP,camera_yaw)
    var dir := (cam_basis * Vector3(input_vec.x,0,input_vec.y)).normalized()
    var speed := run_speed if Input.is_action_pressed("run") else walk_speed
    if swinging:
        _swing_physics(dir,delta)
    elif climbing:
        _climb_physics(dir,delta)
    else:
        _ground_physics(dir,speed,delta)
    player.velocity = velocity
    player.move_and_slide()
    if not climbing and not swinging:
        _try_wall_climb(dir)

func _ground_physics(dir:Vector3,speed:float,delta:float) -> void:
    var target := dir * speed
    velocity.x = move_toward(velocity.x,target.x,acceleration*delta)
    velocity.z = move_toward(velocity.z,target.z,acceleration*delta)
    if player.is_on_floor():
        if Input.is_action_just_pressed("jump"):
            var forward_speed := Vector3(velocity.x,0,velocity.z).length()
            velocity.y = jump_power + min(forward_speed*0.22,6.5)
            air_time = 0.0
        else:
            velocity.y = -0.8
    else:
        velocity.y -= gravity*delta
        air_time += delta

func _try_wall_climb(dir:Vector3) -> void:
    if climb_cooldown > 0 or player.is_on_floor() or dir.length() < 0.1:
        return
    var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*0.9,player.global_position+Vector3.UP*0.9+dir*1.15)
    query.exclude = [player]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        climbing = true
        climb_normal = hit.normal
        velocity = dir*2.0 + Vector3.UP*5.0

func _climb_physics(dir:Vector3,delta:float) -> void:
    var wall_dir := dir
    if wall_dir.length() < 0.1:
        wall_dir = -climb_normal
    velocity = wall_dir*3.0 + Vector3.UP*4.8
    var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*0.8,player.global_position+Vector3.UP*0.8-climb_normal*0.9)
    query.exclude = [player]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        climbing = false
        climb_cooldown = 0.3
        return
    if Input.is_action_just_pressed("jump"):
        climbing = false
        climb_cooldown = 0.25
        velocity = -climb_normal*6.5 + Vector3.UP*8.5

func _find_best_anchor() -> void:
    if swinging:
        return
    var best:Node3D = null
    var best_score := -1000.0
    var forward := -Basis(Vector3.UP,camera_yaw).z
    for p in web_points:
        var to := p.global_position-player.global_position
        var dist := to.length()
        if dist < 5.0 or dist > 34.0:
            continue
        var dot := forward.dot(to.normalized())
        if dot < 0.35:
            continue
        var score := dot*3.0 - dist*0.035 + p.global_position.y*0.004
        if score > best_score:
            best_score = score
            best = p
    if best != anchor:
        anchor = best

func _start_swing() -> void:
    if anchor == null:
        return
    swinging = true
    swing_length = clamp(player.global_position.distance_to(anchor.global_position),8.0,32.0)
    velocity += (-Basis(Vector3.UP,camera_yaw).z)*3.0

func _release_swing() -> void:
    swinging = false
    anchor = null
    climb_cooldown = 0.15

func _swing_physics(dir:Vector3,delta:float) -> void:
    if anchor == null:
        _release_swing()
        return
    var to_anchor := anchor.global_position-player.global_position
    var dist := to_anchor.length()
    if dist < 2.0:
        return
    var radial := to_anchor.normalized()
    var tangent := velocity - radial*velocity.dot(radial)
    velocity += Vector3.DOWN*gravity*delta
    velocity += tangent.normalized()*min(20.0*delta,tangent.length()*0.05) if tangent.length()>0.1 else Vector3.ZERO
    var correction := radial*(dist-swing_length)*7.0
    velocity += correction*delta
    velocity += dir*7.0*delta
    velocity += radial*max(0.0,dist-swing_length)*3.0
    if Input.is_action_just_pressed("jump"):
        velocity += radial*5.0 + Vector3.UP*8.0
        _release_swing()

func _input(event:InputEvent) -> void:
    if event is InputEventMouseMotion:
        camera_yaw -= event.relative.x*0.0028
        camera_pitch = clamp(camera_pitch-event.relative.y*0.0022,-0.9,0.35)
    if event.is_action_pressed("web_swing"):
        _start_swing()
    if event.is_action_released("web_swing"):
        _release_swing()
    if event.is_action_pressed("jump") and climbing:
        _climb_physics(Vector3.ZERO,0.016)

func _update_rope() -> void:
    if rope != null:
        rope.queue_free()
        rope = null
    if not swinging or anchor == null:
        return
    rope = MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    var a := player.global_position+Vector3(0,1.25,0)
    var b := anchor.global_position
    var d := a.distance_to(b)
    mesh.height = d
    mesh.top_radius = 0.018
    mesh.bottom_radius = 0.018
    rope.mesh = mesh
    rope.position = (a+b)*0.5
    rope.look_at(b,Vector3.UP)
    rope.rotate_object_local(Vector3.RIGHT,PI*0.5)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.92,0.92,0.92)
    mat.roughness = 0.75
    rope.material_override = mat
    add_child(rope)

func _animate_hero(delta:float) -> void:
    if visual == null:
        return
    var horizontal := Vector3(velocity.x,0,velocity.z).length()
    var t := Time.get_ticks_msec()*0.001
    var falling := not player.is_on_floor() and velocity.y < -3.0
    if swinging:
        arm_l.rotation.x = -1.35
        arm_r.rotation.x = -1.35
        leg_l.rotation.z = sin(t*5.0)*0.18
        leg_r.rotation.z = -sin(t*5.0)*0.18
        visual.rotation.z = lerp(visual.rotation.z,-0.18,delta*5.0)
    elif climbing:
        arm_l.rotation.x = -1.2
        arm_r.rotation.x = -1.2
        leg_l.rotation.x = 0.5
        leg_r.rotation.x = -0.5
        visual.rotation.z = 0
    elif falling:
        # Looking downward while falling gives a clear dive/fall pose.
        var dive := clamp(-camera_pitch*1.5, -0.8, 1.0)
        visual.rotation.x = lerp(visual.rotation.x,dive,delta*6.0)
        arm_l.rotation.x = -1.0
        arm_r.rotation.x = -1.0
        leg_l.rotation.x = 0.45
        leg_r.rotation.x = -0.45
    elif horizontal > 8.5:
        step_clock += delta*12.0
        arm_l.rotation.x = sin(step_clock)*0.8
        arm_r.rotation.x = -sin(step_clock)*0.8
        leg_l.rotation.x = -sin(step_clock)*0.9
        leg_r.rotation.x = sin(step_clock)*0.9
        visual.rotation.x = lerp(visual.rotation.x,0.0,delta*8.0)
    elif horizontal > 0.8:
        step_clock += delta*8.0
        arm_l.rotation.x = sin(step_clock)*0.45
        arm_r.rotation.x = -sin(step_clock)*0.45
        leg_l.rotation.x = -sin(step_clock)*0.55
        leg_r.rotation.x = sin(step_clock)*0.55
        visual.rotation.x = lerp(visual.rotation.x,0.0,delta*8.0)
    else:
        arm_l.rotation.x = lerp(arm_l.rotation.x,0.05,delta*5.0)
        arm_r.rotation.x = lerp(arm_r.rotation.x,-0.05,delta*5.0)
        leg_l.rotation.x = lerp(leg_l.rotation.x,0.0,delta*5.0)
        leg_r.rotation.x = lerp(leg_r.rotation.x,0.0,delta*5.0)
        visual.rotation.x = lerp(visual.rotation.x,0.0,delta*6.0)

func _update_camera(delta:float) -> void:
    var desired := player.global_position + Vector3(0,2.9,0) + Basis(Vector3.UP,camera_yaw)*Vector3(0,0,7.5)
    camera.global_position = camera.global_position.lerp(desired,1.0-exp(-delta*8.0))
    camera.look_at(player.global_position+Vector3(0,1.2,0),Vector3.UP)
    camera.rotation.x += camera_pitch*0.45
    camera.fov = lerp(camera.fov,88.0 if swinging else 72.0,delta*4.0)

func _update_ui() -> void:
    if hud == null:
        return
    var target := "nenhum"
    if anchor != null:
        target = "PONTO DE TEIA"
    hud.text = "SPIDER CITY\nWASD mover | SHIFT correr | ESPAÇO salto | E web swing\nPonto: %s" % target
    if swinging:
        state_label.text = "🕸️ WEB SWING — mantenha E | ESPAÇO solta com impulso"
    elif climbing:
        state_label.text = "🧗 ESCALANDO — WASD subir | ESPAÇO impulso para trás"
    elif not player.is_on_floor() and velocity.y < -3.0:
        state_label.text = "⬇ QUEDA — olhe para baixo para entrar na pose de mergulho"
    else:
        state_label.text = "Corrida e salto: quanto mais rápido, maior o impulso."

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
    mat.roughness = 0.72
    mesh.material_override = mat
    body.add_child(mesh)
    return body
