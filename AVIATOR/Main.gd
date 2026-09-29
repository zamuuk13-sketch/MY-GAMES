extends Node2D

const SAVE_PATH := "user://aviator_save.json"
const MAX_LEVEL := 10
const PLAYER_ID := 0

var rng := RandomNumberGenerator.new()
var state := "menu"
var nation := ""
var enemy_nation := ""
var level := 1
var xp := 0
var credits := 0
var research := 0
var selected_plane := "starter"
var unlocked_planes: Array[String] = []
var upgrades := {"speed":0,"armor":0,"firepower":0,"handling":0}

var player := {}
var allies: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var clouds: Array[Dictionary] = []

var mission_kills := 0
var mission_damage := 0.0
var mission_time := 0.0
var mission_goal := 2
var mission_started := false
var shake := 0.0
var message := ""
var message_timer := 0.0
var menu_phase := 0.0
var selected_menu := 0

var font: Font

func _ready() -> void:
    rng.seed = 20260929
    font = ThemeDB.fallback_font
    _load_game()
    for i: int in range(20):
        clouds.append({"p":Vector2(rng.randf_range(-300,1580),rng.randf_range(70,620)),"s":rng.randf_range(0.5,1.5),"a":rng.randf_range(0.15,0.45)})
    queue_redraw()

func _process(delta: float) -> void:
    menu_phase += delta
    if message_timer > 0:
        message_timer -= delta
    if state == "battle":
        _battle_update(delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var key: Key = event.keycode
        if state == "nation":
            if key == KEY_1:
                _choose_nation("USA")
            elif key == KEY_2:
                _choose_nation("RUSSIA")
        elif state == "battle":
            if key == KEY_ESCAPE:
                state = "menu"
            elif key == KEY_SPACE:
                _fire()
            elif key == KEY_E:
                _special()
        elif state == "results":
            if key == KEY_ENTER or key == KEY_SPACE:
                state = "hangar"
        elif state == "hangar":
            if key == KEY_ESCAPE:
                state = "menu"
            elif key == KEY_ENTER:
                _upgrade("firepower")
        elif state == "menu":
            if key == KEY_ENTER or key == KEY_SPACE:
                if selected_menu == 0:
                    if nation == "":
                        state = "nation"
                    else:
                        _start_battle()
                elif selected_menu == 1:
                    state = "hangar"
                elif selected_menu == 2:
                    message = "Configurações: controles WASD / SHIFT / CTRL / ESPAÇO / E"
                    message_timer = 4.0
            elif key == KEY_UP:
                selected_menu = max(0,selected_menu-1)
            elif key == KEY_DOWN:
                selected_menu = min(2,selected_menu+1)
        elif state == "gameover":
            if key == KEY_ENTER:
                state = "menu"

func _choose_nation(value: String) -> void:
    nation = value
    enemy_nation = "RUSSIA" if value == "USA" else "USA"
    unlocked_planes = ["starter"]
    level = 1
    xp = 0
    credits = 500
    research = 0
    upgrades = {"speed":0,"armor":0,"firepower":0,"handling":0}
    _save_game()
    state = "menu"
    message = "Nação escolhida: " + ("ESTADOS UNIDOS" if value == "USA" else "RÚSSIA")
    message_timer = 3.0

func _start_battle() -> void:
    if nation == "":
        state = "nation"
        return
    state = "battle"
    mission_started = true
    mission_kills = 0
    mission_damage = 0
    mission_time = 0
    mission_goal = 2 if level == 1 else min(2 + level,8)
    player = _make_plane(PLAYER_ID,true,Vector2(380,360))
    player["hp"] = player["max_hp"]
    allies.clear()
    enemies.clear()
    bullets.clear()
    particles.clear()
    for i: int in range(2):
        allies.append(_make_plane(10+i,false,Vector2(260+i*85,250+i*180)))
    for i: int in range(3 if level == 1 else 4 + level/3):
        enemies.append(_make_plane(20+i,false,Vector2(850+rng.randf_range(-100,180),180+i*130)))
    message = "FASE %d — PRIMEIRO COMBATE" % level if level == 1 else "MISSÃO %d" % level
    message_timer = 2.5

func _make_plane(id: int, friendly: bool, pos: Vector2) -> Dictionary:
    var nation_name: String = nation if friendly or id < 20 else enemy_nation
    var tier: int = max(0,level-1)
    var stats := {
        "speed": 240.0 + tier*9.0,
        "accel": 105.0 + tier*3.0,
        "handling": 2.2 + tier*0.08,
        "max_hp": 100.0 + tier*12.0,
        "armor": 5.0 + tier*1.5,
        "firepower": 14.0 + tier*2.0,
        "range": 390.0,
        "ammo": 80.0
    }
    if nation_name == "RUSSIA":
        stats["armor"] += 7
        stats["firepower"] += 2
    else:
        stats["speed"] += 12
        stats["handling"] += 0.15
    stats["speed"] += upgrades["speed"]*12
    stats["armor"] += upgrades["armor"]*4
    stats["firepower"] += upgrades["firepower"]*3
    stats["handling"] += upgrades["handling"]*0.1
    return {
        "id":id,"friendly":friendly,"pos":pos,"vel":Vector2(80 if friendly else -80,0),
        "hp":stats["max_hp"],"max_hp":stats["max_hp"],"speed":stats["speed"],
        "accel":stats["accel"],"handling":stats["handling"],"armor":stats["armor"],
        "firepower":stats["firepower"],"range":stats["range"],"ammo":stats["ammo"],
        "cooldown":0.0,"special":1,"ai":rng.randi_range(0,2),"phase":rng.randf_range(0,6.28),
        "damage_taken":0.0
    }

func _battle_update(delta: float) -> void:
    mission_time += delta
    _update_player(delta)
    _update_ai(allies,delta)
    _update_ai(enemies,delta)
    _update_bullets(delta)
    _update_particles(delta)
    if player["hp"] <= 0:
        state = "gameover"
        mission_started = false
        _save_game()
        return
    if mission_kills >= mission_goal:
        _finish_mission()

func _update_player(delta: float) -> void:
    var dir := Input.get_vector("move_left","move_right","move_up","move_down")
    var target: Vector2 = dir * float(player["speed"])
    var accel: float = float(player["accel"]) * delta
    player["vel"] = Vector2(
        move_toward(player["vel"].x,target.x,accel),
        move_toward(player["vel"].y,target.y,accel)
    )
    if Input.is_action_pressed("accelerate"):
        player["vel"] = player["vel"].lerp(player["vel"].normalized()*player["speed"]*1.35,delta*2.5)
    if Input.is_action_pressed("brake"):
        player["vel"] *= max(0.0,1.0-delta*2.8)
    player["pos"] += player["vel"]*delta
    player["pos"].x = clamp(player["pos"].x,80.0,1200.0)
    player["pos"].y = clamp(player["pos"].y,100.0,620.0)
    player["cooldown"] = max(0.0,player["cooldown"]-delta)

func _update_ai(group: Array[Dictionary], delta: float) -> void:
    for i: int in range(group.size()-1,-1,-1):
        var p := group[i]
        if p["hp"] <= 0:
            group.remove_at(i)
            continue
        var target: Dictionary = {}
        if p["friendly"]:
            if enemies.size() > 0:
                target = _nearest(p["pos"],enemies)
        else:
            target = player
        if target.is_empty():
            continue
        var to_target: Vector2 = target["pos"] - p["pos"]
        var distance := to_target.length()
        var desired: Vector2 = to_target.normalized() * float(p["speed"]) * (0.65 if p["ai"] == 0 else 0.9)
        if p["ai"] == 2:
            var perpendicular := Vector2(-to_target.y,to_target.x).normalized()
            desired += perpendicular*sin(Time.get_ticks_msec()*0.002+p["phase"])*p["speed"]*0.35
        p["vel"] = p["vel"].lerp(desired,delta*p["handling"])
        p["pos"] += p["vel"]*delta
        p["pos"].x = clamp(p["pos"].x,60.0,1220.0)
        p["pos"].y = clamp(p["pos"].y,70.0,650.0)
        p["cooldown"] = max(0.0,p["cooldown"]-delta)
        if distance < p["range"] and p["cooldown"] <= 0 and p["ammo"] > 0:
            _shoot_from(p,target)
            p["cooldown"] = 0.55 if p["ai"] == 0 else 0.38
            p["ammo"] -= 1
        group[group.find(p)] = p

func _nearest(pos: Vector2, group: Array[Dictionary]) -> Dictionary:
    var best: Dictionary = {}
    var best_d := INF
    for p: Dictionary in group:
        var d: float = pos.distance_to(p["pos"])
        if d < best_d:
            best_d = d
            best = p
    return best

func _fire() -> void:
    if state != "battle" or player["cooldown"] > 0 or player["ammo"] <= 0:
        return
    var target: Dictionary = _nearest(player["pos"],enemies)
    if target.is_empty():
        return
    _shoot_from(player,target)
    player["cooldown"] = 0.16
    player["ammo"] -= 1

func _shoot_from(source: Dictionary,target: Dictionary) -> void:
    var direction: Vector2 = (target["pos"]-source["pos"]).normalized()
    bullets.append({"pos":source["pos"]+direction*25,"vel":direction*560,"friendly":source["friendly"],"damage":source["firepower"],"life":1.2})
    for j: int in range(3):
        particles.append({"pos":source["pos"]+direction*28,"vel":-direction*rng.randf_range(30,90)+Vector2(rng.randf_range(-30,30),rng.randf_range(-30,30)),"life":0.16,"kind":0})

func _special() -> void:
    if state != "battle" or player["special"] <= 0:
        return
    player["special"] -= 1
    var target: Dictionary = _nearest(player["pos"],enemies)
    if target.is_empty():
        return
    var direction: Vector2 = (target["pos"]-player["pos"]).normalized()
    bullets.append({"pos":player["pos"],"vel":direction*760,"friendly":true,"damage":player["firepower"]*3.5,"life":1.5,"special":true})
    message = "MÍSSIL ESPECIAL LANÇADO!"
    message_timer = 1.2

func _update_bullets(delta: float) -> void:
    for i: int in range(bullets.size()-1,-1,-1):
        var b: Dictionary = bullets[i]
        b["pos"] += b["vel"]*delta
        b["life"] -= delta
        var hit := false
        if b["friendly"]:
            for j: int in range(enemies.size()-1,-1,-1):
                if b["pos"].distance_to(enemies[j]["pos"]) < 30:
                    _damage_plane(enemies[j],float(b["damage"]))
                    enemies[j]["damage_taken"] += float(b["damage"])
                    if enemies[j]["hp"] <= 0:
                        mission_kills += 1
                        xp += 100
                        credits += 80
                        research += 15
                        _explode(enemies[j]["pos"])
                        enemies.remove_at(j)
                    hit = true
                    break
        else:
            if b["pos"].distance_to(player["pos"]) < 28:
                _damage_player(float(b["damage"]))
                hit = true
        if b["life"] <= 0 or hit:
            bullets.remove_at(i)
        else:
            bullets[i] = b

func _damage_plane(p: Dictionary, amount: float) -> void:
    p["hp"] -= max(1.0,amount-p["armor"]*0.35)

func _damage_player(amount: float) -> void:
    var real_damage := max(1.0,amount-player["armor"]*0.35)
    player["hp"] -= real_damage
    mission_damage += real_damage
    shake = 0.16

func _explode(pos: Vector2) -> void:
    for i: int in range(22):
        var a := rng.randf_range(0,TAU)
        particles.append({"pos":pos,"vel":Vector2(cos(a),sin(a))*rng.randf_range(60,240),"life":rng.randf_range(0.3,0.8),"kind":1})
    message = "INIMIGO ABATIDO!"
    message_timer = 0.7

func _update_particles(delta: float) -> void:
    for i: int in range(particles.size()-1,-1,-1):
        particles[i]["pos"] += particles[i]["vel"]*delta
        particles[i]["vel"] *= 0.96
        particles[i]["life"] -= delta
        if particles[i]["life"] <= 0:
            particles.remove_at(i)

func _finish_mission() -> void:
    state = "results"
    mission_started = false
    var bonus := 250 + level*80
    xp += bonus
    credits += bonus
    research += 25
    if level == 1:
        unlocked_planes.append("fighter_mk2")
    if xp >= level*500 and level < MAX_LEVEL:
        level += 1
    _save_game()

func _upgrade(kind: String) -> void:
    var cost: int = 150 + int(upgrades[kind])*100
    if credits < cost:
        message = "Créditos insuficientes."
        message_timer = 2.0
        return
    credits -= cost
    upgrades[kind] += 1
    _save_game()
    message = "Melhoria aplicada: " + kind
    message_timer = 2.0

func _draw() -> void:
    if state == "menu":
        _draw_menu()
    elif state == "nation":
        _draw_nation()
    elif state == "battle":
        _draw_battle()
    elif state == "results":
        _draw_results()
    elif state == "hangar":
        _draw_hangar()
    elif state == "gameover":
        _draw_gameover()

func _draw_background() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#081322"))
    draw_rect(Rect2(0,0,1280,430),Color("#16345b"))
    draw_rect(Rect2(0,430,1280,290),Color("#102033"))
    for c: Dictionary in clouds:
        var p: Vector2 = c["p"]
        var s: float = c["s"]
        draw_circle(p,32*s,Color(0.75,0.85,0.95,c["a"]))
        draw_circle(p+Vector2(35*s,-5),42*s,Color(0.75,0.85,0.95,c["a"]))
        draw_circle(p+Vector2(-35*s,4),25*s,Color(0.75,0.85,0.95,c["a"]))

func _draw_menu() -> void:
    _draw_background()
    draw_rect(Rect2(0,0,1280,720),Color(0,0,0,0.18))
    draw_string(font,Vector2(90,150),"AVIATOR",HORIZONTAL_ALIGNMENT_LEFT,500,72,Color("#f4f7ff"))
    draw_string(font,Vector2(94,190),"SKY RPG  •  AIR COMBAT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#80a9d8"))
    var options := ["JOGAR","HANGAR","CONFIGURAÇÕES"]
    for i: int in range(options.size()):
        var y := 300.0+i*70
        var selected := i==selected_menu
        draw_rect(Rect2(88,y-38,300,54),Color("#2e75c8",0.8) if selected else Color("#172941",0.82),true)
        draw_string(font,Vector2(112,y),options[i],HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color.WHITE)
    draw_string(font,Vector2(92,545),"Nação: "+("ESCOLHA PENDENTE" if nation=="" else nation),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#b8c8da"))
    draw_string(font,Vector2(92,582),"Nível %d   •   XP %d   •   Créditos %d" % [level,xp,credits],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#8299b5"))
    draw_string(font,Vector2(90,665),"↑ ↓ selecionar    ENTER iniciar",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#637b99"))
    _draw_plane(Vector2(900,350),1.0,0.0,nation=="RUSSIA")
    if message_timer>0:
        draw_string(font,Vector2(90,625),message,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f4d47a"))

func _draw_nation() -> void:
    _draw_background()
    draw_string(font,Vector2(0,90),"ESCOLHA SUA NAÇÃO",HORIZONTAL_ALIGNMENT_CENTER,1280,44,Color.WHITE)
    _nation_card(Rect2(110,180,480,350),"🇺🇸 ESTADOS UNIDOS","Velocidade, resposta e manobrabilidade.",1)
    _nation_card(Rect2(690,180,480,350),"🇷🇺 RÚSSIA","Blindagem e poder de fogo.",2)
    draw_string(font,Vector2(0,610),"1 — Estados Unidos       2 — Rússia",HORIZONTAL_ALIGNMENT_CENTER,1280,22,Color("#a9bdd4"))

func _nation_card(rect: Rect2,title: String,desc: String,key: int) -> void:
    draw_rect(rect,Color("#14283e"),true)
    draw_rect(rect,Color("#356da5"),false,3)
    draw_string(font,rect.position+Vector2(30,65),title,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
    draw_string(font,rect.position+Vector2(30,115),desc,HORIZONTAL_ALIGNMENT_LEFT,410,18,Color("#b9cce0"))
    draw_string(font,rect.position+Vector2(30,235),"Selecionar: %d" % key,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#7db8ff"))

func _draw_battle() -> void:
    _draw_battle_background()
    for p: Dictionary in allies:
        _draw_plane(p["pos"],0.78,atan2(p["vel"].y,p["vel"].x),true)
    for p: Dictionary in enemies:
        _draw_plane(p["pos"],0.82,atan2(p["vel"].y,p["vel"].x),false)
    if not player.is_empty():
        _draw_plane(player["pos"],1.0,atan2(player["vel"].y,player["vel"].x),nation=="RUSSIA")
    for b: Dictionary in bullets:
        draw_circle(b["pos"],5.0,Color("#ffe37a"))
        draw_line(b["pos"],b["pos"]-b["vel"].normalized()*18,Color("#ffd24c",0.5),3)
    for p: Dictionary in particles:
        draw_circle(p["pos"],max(2.0,float(p["life"])*9),Color("#ff8d42",clamp(float(p["life"])*2,0,1)))
    _draw_hud()

func _draw_battle_background() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#75b7e8"))
    draw_rect(Rect2(0,520,1280,200),Color("#4d6e55"))
    for i: int in range(8):
        var x := float(i*190-50)
        draw_colored_polygon(PackedVector2Array([Vector2(x,520),Vector2(x+90,380-(i%3)*35),Vector2(x+180,520)]),Color("#3e5e55"))
    for c: Dictionary in clouds:
        var p: Vector2 = c["p"]
        draw_circle(p,30,Color(1,1,1,0.45))
        draw_circle(p+Vector2(35,-4),38,Color(1,1,1,0.4))

func _draw_plane(pos: Vector2, scale: float, angle: float, russian: bool) -> void:
    var transform: Transform2D = Transform2D(angle,pos)
    var body := PackedVector2Array([Vector2(35,0),Vector2(8,-10),Vector2(-24,-7),Vector2(-34,0),Vector2(-24,7),Vector2(8,10)])
    var wing := PackedVector2Array([Vector2(6,0),Vector2(-7,-28),Vector2(-18,-26),Vector2(-5,0),Vector2(-18,26),Vector2(-7,28)])
    var tail := PackedVector2Array([Vector2(-18,0),Vector2(-31,-16),Vector2(-25,-3),Vector2(-25,3),Vector2(-31,16)])
    var col := Color("#d8e0e8") if russian else Color("#d9d9d2")
    draw_set_transform(pos,angle,Vector2.ONE*scale)
    draw_colored_polygon(body,col)
    draw_colored_polygon(wing,Color("#566879"))
    draw_colored_polygon(tail,Color("#4b5e70"))
    draw_circle(Vector2(10,0),4,Color("#6fa4d8"))
    draw_line(Vector2(-36,0),Vector2(-52,0),Color("#e8f1ff",0.65),3)
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_hud() -> void:
    var hp_ratio: float = clamp(float(player["hp"])/float(player["max_hp"]),0.0,1.0)
    draw_rect(Rect2(22,20,270,70),Color(0.03,0.07,0.12,0.86),true)
    draw_string(font,Vector2(38,47),"AVIATOR  •  NÍVEL %d" % level,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_rect(Rect2(38,58,210,10),Color("#26394c"),true)
    draw_rect(Rect2(38,58,210*hp_ratio,10),Color("#4bd58c"),true)
    draw_string(font,Vector2(38,84),"MUNIÇÃO %d   ALVOS %d/%d" % [int(player["ammo"]),mission_kills,mission_goal],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#bdd0e4"))
    draw_rect(Rect2(930,20,328,120),Color(0.03,0.07,0.12,0.82),true)
    draw_string(font,Vector2(950,50),"FASE %d — %s" % [level,"PRIMEIRO COMBATE" if level==1 else "MISSÃO"],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_string(font,Vector2(950,78),"Objetivo: abater %d inimigos" % mission_goal,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#c6d5e6"))
    draw_string(font,Vector2(950,103),"Velocidade: %d" % int(player["vel"].length()),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#c6d5e6"))
    draw_string(font,Vector2(950,127),"WASD mover  •  ESPAÇO atirar  •  E especial",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#87b9ed"))
    if message_timer>0:
        draw_rect(Rect2(390,22,500,48),Color(0.04,0.08,0.13,0.85),true)
        draw_string(font,Vector2(410,53),message,HORIZONTAL_ALIGNMENT_LEFT,460,19,Color("#ffe29a"))

func _draw_results() -> void:
    _draw_background()
    draw_rect(Rect2(260,100,760,510),Color("#10243a"),true)
    draw_rect(Rect2(260,100,760,510),Color("#4a78a8"),false,3)
    draw_string(font,Vector2(0,175),"MISSÃO CONCLUÍDA",HORIZONTAL_ALIGNMENT_CENTER,1280,42,Color("#7ff0a9"))
    draw_string(font,Vector2(330,250),"XP recebido: +%d" % (250+level*80),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(font,Vector2(330,292),"Créditos: +%d" % (250+level*80),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(font,Vector2(330,334),"Inimigos abatidos: %d" % mission_kills,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(font,Vector2(330,376),"Tempo de missão: %.1f s" % mission_time,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(font,Vector2(330,418),"Dano recebido: %.0f" % mission_damage,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(font,Vector2(330,475),"RECOMPENSA: " + ("NOVO AVIÃO DESBLOQUEADO!" if level==1 else "Pontos de pesquisa"),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ffd878"))
    draw_string(font,Vector2(0,565),"ENTER / ESPAÇO — voltar ao hangar",HORIZONTAL_ALIGNMENT_CENTER,1280,17,Color("#9eb5ce"))

func _draw_hangar() -> void:
    _draw_background()
    draw_string(font,Vector2(60,90),"HANGAR",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color.WHITE)
    draw_string(font,Vector2(60,126),"Nação: "+nation+"   •   Nível "+str(level),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#9db8d3"))
    draw_rect(Rect2(55,165,540,430),Color("#102238"),true)
    _draw_plane(Vector2(325,360),2.2,0,nation=="RUSSIA")
    draw_string(font,Vector2(650,205),"CAÇA ATUAL",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color.WHITE)
    draw_string(font,Vector2(650,250),"Velocidade       %d" % int(player.get("speed",240)),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bdd0e4"))
    draw_string(font,Vector2(650,285),"Blindagem        %d" % int(player.get("armor",5)),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bdd0e4"))
    draw_string(font,Vector2(650,320),"Poder de fogo    %d" % int(player.get("firepower",14)),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bdd0e4"))
    draw_string(font,Vector2(650,355),"Manobrabilidade  %.1f" % float(player.get("handling",2.2)),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bdd0e4"))
    draw_string(font,Vector2(650,420),"ENTER: melhorar poder de fogo",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#7db8ff"))
    draw_string(font,Vector2(650,450),"Créditos: %d" % credits,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffd878"))
    draw_string(font,Vector2(650,520),"ESC: menu principal",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#829ab4"))

func _draw_gameover() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#090d15"))
    draw_string(font,Vector2(0,285),"AVIÃO PERDIDO",HORIZONTAL_ALIGNMENT_CENTER,1280,44,Color("#ff6f70"))
    draw_string(font,Vector2(0,340),"A missão terminou. ENTER para voltar ao menu.",HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#b5c4d6"))

func _save_game() -> void:
    var data: Dictionary = {"nation":nation,"level":level,"xp":xp,"credits":credits,"research":research,"unlocked_planes":unlocked_planes,"upgrades":upgrades}
    var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    nation = str(parsed.get("nation",""))
    enemy_nation = "RUSSIA" if nation=="USA" else "USA"
    level = int(parsed.get("level",1))
    xp = int(parsed.get("xp",0))
    credits = int(parsed.get("credits",0))
    research = int(parsed.get("research",0))
    unlocked_planes = Array(parsed.get("unlocked_planes",[]))
    var loaded_upgrades: Variant = parsed.get("upgrades",{})
    if typeof(loaded_upgrades)==TYPE_DICTIONARY:
        upgrades = loaded_upgrades
