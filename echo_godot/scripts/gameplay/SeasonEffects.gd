extends Node2D
class_name SeasonEffects

# Efeitos visuais das mecânicas de estação, desenhados POR CIMA das notas:
#   - PRIMAVERA: flores que desabrocham sobre metade das lanes (eventos
#     "flower" do chart, programados no editor).
#   - INVERNO: camada de gelo sobre as teclas congeladas por uma nota de gelo.
# (Fogo e folha são desenhados pela própria nota.)

const INK: Color = Color("#174A9A")
const BLOOM_BEATS: float = 0.5   # tempo pra flor abrir/fechar, em beats

const PETAL_COLORS: Array = [
    Color(0.93, 0.45, 0.62, 1.0),
    Color(0.96, 0.62, 0.30, 1.0),
    Color(0.80, 0.50, 0.85, 1.0)
]

var events: Array = []
var opponent_spawner: NoteSpawner
var player_spawner: NoteSpawner
var judge: Judge

func setup(chart_events: Array, opponent: NoteSpawner, player: NoteSpawner, judge_ref: Judge) -> void:
    events = chart_events
    opponent_spawner = opponent
    player_spawner = player
    judge = judge_ref
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    _draw_flowers()
    _draw_ice()

# --- Primavera --------------------------------------------------------------

func _draw_flowers() -> void:
    if events.is_empty():
        return
    var beat: float = Conductor.get_current_beat()
    for raw in events:
        if not (raw is Dictionary):
            continue
        var ev: Dictionary = raw as Dictionary
        if str(ev.get("type", "")) != "flower":
            continue
        var start_beat: float = float(ev.get("start_beat", 0.0))
        var end_beat: float = float(ev.get("end_beat", start_beat))
        var grow: float = clampf((beat - start_beat) / BLOOM_BEATS, 0.0, 1.0)
        var shrink: float = clampf((end_beat + BLOOM_BEATS - beat) / BLOOM_BEATS, 0.0, 1.0)
        var amount: float = minf(grow, shrink)
        if amount <= 0.0:
            continue

        var top_half: bool = str(ev.get("half", "top")) == "top"
        var field: String = str(ev.get("field", "both"))
        if field == "both" or field == "player":
            _draw_flower_cluster(player_spawner, top_half, amount)
        if field == "both" or field == "lorde":
            _draw_flower_cluster(opponent_spawner, top_half, amount)

func _draw_flower_cluster(spawner: NoteSpawner, top_half: bool, amount: float) -> void:
    if spawner == null or spawner.lane_y.size() < 4:
        return
    var first: int = 0 if top_half else 2
    var center_y: float = (spawner.lane_y[first] + spawner.lane_y[first + 1]) * 0.5
    var field_center_x: float = (spawner.target_x + spawner.spawn_x) * 0.5
    var offsets: Array = [-150.0, 0.0, 150.0]
    for i in range(offsets.size()):
        var jitter_y: float = -8.0 if i == 1 else 6.0
        var radius: float = 60.0 * amount * (1.0 if i == 1 else 0.88)
        var petal_color: Color = PETAL_COLORS[i % PETAL_COLORS.size()]
        _draw_flower(Vector2(field_center_x + float(offsets[i]), center_y + jitter_y), radius, petal_color)

func _draw_flower(center: Vector2, radius: float, petal_color: Color) -> void:
    if radius < 2.0:
        return
    var petals: int = 8
    var petal_radius: float = radius * 0.42
    var ring: float = radius * 0.62
    for i in range(petals):
        var a: float = (TAU / float(petals)) * float(i)
        var p: Vector2 = center + Vector2(cos(a), sin(a)) * ring
        draw_circle(p, petal_radius, Color(petal_color.r, petal_color.g, petal_color.b, 0.97))
        draw_arc(p, petal_radius, 0.0, TAU, 20, INK, 2.0, true)
    draw_circle(center, radius * 0.40, Color(0.98, 0.82, 0.25, 1.0))
    draw_arc(center, radius * 0.40, 0.0, TAU, 24, INK, 2.5, true)

# --- Inverno ------------------------------------------------------------------

func _draw_ice() -> void:
    if judge == null or player_spawner == null or player_spawner.lane_y.size() < 4:
        return
    var now: float = Conductor.get_song_position()
    for lane in range(4):
        var remaining: float = judge.frozen_until[lane] - now
        if remaining <= 0.0:
            continue
        var fade: float = clampf(remaining / 0.4, 0.0, 1.0)
        var y: float = player_spawner.lane_y[lane]
        var x0: float = player_spawner.target_x - 46.0
        var width: float = 190.0
        var rect: Rect2 = Rect2(x0, y - 19.0, width, 38.0)
        draw_rect(rect, Color(0.72, 0.90, 1.0, 0.62 * fade), true)
        draw_rect(rect, Color(0.10, 0.35, 0.58, 0.9 * fade), false, 3.0)
        # Rachaduras do gelo.
        var crack: Color = Color(1.0, 1.0, 1.0, 0.9 * fade)
        draw_line(Vector2(x0 + 18.0, y - 16.0), Vector2(x0 + 52.0, y + 4.0), crack, 2.0, true)
        draw_line(Vector2(x0 + 52.0, y + 4.0), Vector2(x0 + 44.0, y + 16.0), crack, 2.0, true)
        draw_line(Vector2(x0 + 96.0, y - 17.0), Vector2(x0 + 120.0, y - 2.0), crack, 2.0, true)
        draw_line(Vector2(x0 + 120.0, y - 2.0), Vector2(x0 + 150.0, y + 14.0), crack, 2.0, true)
        draw_string(ThemeDB.fallback_font, Vector2(x0 + 66.0, y + 6.0), "CONGELADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.10, 0.35, 0.58, fade))
