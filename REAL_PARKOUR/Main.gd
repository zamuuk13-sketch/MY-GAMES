extends Node3D

# REAL PARKOUR PHYSICS
# Procedural third-person parkour prototype.
# Designed to stay light enough for integrated graphics while keeping
# articulated hands, fingers, feet, camera-relative movement and physical traversal.

var player: CharacterBody3D
var rig: Node3D
var pelvis: Node3D
var chest: Node3D
var head: Node3D
var neck: Node3D
var upper_arm_l: Node3D
var forearm_l: Node3D
var hand_l: Node3D
var upper_arm_r: Node3D
var forearm_r: Node3D
var hand_r: Node3D
var thigh_l: Node3D
var shin_l: Node3D
var foot_l: Node3D
var thigh_r: Node3D
var shin_r: Node3D
var foot_r: Node3D
var fingers_l: Array[Node3D] = []
var fingers_r: Array[Node3D] = []
var toes_l: Array[Node3D] = []
var toes_r: Array[Node3D] = []

var camera: Camera3D
var camera_yaw: float = 0.0
var camera_pitch: float = -0.16
var camera_distance: float = 6.4
var camera_height: float = 2.4

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 22.0
var walk_speed: float = 4.8
var run_speed: float = 8.8
var acceleration: float = 20.0
var air_acceleration: float = 7.0
var jump_power: float = 6.6

var parkour_state: String = "idle"
var climbing: bool = false
var wall_running: bool = false
var vaulting: bool = false
var wall_normal: Vector3 = Vector3.ZERO
var climb_timer: float = 0.0
var wall_run_timer: float = 0.0
var vault_timer: float = 0.0
var vault_start: Vector3 = Vector3.ZERO
var vault_end: Vector3 = Vector3.ZERO
var climb_height: float = 0.0
var max_climb_height: float = 5.5
var last_floor_velocity: float = 0.0
var fall_speed: float = 0.0
var landing_timer: float = 0.0
var step_phase: float = 0.0
var idle_phase: float = 0.0
var was_on_floor: bool = true
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var state_label: Label
var speed_label: Label

func _ready() -> void:
    rng.seed = 48192
    _build_world()
    _build_player()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
    var env_node: WorldEnvironment = WorldEnvironment.new()
    var env: Environment = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.52, 0.68, 0.76)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.78, 0.84, 0.88)
    env.ambient_light_energy = 1.25
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = env
    add_child(env_node)

    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
    sun.light_energy = 1.65
    sun.shadow_enabled = true
    add_child(sun)

    _box_static("Ground", Vector3(0,-0.25,0), Vector3(150,0.5,150), Color(0.19,0.20,0.20))

    # Parkour training district: low, medium and high surfaces.
    _box_static("WallLow", Vector3(0,1.5,-8), Vector3(10,3,0.8), Color(0.46,0.47,0.45))
    _box_static("WallMedium", Vector3(-13,2.7,-5), Vector3(0.8,5.4,10), Color(0.43,0.44,0.43))
    _box_static("WallTall", Vector3(14,4.0,-6), Vector3(9,8,0.8), Color(0.39,0.41,0.40))
    _box_static("WallLong", Vector3(1,2.1,11), Vector3(24,4.2,0.9), Color(0.48,0.48,0.46))

    _box_static("BlockA", Vector3(-7,0.65,3), Vector3(3.2,1.3,3.2), Color(0.34,0.35,0.34))
    _box_static("BlockB", Vector3(-1,1.05,3), Vector3(3.2,2.1,3.2), Color(0.38,0.39,0.38))
    _box_static("BlockC", Vector3(6,1.45,3), Vector3(3.2,2.9,3.2), Color(0.42,0.43,0.42))
    _box_static("LedgeHigh", Vector3(10,2.2,8), Vector3(5,4.4,1.0), Color(0.36,0.37,0.37))

    # Narrow rails for balance / traversal.
    _box_static("RailA", Vector3(-8,0.55,-15), Vector3(0.5,1.1,12), Color(0.26,0.27,0.27))
    _box_static("RailB", Vector3(8,0.55,-18), Vector3(0.5,1.1,12), Color(0.26,0.27,0.27))

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "ParkourCharacter"
    player.position = Vector3(0,1.15,18)
    player.floor_snap_length = 0.28
    player.floor_stop_on_slope = true
    add_child(player)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var capsule: CapsuleShape3D = CapsuleShape3D.new()
    capsule.height = 1.72
    capsule.radius = 0.30
    collision.shape = capsule
    collision.position.y = 0.86
    player.add_child(collision)

    rig = Node3D.new()
    rig.name = "DetailedHumanoid"
    rig.position.y = 0.08
    player.add_child(rig)

    pelvis = Node3D.new()
    pelvis.name = "Pelvis"
    pelvis.position = Vector3(0,0.88,0)
    rig.add_child(pelvis)

    chest = Node3D.new()
    chest.name = "Chest"
    chest.position = Vector3(0,0.48,0)
    pelvis.add_child(chest)
    _capsule_mesh("Torso", chest, Vector3(0,0,0), 0.82, 0.28, Color(0.18,0.20,0.22))

    neck = Node3D.new()
    neck.name = "Neck"
    neck.position = Vector3(0,0.55,0)
    chest.add_child(neck)
    _cylinder_mesh("NeckMesh", neck, Vector3.ZERO, 0.20, 0.13, Color(0.46,0.33,0.25))

    head = Node3D.new()
    head.name = "Head"
    head.position = Vector3(0,0.24,0)
    neck.add_child(head)
    _sphere_mesh("HeadMesh", head, Vector3.ZERO, Vector3(0.27,0.31,0.27), Color(0.52,0.37,0.28))
    _sphere_mesh("Hair", head, Vector3(0,0.18,0), Vector3(0.29,0.13,0.29), Color(0.055,0.04,0.03))

    # Arms: shoulder -> upper arm -> forearm -> hand -> five fingers.
    upper_arm_l = _limb("UpperArmL", chest, Vector3(-0.42,0.30,0), 0.48, 0.105, Color(0.48,0.34,0.27))
    forearm_l = _limb("ForearmL", upper_arm_l, Vector3(0,-0.48,0), 0.44, 0.09, Color(0.49,0.35,0.28))
    hand_l = _hand("HandL", forearm_l, Vector3(0,-0.43,0), fingers_l)

    upper_arm_r = _limb("UpperArmR", chest, Vector3(0.42,0.30,0), 0.48, 0.105, Color(0.48,0.34,0.27))
    forearm_r = _limb("ForearmR", upper_arm_r, Vector3(0,-0.48,0), 0.44, 0.09, Color(0.49,0.35,0.28))
    hand_r = _hand("HandR", forearm_r, Vector3(0,-0.43,0), fingers_r)

    # Legs: hip -> thigh -> shin -> articulated foot and toes.
    thigh_l = _limb("ThighL", pelvis, Vector3(-0.17,-0.10,0), 0.53, 0.135, Color(0.13,0.14,0.15))
    shin_l = _limb("ShinL", thigh_l, Vector3(0,-0.53,0), 0.50, 0.105, Color(0.46,0.33,0.26))
    foot_l = _foot("FootL", shin_l, Vector3(0,-0.49,-0.07), toes_l)

    thigh_r = _limb("ThighR", pelvis, Vector3(0.17,-0.10,0), 0.53, 0.135, Color(0.13,0.14,0.15))
    shin_r = _limb("ShinR", thigh_r, Vector3(0,-0.53,0), 0.50, 0.105, Color(0.46,0.33,0.26))
    foot_r = _foot("FootR", shin_r, Vector3(0,-0.49,-0.07), toes_r)

    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.current = true
    camera.fov = 70.0
    add_child(camera)

func _hand(n: String, parent: Node3D, pos: Vector3, out_fingers: Array[Node3D]) -> Node3D:
    var hand: Node3D = Node3D.new()
    hand.name = n
    hand.position = pos
    parent.add_child(hand)
    _sphere_mesh(n + "Palm", hand, Vector3.ZERO, Vector3(0.12,0.12,0.08), Color(0.50,0.36,0.28))
    for i: int in range(5):
        var finger: Node3D = _limb(n + "Finger" + str(i), hand, Vector3((float(i)-2.0)*0.035,-0.08,0), 0.12, 0.022, Color(0.52,0.37,0.29))
        out_fingers.append(finger)
    return hand

func _foot(n: String, parent: Node3D, pos: Vector3, out_toes: Array[Node3D]) -> Node3D:
    var foot: Node3D = Node3D.new()
    foot.name = n
    foot.position = pos
    parent.add_child(foot)
    _box_visual(n + "Shoe", foot, Vector3(0,0,-0.08), Vector3(0.22,0.13,0.43), Color(0.075,0.08,0.085))
    for i: int in range(4):
        var toe: Node3D = _limb(n + "Toe" + str(i), foot, Vector3((float(i)-1.5)*0.045,-0.02,-0.25), 0.09, 0.018, Color(0.43,0.31,0.25))
        out_toes.append(toe)
    return foot

func _limb(n: String, parent: Node3D, pos: Vector3, length: float, radius: float, color: Color) -> Node3D:
    var pivot: Node3D = Node3D.new()
    pivot.name = n
    pivot.position = pos
    parent.add_child(pivot)
    _capsule_mesh(n + "Mesh", pivot, Vector3(0,-length*0.5,0), length, radius, color)
    return pivot

func _capsule_mesh(n: String, parent: Node3D, pos: Vector3, length: float, radius: float, color: Color) -> MeshInstance3D:
    var mesh_node: MeshInstance3D = MeshInstance3D.new()
    mesh_node.name = n
    var mesh: CapsuleMesh = CapsuleMesh.new()
    mesh.height = length
    mesh.radius = radius
    mesh_node.mesh = mesh
    mesh_node.position = pos
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.68
    mesh_node.material_override = mat
    parent.add_child(mesh_node)
    return mesh_node

func _sphere_mesh(n: String, parent: Node3D, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    var node: MeshInstance3D = MeshInstance3D.new()
    node.name = n
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    node.mesh = mesh
    node.position = pos
    node.scale = scale_value
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.62
    node.material_override = mat
    parent.add_child(node)
    return node

func _cylinder_mesh(n: String, parent: Node3D, pos: Vector3, height: float, radius: float, color: Color) -> MeshInstance3D:
    var node: MeshInstance3D = MeshInstance3D.new()
    node.name = n
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.height = height
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    node.mesh = mesh
    node.position = pos
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.7
    node.material_override = mat
    parent.add_child(node)
    return node

func _box_visual(n: String, parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node: MeshInstance3D = MeshInstance3D.new()
    node.name = n
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.7
    node.material_override = mat
    parent.add_child(node)
    return node

func _build_ui() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    state_label = Label.new()
    state_label.position = Vector2(24,22)
    state_label.add_theme_font_size_override("font_size",18)
    layer.add_child(state_label)
    speed_label = Label.new()
    speed_label.position = Vector2(24,54)
    speed_label.add_theme_font_size_override("font_size",15)
    layer.add_child(speed_label)

func _physics_process(delta: float) -> void:
    if player == null:
        return

    var input_vec: Vector2 = Input.get_vector("move_left","move_right","move_forward","move_back")
    var cam_forward: Vector3 = -Basis(Vector3.UP,camera_yaw).z
    var cam_right: Vector3 = Basis(Vector3.UP,camera_yaw).x
    var move_dir: Vector3 = (cam_right * input_vec.x + cam_forward * input_vec.y).normalized()

    if Input.is_action_just_pressed("reset"):
        _reset_player()
        return

    if vaulting:
        _update_vault(delta)
    elif climbing:
        _update_climb(move_dir,delta)
    elif wall_running:
        _update_wall_run(move_dir,delta)
    else:
        _update_ground(move_dir,delta)
        _detect_parkour(move_dir)

    player.velocity = velocity
    player.move_and_slide()

    if not player.is_on_floor():
        fall_speed = min(fall_speed + gravity * delta,30.0)
    else:
        fall_speed = 0.0

    var on_floor_now: bool = player.is_on_floor()
    if on_floor_now and not was_on_floor:
        _land()
    was_on_floor = on_floor_now

    if player.position.y < -15.0:
        _reset_player()

func _update_ground(move_dir: Vector3, delta: float) -> void:
    var speed_limit: float = run_speed if Input.is_action_pressed("run") else walk_speed
    var target: Vector3 = move_dir * speed_limit
    var accel: float = acceleration if player.is_on_floor() else air_acceleration

    velocity.x = move_toward(velocity.x,target.x,accel*delta)
    velocity.z = move_toward(velocity.z,target.z,accel*delta)

    if player.is_on_floor():
        velocity.y = -1.0
        if Input.is_action_just_pressed("jump"):
            var horizontal_speed: float = Vector3(velocity.x,0,velocity.z).length()
            velocity.y = jump_power + clamp(horizontal_speed*0.18,0.0,2.2)
    else:
        velocity.y -= gravity*delta

    if move_dir.length() > 0.08:
        var target_yaw: float = atan2(-move_dir.x,-move_dir.z)
        player.rotation.y = lerp_angle(player.rotation.y,target_yaw,delta*11.0)

func _detect_parkour(move_dir: Vector3) -> void:
    if not Input.is_action_pressed("grab"):
        return
    if move_dir.length() < 0.1:
        return

    var origin: Vector3 = player.global_position + Vector3.UP*1.0
    var wall_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin,origin + move_dir*0.95)
    wall_query.exclude = [player]
    var wall_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(wall_query)

    if wall_hit.is_empty():
        return

    var normal: Vector3 = wall_hit["normal"]
    if absf(normal.y) > 0.25:
        return

    var wall_point: Vector3 = wall_hit["position"]
    var top_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        wall_point + Vector3.UP*max_climb_height + move_dir*0.15,
        wall_point + Vector3.DOWN*0.25 + move_dir*0.15
    )
    top_query.exclude = [player]
    var top_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(top_query)

    if top_hit.is_empty():
        _start_wall_run(normal,move_dir)
        return

    var top_y: float = float(top_hit["position"].y)
    climb_height = top_y - player.global_position.y

    if climb_height > 0.55 and climb_height <= max_climb_height:
        if climb_height <= 1.35 and player.is_on_floor():
            _start_vault(normal,top_hit["position"])
        elif Input.is_action_pressed("grab"):
            _start_climb(normal,climb_height)

func _start_climb(normal: Vector3, height: float) -> void:
    climbing = true
    wall_running = false
    climb_timer = 0.0
    wall_normal = normal
    climb_height = height
    velocity = Vector3.ZERO
    parkour_state = "climb"

func _update_climb(move_dir: Vector3, delta: float) -> void:
    climb_timer += delta
    var lateral: Vector3 = move_dir - wall_normal * move_dir.dot(wall_normal)
    var vertical_input: float = 0.0
    if Input.is_action_pressed("move_forward"):
        vertical_input += 1.0
    if Input.is_action_pressed("move_back"):
        vertical_input -= 0.65

    var climb_speed: float = 2.7
    velocity = lateral * 1.7 + Vector3.UP * vertical_input * climb_speed

    # Keep the torso close to the surface.
    var desired_position: Vector3 = player.global_position - wall_normal*0.18
    player.global_position = player.global_position.lerp(desired_position,1.0-exp(-delta*12.0))

    if not Input.is_action_pressed("grab"):
        climbing = false
        climb_timer = 0.0
        velocity = -wall_normal*2.2 + Vector3.UP*3.5
        parkour_state = "air"
        return

    if climb_timer > 0.22:
        var ledge_check: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
            player.global_position + Vector3.UP*1.7 - wall_normal*0.1,
            player.global_position + Vector3.UP*1.7 - wall_normal*0.1 + Vector3.UP*0.5
        )
        ledge_check.exclude = [player]
        var ledge: Dictionary = get_world_3d().direct_space_state.intersect_ray(ledge_check)
        if ledge.is_empty() and vertical_input > 0.0:
            climbing = false
            velocity = -wall_normal*1.2 + Vector3.UP*4.8
            parkour_state = "ledge"

func _start_wall_run(normal: Vector3, move_dir: Vector3) -> void:
    var side_dot: float = absf(normal.dot(Vector3.UP))
    if side_dot > 0.2:
        return
    wall_running = true
    wall_run_timer = 0.0
    wall_normal = normal
    velocity = move_dir*7.0 + Vector3.UP*3.0
    parkour_state = "wall_run"

func _update_wall_run(move_dir: Vector3, delta: float) -> void:
    wall_run_timer += delta
    var tangent: Vector3 = move_dir - wall_normal*move_dir.dot(wall_normal)
    velocity = tangent.normalized()*7.0 + Vector3.UP*2.2
    if Input.is_action_just_pressed("jump"):
        wall_running = false
        velocity = wall_normal*5.5 + Vector3.UP*6.4
        parkour_state = "air"
    elif wall_run_timer > 0.85 or not Input.is_action_pressed("grab"):
        wall_running = false
        velocity += Vector3.UP*1.5
        parkour_state = "air"

func _start_vault(normal: Vector3, top_point: Vector3) -> void:
    vaulting = true
    vault_timer = 0.0
    vault_start = player.global_position
    vault_end = top_point + Vector3.UP*1.0 - normal*0.9
    velocity = Vector3.ZERO
    parkour_state = "vault"

func _update_vault(delta: float) -> void:
    vault_timer += delta
    var t: float = clamp(vault_timer/0.48,0.0,1.0)
    var smooth_t: float = t*t*(3.0-2.0*t)
    var pos: Vector3 = vault_start.lerp(vault_end,smooth_t)
    pos.y += sin(t*PI)*0.65
    player.global_position = pos
    if t >= 1.0:
        vaulting = false
        velocity = -player.basis.z*2.0
        parkour_state = "run"

func _land() -> void:
    if fall_speed > 10.0:
        landing_timer = 0.32
        parkour_state = "hard_land"
    else:
        landing_timer = 0.18
        parkour_state = "land"

func _process(delta: float) -> void:
    if landing_timer > 0.0:
        landing_timer -= delta
    _animate_character(delta)
    _update_camera(delta)
    _update_ui()

func _animate_character(delta: float) -> void:
    if rig == null:
        return

    var horizontal_velocity: Vector3 = Vector3(velocity.x,0,velocity.z)
    var speed: float = horizontal_velocity.length()
    var grounded: bool = player.is_on_floor()
    var t: float = Time.get_ticks_msec()*0.001

    # Reset/relax all joints smoothly every render frame.
    var relax: float = min(delta*13.0,1.0)
    if grounded and speed > 0.35 and not climbing and not vaulting:
        step_phase += delta*(6.0 + speed*0.9)
    else:
        step_phase += delta*1.4

    var stride: float = sin(step_phase)
    var opposite: float = sin(step_phase+PI)
    var bounce: float = absf(cos(step_phase*0.5))*0.025 if grounded else 0.0

    pelvis.position.y = lerp(pelvis.position.y,0.88+bounce,relax)

    if climbing:
        _pose_climb(delta)
    elif vaulting:
        _pose_vault(delta)
    elif wall_running:
        _pose_wall_run(delta)
    elif landing_timer > 0.0:
        _pose_landing(delta)
    elif not grounded:
        _pose_air(delta)
    elif speed > 6.8:
        _pose_run(stride,opposite,delta)
    elif speed > 0.35:
        _pose_walk(stride,opposite,delta)
    else:
        _pose_idle(t,delta)

    # Head follows camera pitch and yaw independently of body.
    var local_camera_yaw: float = wrapf(camera_yaw-player.rotation.y,-PI,PI)
    head.rotation.y = lerp_angle(head.rotation.y,clamp(local_camera_yaw,-1.25,1.25),min(delta*9.0,1.0))
    head.rotation.x = lerp(head.rotation.x,clamp(camera_pitch*0.72,-0.58,0.34),min(delta*9.0,1.0))
    chest.rotation.y = lerp(chest.rotation.y,local_camera_yaw*0.10,min(delta*5.0,1.0))

func _pose_idle(t: float, delta: float) -> void:
    idle_phase += delta
    var breathe: float = sin(idle_phase*2.0)*0.012
    chest.rotation.x = lerp(chest.rotation.x,breathe,delta*4.0)
    upper_arm_l.rotation = upper_arm_l.rotation.lerp(Vector3(0,0,0.03),delta*5.0)
    upper_arm_r.rotation = upper_arm_r.rotation.lerp(Vector3(0,0,-0.03),delta*5.0)
    forearm_l.rotation = forearm_l.rotation.lerp(Vector3(-0.08,0,0),delta*5.0)
    forearm_r.rotation = forearm_r.rotation.lerp(Vector3(-0.08,0,0),delta*5.0)
    thigh_l.rotation = thigh_l.rotation.lerp(Vector3(0,0,0),delta*5.0)
    thigh_r.rotation = thigh_r.rotation.lerp(Vector3(0,0,0),delta*5.0)
    shin_l.rotation = shin_l.rotation.lerp(Vector3(0,0,0),delta*5.0)
    shin_r.rotation = shin_r.rotation.lerp(Vector3(0,0,0),delta*5.0)

func _pose_walk(a: float, b: float, delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,0.025,delta*8.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,a*0.48,delta*12.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,b*0.48,delta*12.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.10-absf(a)*0.12,delta*12.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.10-absf(b)*0.12,delta*12.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,b*0.62,delta*12.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,a*0.62,delta*12.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,max(0.0,-b)*0.55,delta*12.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,max(0.0,-a)*0.55,delta*12.0)
    foot_l.rotation.x = lerp(foot_l.rotation.x,-b*0.18,delta*12.0)
    foot_r.rotation.x = lerp(foot_r.rotation.x,-a*0.18,delta*12.0)
    _animate_fingers(delta,0.08)

func _pose_run(a: float, b: float, delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,0.12,delta*10.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,a*0.82-0.18,delta*15.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,b*0.82-0.18,delta*15.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.35-absf(a)*0.22,delta*15.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.35-absf(b)*0.22,delta*15.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,b*0.92,delta*15.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,a*0.92,delta*15.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,max(0.0,-b)*0.95,delta*15.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,max(0.0,-a)*0.95,delta*15.0)
    foot_l.rotation.x = lerp(foot_l.rotation.x,-b*0.28,delta*15.0)
    foot_r.rotation.x = lerp(foot_r.rotation.x,-a*0.28,delta*15.0)
    _animate_fingers(delta,0.18)

func _pose_air(delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,clamp(-velocity.y*0.025,-0.16,0.22),delta*5.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,-0.28,delta*6.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,-0.28,delta*6.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.38,delta*6.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.38,delta*6.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,0.22,delta*5.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,0.22,delta*5.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,-0.35,delta*5.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,-0.35,delta*5.0)
    _animate_fingers(delta,0.35)

func _pose_climb(delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,-0.10,delta*10.0)
    upper_arm_l.rotation = upper_arm_l.rotation.lerp(Vector3(-1.12,0.18,0),delta*10.0)
    upper_arm_r.rotation = upper_arm_r.rotation.lerp(Vector3(-1.12,-0.18,0),delta*10.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.45,delta*10.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.45,delta*10.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,0.55,delta*10.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,-0.35,delta*10.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,-0.65,delta*10.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,0.45,delta*10.0)
    _animate_fingers(delta,0.7)

func _pose_wall_run(delta: float) -> void:
    chest.rotation.z = lerp(chest.rotation.z,clamp(wall_normal.x*0.3,-0.25,0.25),delta*8.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,-0.8,delta*8.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,-0.8,delta*8.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.3,delta*8.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.3,delta*8.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,0.45,delta*8.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,-0.45,delta*8.0)

func _pose_vault(delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,-0.22,delta*12.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,-1.05,delta*12.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,-1.05,delta*12.0)
    forearm_l.rotation.x = lerp(forearm_l.rotation.x,-0.25,delta*12.0)
    forearm_r.rotation.x = lerp(forearm_r.rotation.x,-0.25,delta*12.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,0.55,delta*12.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,0.55,delta*12.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,-0.45,delta*12.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,-0.45,delta*12.0)
    _animate_fingers(delta,0.8)

func _pose_landing(delta: float) -> void:
    chest.rotation.x = lerp(chest.rotation.x,0.28,delta*14.0)
    thigh_l.rotation.x = lerp(thigh_l.rotation.x,-0.48,delta*14.0)
    thigh_r.rotation.x = lerp(thigh_r.rotation.x,-0.48,delta*14.0)
    shin_l.rotation.x = lerp(shin_l.rotation.x,0.72,delta*14.0)
    shin_r.rotation.x = lerp(shin_r.rotation.x,0.72,delta*14.0)
    upper_arm_l.rotation.x = lerp(upper_arm_l.rotation.x,-0.65,delta*14.0)
    upper_arm_r.rotation.x = lerp(upper_arm_r.rotation.x,-0.65,delta*14.0)

func _animate_fingers(delta: float, curl: float) -> void:
    for i: int in fingers_l.size():
        fingers_l[i].rotation.x = lerp(fingers_l[i].rotation.x,-curl,delta*10.0)
    for i: int in fingers_r.size():
        fingers_r[i].rotation.x = lerp(fingers_r[i].rotation.x,-curl,delta*10.0)
    for i: int in toes_l.size():
        toes_l[i].rotation.x = lerp(toes_l[i].rotation.x,curl*0.18,delta*10.0)
    for i: int in toes_r.size():
        toes_r[i].rotation.x = lerp(toes_r[i].rotation.x,curl*0.18,delta*10.0)

func _update_camera(delta: float) -> void:
    if camera == null:
        return
    var focus: Vector3 = player.global_position + Vector3.UP*1.28
    var rotation_basis: Basis = Basis(Vector3.UP,camera_yaw)
    var offset: Vector3 = rotation_basis * Vector3(0,camera_height,camera_distance)
    var desired: Vector3 = player.global_position + offset
    camera.global_position = camera.global_position.lerp(desired,1.0-exp(-delta*10.0))
    camera.look_at(focus,Vector3.UP)
    camera.rotation.x += camera_pitch
    camera.fov = lerp(camera.fov,74.0 + min(Vector3(velocity.x,0,velocity.z).length()*1.2,10.0),delta*4.0)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        camera_yaw -= event.relative.x*0.0026
        camera_pitch = clamp(camera_pitch-event.relative.y*0.0020,-0.75,0.35)
    if event.is_action_pressed("reset"):
        _reset_player()

func _update_ui() -> void:
    if state_label == null:
        return
    var speed: float = Vector3(velocity.x,0,velocity.z).length()
    state_label.text = "REAL PARKOUR PHYSICS  |  WASD mover  SHIFT correr  ESPAÇO saltar  F agarrar/escalar  R reset"
    speed_label.text = "Estado: %s    Velocidade: %.1f m/s    Parede máxima: %.1f m" % [parkour_state,speed,max_climb_height]

func _reset_player() -> void:
    climbing = false
    wall_running = false
    vaulting = false
    velocity = Vector3.ZERO
    player.global_position = Vector3(0,1.15,18)
    player.rotation = Vector3.ZERO
    parkour_state = "idle"

func _box_static(n: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = n
    body.position = pos
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

    var visual_box: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    visual_box.mesh = mesh
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    visual_box.material_override = mat
    body.add_child(visual_box)
    return body
