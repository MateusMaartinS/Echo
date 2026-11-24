extends Node2D
class_name RhythmNote

# Uma nota que viaja da direita pra esquerda até o receptor.
#
# note_type:
#   "normal" = nota comum (pode ser longa: duration > 0)
#   "fire"   = FOGO  (Verão)    -> NÃO apertar; apertar queima energia
#   "ice"    = GELO  (Inverno)  -> NÃO apertar; apertar congela teclas vizinhas
#   "leaf"   = FOLHA (Outono)   -> sai voando antes de chegar; não é erro

const NOTE_SIZE: float = 26.0
const INK: Color = Color("#174A9A")
const INK_DARK: Color = Color("#0D2F64")
const FIRE_COLOR: Color = Color(0.92, 0.30, 0.10, 1.0)
const FIRE_DARK: Color = Color(0.50, 0.10, 0.05, 1.0)
const ICE_COLOR: Color = Color(0.45, 0.80, 0.96, 1.0)
const ICE_DARK: Color = Color(0.10, 0.35, 0.58, 1.0)
const LEAF_COLOR: Color = Color(0.85, 0.48, 0.10, 1.0)
const LEAF_DARK: Color = Color(0.42, 0.20, 0.05, 1.0)
const BROKEN_COLOR: Color = Color(0.50, 0.50, 0.52, 1.0)
const LEAF_FLEE_LEAD: float = 0.45

var lane: int = 0
var hit_time: float = 0.0
var spawn_time: float = 0.0
var spawn_x: float = 1180.0
var target_x: float = 302.0
var judged: bool = false
var active: bool = false
var note_color: Color = Color("#174A9A")

var note_type: String = "normal"
var duration: float = 0.0     # segundos (0 = nota simples)
var end_time: float = 0.0     # hit_time + duration
var is_holding: bool = false
var hold_broken: bool = false
var fleeing: bool = false
var speed_px: float = 600.0   # pixels por segundo
var tail_len: float = 0.0
var pixel_style: bool = false

func setup(note_lane: int, target_time: float, travel_time: float, start_x: float, end_x: float, type_name: String = "normal", hold_seconds: float = 0.0) -> void:
    lane = note_lane
    hit_time = target_time
    spawn_time = target_time - maxf(travel_time, 0.001)
    spawn_x = start_x
    target_x = end_x
    note_type = type_name
    duration = maxf(hold_seconds, 0.0) if type_name == "normal" else 0.0
    end_time = hit_time + duration
    speed_px = (spawn_x - target_x) / maxf(travel_time, 0.001)
    position.x = spawn_x
    judged = false
    active = true
    queue_redraw()

func set_note_color(value: Color) -> void:
    note_color = value
    queue_redraw()

func is_hold() -> bool:
    return duration > 0.0

func _process(_delta: float) -> void:
    if not active or judged:
        return

    var now: float = Conductor.get_song_position()
    var travel_time: float = maxf(hit_time - spawn_time, 0.001)
    var progress: float = clampf((now - spawn_time) / travel_time, 0.0, 1.0)
    position.x = lerpf(spawn_x, target_x, progress)

    if note_type == "leaf" and not fleeing and now >= hit_time - LEAF_FLEE_LEAD:
        _start_flee()

    if duration > 0.0 and not hold_broken:
        _update_tail(now)

func _update_tail(now: float) -> void:
    # A cauda fica atrás da cabeça (à direita). Depois que a cabeça chega
    # no receptor ela encolhe conforme o tempo passa. O limite à direita
    # impede a cauda de aparecer fora do campo.
    var remaining: float = end_time - maxf(now, hit_time)
    var full_length: float = maxf(remaining, 0.0) * speed_px
    var cap: float = maxf(spawn_x - position.x, 0.0)
    var new_length: float = minf(full_length, cap)
    if absf(new_length - tail_len) > 0.5 or is_holding:
        tail_len = new_length
        queue_redraw()

func begin_hold() -> void:
    is_holding = true
    queue_redraw()

func finish_hold() -> void:
    is_holding = false
    mark_judged()

func break_hold() -> void:
    is_holding = false
    hold_broken = true
    tail_len = 0.0
    queue_redraw()
    mark_judged()

func _start_flee() -> void:
    # Folha: sobe e desaparece antes de chegar no receptor.
    fleeing = true
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y - 90.0, LEAF_FLEE_LEAD)
    tween.tween_property(self, "rotation", 0.9, LEAF_FLEE_LEAD)
    tween.tween_property(self, "modulate:a", 0.0, LEAF_FLEE_LEAD)

func mark_judged() -> void:
    if judged:
        return
    judged = true
    active = false
    queue_redraw()
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.14)
    tween.tween_property(self, "modulate:a", 0.0, 0.16)
    tween.set_parallel(false)
    tween.tween_callback(queue_free)

func _body_color() -> Color:
    if hold_broken:
        return BROKEN_COLOR
    match note_type:
        "fire":
            return FIRE_COLOR
        "ice":
            return ICE_COLOR
        "leaf":
            return LEAF_COLOR
    return note_color

func _dark_color() -> Color:
    if hold_broken:
        return BROKEN_COLOR.darkened(0.4)
    match note_type:
        "fire":
            return FIRE_DARK
        "ice":
            return ICE_DARK
        "leaf":
            return LEAF_DARK
    return INK_DARK

func _draw() -> void:
    if pixel_style:
        _draw_pixel()
        return
    var s: float = NOTE_SIZE
    var center: Vector2 = Vector2.ZERO
    var body: Color = _body_color()
    var dark: Color = _dark_color()

    if judged:
        # Anel que "estoura" junto com o tween de escala/fade em mark_judged().
        draw_arc(center, s * 1.1, 0, TAU, 28, Color(body.r, body.g, body.b, 0.6), 3.0, true)

    # Cauda da nota longa (atrás da cabeça).
    if duration > 0.0 and tail_len > 1.0:
        var tail_rect: Rect2 = Rect2(0.0, -7.0, tail_len, 14.0)
        draw_rect(tail_rect, Color(body.r, body.g, body.b, 0.80 if is_holding else 0.50), true)
        draw_rect(tail_rect, dark, false, 2.0)

    if is_holding:
        draw_circle(center, s * 1.45, Color(body.r, body.g, body.b, 0.28))

    # Enfeite por tipo, atrás da seta.
    match note_type:
        "fire":
            _draw_flame(s)
        "ice":
            _draw_snowflake(s)
        "leaf":
            _draw_leaf(s)

    # Brilho suave por trás da seta (GDD: "efeitos luminosos").
    draw_circle(center, s * 1.05, Color(body.r, body.g, body.b, 0.14))

    var pts: PackedVector2Array = Lanes.arrow_points(lane, center, s)
    draw_colored_polygon(pts, Color(body.r, body.g, body.b, 0.22))
    var outline: PackedVector2Array = Lanes.arrow_outline(lane, center, s)
    draw_polyline(outline, body, 5.0, true)
    draw_polyline(outline, dark, 2.0, true)

func _draw_flame(s: float) -> void:
    var unit: Array = [
        Vector2(0.0, -1.25), Vector2(0.35, -0.70), Vector2(0.75, -0.10),
        Vector2(0.70, 0.55), Vector2(0.30, 0.95), Vector2(-0.30, 0.95),
        Vector2(-0.70, 0.55), Vector2(-0.75, -0.10), Vector2(-0.30, -0.65)
    ]
    var outer: PackedVector2Array = PackedVector2Array()
    var inner: PackedVector2Array = PackedVector2Array()
    for u in unit:
        var uv: Vector2 = u
        outer.append(uv * s * 1.15)
        inner.append(uv * s * 0.60 + Vector2(0.0, s * 0.25))
    draw_colored_polygon(outer, Color(FIRE_COLOR.r, FIRE_COLOR.g, FIRE_COLOR.b, 0.55))
    draw_colored_polygon(inner, Color(1.0, 0.85, 0.25, 0.60))
    outer.append(outer[0])
    draw_polyline(outer, FIRE_DARK, 2.0, true)

func _draw_snowflake(s: float) -> void:
    var hex: PackedVector2Array = PackedVector2Array()
    for i in range(6):
        var a: float = (TAU / 6.0) * float(i)
        hex.append(Vector2(cos(a), sin(a)) * s * 1.15)
    draw_colored_polygon(hex, Color(ICE_COLOR.r, ICE_COLOR.g, ICE_COLOR.b, 0.38))
    for i in range(3):
        var a2: float = (PI / 3.0) * float(i)
        var dir: Vector2 = Vector2(cos(a2), sin(a2)) * s * 1.25
        draw_line(-dir, dir, ICE_DARK, 2.0, true)
    hex.append(hex[0])
    draw_polyline(hex, ICE_DARK, 2.0, true)

func _draw_leaf(s: float) -> void:
    draw_set_transform(Vector2.ZERO, -0.5, Vector2.ONE)
    var unit: Array = [
        Vector2(-1.30, 0.0), Vector2(-0.70, -0.65), Vector2(0.0, -0.88),
        Vector2(0.80, -0.60), Vector2(1.30, 0.0), Vector2(0.80, 0.60),
        Vector2(0.0, 0.88), Vector2(-0.70, 0.65)
    ]
    var leaf: PackedVector2Array = PackedVector2Array()
    for u in unit:
        var uv: Vector2 = u
        leaf.append(uv * s)
    draw_colored_polygon(leaf, Color(LEAF_COLOR.r, LEAF_COLOR.g, LEAF_COLOR.b, 0.60))
    draw_line(Vector2(-1.30, 0.0) * s, Vector2(1.30, 0.0) * s, LEAF_DARK, 2.0, true)
    leaf.append(leaf[0])
    draw_polyline(leaf, LEAF_DARK, 2.0, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pixel() -> void:
    if judged:
        return # Receptor feedback is rendered by the arena, outside incoming notes.
    var color: Color = BattleHudStyle.LANE_COLORS[lane]
    if hold_broken:
        color=BROKEN_COLOR
    if duration>0.0 and tail_len>1.0:
        draw_rect(Rect2(0,-7,tail_len,14),BattleHudStyle.INK)
        draw_rect(Rect2(0,-3,tail_len,6),color)
    match note_type:
        "fire":
            BattleHudStyle.draw_fire(self,Vector2.ZERO,lane)
        "normal":
            BattleHudStyle.draw_arrow(self,Vector2.ZERO,lane,20,color)
        _:
            # Custom charts can still contain the other seasons' hazards.
            if note_type=="ice":
                _draw_snowflake(20)
            elif note_type=="leaf":
                _draw_leaf(20)
            BattleHudStyle.draw_arrow(self,Vector2.ZERO,lane,14,Color.WHITE)
