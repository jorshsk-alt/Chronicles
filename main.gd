extends Node2D

# Prototipo independiente: no utiliza código ni recursos del ROM de Soul Blazer.
const W := 960.0
const H := 540.0
const WALK := 155.0
const RUN := 250.0
const RADIUS := 14.0
const MAPS := {
    "bosque": {"name":"Bosque de Océlotl", "ground":Color("568b57"), "exits":{"left":"aldea", "right":"cueva", "up":"templo"}},
    "aldea": {"name":"Aldea de Xochitlán", "ground":Color("a6ae69"), "exits":{"right":"bosque"}},
    "cueva": {"name":"Cueva del Jaguar", "ground":Color("777386"), "exits":{"left":"bosque"}},
    "templo": {"name":"Templo de Ehécatl", "ground":Color("a2b5a0"), "exits":{"down":"bosque"}}
}
var current_map := "aldea"
var hero := Vector2(480, 310)
var facing := Vector2.RIGHT
var hp := 5
var max_hp := 5
var enemies := []
var defeated := {}
var liberated := false
var dialog := "Habla con la anciana junto a la casa."
var dialog_time := 6.0
var attack_cooldown := 0.0
var slash_time := 0.0
var touch_move := Vector2.ZERO
var touch_run := false
var joystick_id := -1
var run_touch_id := -1
var joystick_start := Vector2.ZERO
var attack_requested := false
var font := ThemeDB.fallback_font

func _ready() -> void:
    _bind_key("move_left", [KEY_A, KEY_LEFT])
    _bind_key("move_right", [KEY_D, KEY_RIGHT])
    _bind_key("move_up", [KEY_W, KEY_UP])
    _bind_key("move_down", [KEY_S, KEY_DOWN])
    _bind_key("attack", [KEY_J, KEY_SPACE])
    _bind_key("run", [KEY_K, KEY_SHIFT])
    _enter_map("aldea", Vector2(480, 310))

func _bind_key(action:String, keys:Array) -> void:
    if not InputMap.has_action(action): InputMap.add_action(action)
    for key in keys:
        var event := InputEventKey.new()
        event.physical_keycode = key
        InputMap.action_add_event(action, event)

func _enter_map(id:String, pos:Vector2) -> void:
    current_map = id
    hero = pos
    enemies.clear()
    if id == "bosque":
        for i in range(3):
            if not defeated.has("bosque_%d" % i):
                enemies.append({"id":"bosque_%d" % i, "pos":Vector2(290 + i*180, 180 + (i%2)*170), "hp":2})
    elif id == "cueva" and not defeated.has("jaguar"):
        enemies.append({"id":"jaguar", "pos":Vector2(710,260), "hp":5})
    dialog = "Llegaste a " + MAPS[id]["name"]
    dialog_time = 2.5
    queue_redraw()

func _physics_process(delta:float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown-delta)
    slash_time = maxf(0.0, slash_time-delta)
    dialog_time = maxf(0.0, dialog_time-delta)
    var motion := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if touch_move.length() > 0.1:
        motion = touch_move
    if motion.length() > 0.05:
        facing = motion.normalized()
        var speed := RUN if Input.is_action_pressed("run") or touch_run else WALK
        var next := hero + motion.normalized()*speed*delta
        # Límites internos. Los bordes con salida permanecen abiertos.
        hero = next
        _check_exit()
    if Input.is_action_just_pressed("attack") or attack_requested:
        attack_requested = false
        _attack()
    queue_redraw()

func _check_exit() -> void:
    var exits:Dictionary = MAPS[current_map]["exits"]
    if hero.x < 22:
        if exits.has("left") and hero.y > 125 and hero.y < 425:
            _enter_map(exits["left"], Vector2(W-48, clampf(hero.y, 140, 400)))
        else: hero.x = 22
    elif hero.x > W-22:
        if exits.has("right") and hero.y > 125 and hero.y < 425:
            _enter_map(exits["right"], Vector2(48, clampf(hero.y, 140, 400)))
        else: hero.x = W-22
    if hero.y < 22:
        if exits.has("up") and hero.x > 330 and hero.x < 630:
            _enter_map(exits["up"], Vector2(clampf(hero.x, 345, 615), H-48))
        else: hero.y = 22
    elif hero.y > H-22:
        if exits.has("down") and hero.x > 330 and hero.x < 630:
            _enter_map(exits["down"], Vector2(clampf(hero.x, 345, 615), 48))
        else: hero.y = H-22

func _attack() -> void:
    if attack_cooldown > 0.0: return
    attack_cooldown = 0.35
    slash_time = 0.18
    if current_map == "aldea" and hero.distance_to(Vector2(640,260)) < 85:
        dialog = "Anciana: ¡Libera el bosque y recupera el viento sagrado!"
        dialog_time = 5.0
        return
    for i in range(enemies.size()-1, -1, -1):
        var e:Dictionary = enemies[i]
        var offset:Vector2 = e["pos"] - hero
        if offset.length() < 90 and (offset.length() < 30 or offset.normalized().dot(facing) > 0.15):
            e["hp"] -= 1
            if e["hp"] <= 0:
                defeated[e["id"]] = true
                enemies.remove_at(i)
                dialog = "¡Enemigo derrotado!"
                dialog_time = 1.7
            else:
                enemies[i] = e
    if current_map == "bosque" and enemies.is_empty() and not liberated:
        liberated = true
        dialog = "¡Has liberado a los habitantes del bosque!"
        dialog_time = 5.0

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H), MAPS[current_map]["ground"])
    # Senderos principales y caminos de salida coincidentes.
    draw_rect(Rect2(0,220,W,105), Color("c6b18a"))
    if current_map == "bosque":
        draw_rect(Rect2(430,0,100,270), Color("c6b18a"))
        for i in range(18):
            var p := Vector2(65 + (i*137)%830, 65 + (i*89)%405)
            if absf(p.y-270)>85 and not (p.x>400 and p.x<560):
                _tree(p)
    elif current_map == "aldea":
        _house(Vector2(185,115))
        _house(Vector2(490,105))
        _house(Vector2(750,355))
        _person(Vector2(640,260), Color("f0ca82"))
        _label("Anciana", Vector2(612,222), 17)
    elif current_map == "cueva":
        for i in range(9):
            var p := Vector2(110+i*90, 90+(i%3)*155)
            draw_colored_polygon(PackedVector2Array([p+Vector2(-27,26),p+Vector2(0,-31),p+Vector2(28,25)]), Color("504c61"))
    elif current_map == "templo":
        draw_rect(Rect2(340,80,280,190), Color("6d827b"))
        draw_rect(Rect2(380,110,200,130), Color("c6d0bb"))
        for i in range(4):
            draw_rect(Rect2(390+i*52,115,28,105), Color("7e9185"))
        _label("ALTAR DEL VIENTO", Vector2(377,68), 21)
    var exits:Dictionary = MAPS[current_map]["exits"]
    if exits.has("left"): _label("◀ ALDEA" if current_map=="bosque" else "◀ BOSQUE", Vector2(10,200),17)
    if exits.has("right"): _label("BOSQUE ▶" if current_map=="aldea" else "CUEVA ▶", Vector2(824,200),17)
    if exits.has("up"): _label("▲ TEMPLO", Vector2(442,37),17)
    if exits.has("down"): _label("▼ BOSQUE", Vector2(441,514),17)
    for e in enemies:
        draw_circle(e["pos"], 19, Color("a64b47") if e["id"]!="jaguar" else Color("4a354f"))
        draw_circle(e["pos"]+Vector2(-6,-4),3,Color.WHITE)
        draw_circle(e["pos"]+Vector2(6,-4),3,Color.WHITE)
        draw_rect(Rect2(e["pos"]+Vector2(-21,-32), Vector2(42*float(e["hp"])/(5.0 if e["id"]=="jaguar" else 2.0),5)),Color("efc55c"))
    _person(hero, Color("4e81c4"))
    if slash_time>0:
        draw_arc(hero+facing*32,25,atan2(facing.y,facing.x)-0.85,atan2(facing.y,facing.x)+0.85,18,Color("fce69c"),6)
    draw_rect(Rect2(8,8,285,71),Color(0.07,0.12,0.16,0.83))
    _label("LEO  |  PV: %d/%d" % [hp,max_hp],Vector2(21,34),22)
    _label(MAPS[current_map]["name"],Vector2(21,62),18)
    if dialog_time>0:
        draw_rect(Rect2(170,446,620,65),Color(0.08,0.13,0.18,0.9))
        _label(dialog,Vector2(184,486),19)
    # Controles táctiles, con posiciones fijas en pantalla.
    draw_circle(Vector2(95,426),68,Color(0.1,0.14,0.16,0.32))
    draw_arc(Vector2(95,426),68,0,TAU,48,Color(1,1,1,0.35),3)
    draw_circle(Vector2(95,426)+touch_move*34,23,Color(0.9,0.92,0.9,0.58))
    _button(Vector2(851,374),"A",Color("4b789d"))
    _button(Vector2(763,438),"B",Color("9c6947"))

func _label(s:String,p:Vector2,size:int=20) -> void:
    draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color.WHITE)

func _person(p:Vector2,c:Color) -> void:
    draw_circle(p+Vector2(0,8),16,Color(0,0,0,0.22))
    draw_rect(Rect2(p+Vector2(-12,-6),Vector2(24,31)),c)
    draw_circle(p+Vector2(0,-16),12,Color("efc89d"))
    draw_rect(Rect2(p+Vector2(-11,-28),Vector2(22,9)),Color("40372f"))

func _tree(p:Vector2) -> void:
    draw_rect(Rect2(p.x-5,p.y-5,10,30),Color("674b36"))
    draw_circle(p+Vector2(0,-15),25,Color("2f6846"))
    draw_circle(p+Vector2(-11,-20),14,Color("408356"))

func _house(p:Vector2) -> void:
    draw_rect(Rect2(p,Vector2(135,105)),Color("d6b988"))
    draw_colored_polygon(PackedVector2Array([p+Vector2(-12,8),p+Vector2(67,-55),p+Vector2(148,8)]),Color("885947"))
    draw_rect(Rect2(p+Vector2(53,58),Vector2(30,47)),Color("624f3e"))

func _button(p:Vector2,s:String,c:Color) -> void:
    draw_circle(p,40,c)
    draw_arc(p,40,0,TAU,36,Color.WHITE,3)
    _label(s,p+Vector2(-10,9),29)

func _unhandled_input(event:InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < 210 and event.position.y > 290 and joystick_id == -1:
                joystick_id = event.index
                joystick_start = Vector2(95,426)
                _touch_joystick(event.position)
            elif event.position.distance_to(Vector2(851,374)) < 65:
                attack_requested = true
            elif event.position.distance_to(Vector2(763,438)) < 65:
                run_touch_id = event.index
                touch_run = true
        else:
            if event.index == joystick_id:
                joystick_id = -1
                touch_move = Vector2.ZERO
            if event.index == run_touch_id:
                run_touch_id = -1
                touch_run = false
    elif event is InputEventScreenDrag and event.index == joystick_id:
        _touch_joystick(event.position)

func _touch_joystick(pos:Vector2) -> void:
    touch_move = ((pos-joystick_start)/58.0).limit_length(1.0)
