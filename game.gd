extends Node2D

const PATH = [Vector2(-40,340),Vector2(175,340),Vector2(175,520),Vector2(540,520),Vector2(540,750),Vector2(180,750),Vector2(180,970),Vector2(760,970)]
const PADS = [Vector2(80,455),Vector2(300,335),Vector2(410,415),Vector2(638,430),Vector2(425,645),Vector2(75,665),Vector2(320,860),Vector2(610,850)]
const COSTS = [70,110,95]
const COLORS = [Color("ff85bd"),Color("ffe07c"),Color("7ee7cc")]
const DAMAGE = [18.0,38.0,11.0]
const RATE = [0.72,1.3,0.38]
const RANGE = [180.0,210.0,165.0]
var gold = 210
var lives = 12
var wave = 0
var selected = 0
var enemies = []
var towers = []
var shots = []
var spawning = 0
var spawn_timer = 0.0
var playing = false
var ended = ""
var font: Font

func _ready() -> void:
    font = ThemeDB.fallback_font
    queue_redraw()

func _process(delta: float) -> void:
    if ended != "":
        queue_redraw()
        return
    if spawning > 0:
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            var boss = wave % 4 == 0 and spawning == 1
            var hp = (190.0 if boss else 48.0) * (1.0 + wave * 0.26)
            enemies.append({"dist":0.0,"pos":PATH[0],"hp":hp,"max":hp,"speed":65.0 if boss else 88.0 + wave * 4.0,"boss":boss,"reward":55 if boss else 17,"color":Color("bf91ec") if boss else Color("ff9b88")})
            spawning -= 1
            spawn_timer = 0.72
    for e in enemies.duplicate():
        e["dist"] += e["speed"] * delta
        e["pos"] = point_at(e["dist"])
        if e["dist"] >= path_length():
            enemies.erase(e)
            lives -= 1
            if lives <= 0:
                ended = "GAME OVER"
    for t in towers:
        t["cd"] -= delta
        if t["cd"] > 0:
            continue
        var k: int = t["kind"]
        var target = null
        for e in enemies:
            if t["pos"].distance_to(e["pos"]) < RANGE[k]:
                if target == null or e["dist"] > target["dist"]:
                    target = e
        if target != null:
            t["cd"] = RATE[k]
            shots.append({"a":t["pos"],"b":target["pos"],"ttl":0.2,"color":COLORS[k]})
            target["hp"] -= DAMAGE[k]
            if target["hp"] <= 0:
                gold += target["reward"]
                enemies.erase(target)
    for s in shots.duplicate():
        s["ttl"] -= delta
        if s["ttl"] <= 0:
            shots.erase(s)
    if playing and spawning == 0 and enemies.is_empty():
        playing = false
        if wave >= 8:
            ended = "YOU WIN!"
        else:
            gold += 40 + wave * 8
    queue_redraw()

func path_length() -> float:
    var length = 0.0
    for i in range(PATH.size() - 1):
        length += PATH[i].distance_to(PATH[i + 1])
    return length

func point_at(dist: float) -> Vector2:
    for i in range(PATH.size() - 1):
        var seg: float = PATH[i].distance_to(PATH[i + 1])
        if dist <= seg:
            return PATH[i].lerp(PATH[i + 1],dist / seg)
        dist -= seg
    return PATH[PATH.size() - 1]

func _input(event: InputEvent) -> void:
    var pos = Vector2(-100,-100)
    if event is InputEventScreenTouch and event.pressed:
        pos = event.position
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
    if pos.x < 0:
        return
    if ended != "":
        get_tree().reload_current_scene()
        return
    if pos.y >= 1105:
        selected = clampi(int((pos.x-20.0)/235.0),0,2)
        return
    if pos.y < 270 and pos.x > 430 and not playing and wave < 8:
        wave += 1
        playing = true
        spawning = 5 + wave * 2
        spawn_timer = 0.1
        return
    for pad in PADS:
        if pad.distance_to(pos) < 49:
            var occupied = false
            for t in towers:
                if t["pos"] == pad:
                    occupied = true
            if not occupied and gold >= COSTS[selected]:
                gold -= COSTS[selected]
                towers.append({"pos":pad,"kind":selected,"cd":0.1})
            return

func label(s: String, p: Vector2, size: int = 24, color: Color = Color("594a72")) -> void:
    draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func panel(rect: Rect2, color: Color) -> void:
    draw_rect(rect,color)

func _draw() -> void:
    panel(Rect2(0,0,720,1280),Color("eaf8ee"))
    for x in range(0,720,80):
        for y in range(0,1280,80):
            draw_circle(Vector2(x+28,y+31),4,Color("d0e9d8"))
    panel(Rect2(15,20,690,135),Color.WHITE)
    label("CANDY GUARD",Vector2(36,78),42,Color("a969ba"))
    label("GOLD: %d" % gold,Vector2(38,124),27,Color("bc913b"))
    label("HEART: %d" % lives,Vector2(378,124),27,Color("ee7597"))
    panel(Rect2(16,170,396,93),Color.WHITE)
    label("WAVE %d / 8" % wave,Vector2(38,226),36)
    panel(Rect2(433,170,269,93),Color("8cdcc1"))
    label("IN PROGRESS" if playing else "START WAVE",Vector2(448,226),27,Color("365d59"))
    draw_polyline(PackedVector2Array(PATH),Color("c9aa8d"),112,true)
    draw_polyline(PackedVector2Array(PATH),Color("ffe7b8"),96,true)
    for i in range(1,75):
        var dist = path_length() * float(i)/75.0
        draw_line(point_at(dist),point_at(dist+10),Color.WHITE,4)
    for pad in PADS:
        var tower = null
        for t in towers:
            if t["pos"] == pad:
                tower = t
        draw_circle(pad,45,Color.WHITE)
        if tower == null:
            draw_arc(pad,39,0,TAU,40,Color("92d9bd"),5)
            label("+",pad+Vector2(-15,18),53,Color("8ac9af"))
        else:
            var kind: int = tower["kind"]
            draw_circle(pad,35,COLORS[kind])
            draw_circle(pad+Vector2(-12,-8),6,Color.WHITE)
            draw_circle(pad+Vector2(12,-8),6,Color.WHITE)
            draw_circle(pad+Vector2(-12,-8),2,Color("5a4261"))
            draw_circle(pad+Vector2(12,-8),2,Color("5a4261"))
            draw_arc(pad,14,0.3,2.8,18,Color("6e526e"),3)
    for e in enemies:
        var p: Vector2 = e["pos"]
        var r = 32.0 if e["boss"] else 24.0
        draw_circle(p,r,e["color"])
        draw_circle(p+Vector2(-8,-4),4,Color("483a55"))
        draw_circle(p+Vector2(8,-4),4,Color("483a55"))
        draw_arc(p,9,0.2,2.9,16,Color("483a55"),2.5)
        draw_rect(Rect2(p.x-26,p.y-r-15,52,6),Color("745f70"))
        draw_rect(Rect2(p.x-26,p.y-r-15,52*maxf(0,e["hp"]/e["max"]),6),Color("66d697"))
    for s in shots:
        draw_line(s["a"],s["b"],s["color"],6,true)
    panel(Rect2(0,1105,720,175),Color.WHITE)
    for i in range(3):
        var p = Vector2(22+i*235,1128)
        panel(Rect2(p,Vector2(215,120)),Color("fcefdc") if selected == i else Color("eaf2f0"))
        draw_circle(p+Vector2(33,35),20,COLORS[i])
        label(["COTTON","LEMON","MINT"][i],p+Vector2(64,45),23)
        label("%d GOLD" % COSTS[i],p+Vector2(60,86),21,Color("b28647"))
    if ended != "":
        panel(Rect2(55,475,610,290),Color("f8edff"))
        label(ended,Vector2(180,575),62,Color("aa73b8"))
        label("TAP TO RESTART",Vector2(205,676),27)
