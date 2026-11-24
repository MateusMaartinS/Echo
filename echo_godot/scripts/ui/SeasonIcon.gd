extends Control
class_name SeasonIcon

# Ícone simples de cada estação, desenhado por código no estilo tinta/papel.
# spring = flor | summer = sol | autumn = folha | winter = floco de neve

const INK: Color = Color("#174A9A")

var outline_color: Color = INK

var season: String = "spring"
var accent: Color = Color("#174A9A")

func setup(season_name: String, accent_color: Color) -> void:
    season = season_name
    accent = accent_color
    queue_redraw()

func _draw() -> void:
    var c: Vector2 = size * 0.5
    var r: float = minf(size.x, size.y) * 0.42
    match season:
        "spring":
            _flower(c, r)
        "summer":
            _sun(c, r)
        "autumn":
            _leaf(c, r)
        "winter":
            _snowflake(c, r)
        "tutorial":
            _music_note(c, r)

func _flower(c: Vector2, r: float) -> void:
    for i in range(6):
        var a: float = (TAU / 6.0) * float(i)
        var p: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.58
        draw_circle(p, r * 0.36, Color(accent.r, accent.g, accent.b, 0.85))
        draw_arc(p, r * 0.36, 0.0, TAU, 20, outline_color, 2.0, true)
    draw_circle(c, r * 0.28, Color(0.98, 0.82, 0.25, 1.0))
    draw_arc(c, r * 0.28, 0.0, TAU, 20, outline_color, 2.0, true)

func _sun(c: Vector2, r: float) -> void:
    for i in range(12):
        var a: float = (TAU / 12.0) * float(i)
        var d: Vector2 = Vector2(cos(a), sin(a))
        draw_line(c + d * r * 0.62, c + d * r * 1.0, accent, 4.0, true)
    draw_circle(c, r * 0.46, Color(accent.r, accent.g, accent.b, 0.9))
    draw_arc(c, r * 0.46, 0.0, TAU, 28, outline_color, 2.5, true)

func _leaf(c: Vector2, r: float) -> void:
    draw_set_transform(c, -0.6, Vector2.ONE)
    var unit: Array = [
        Vector2(-1.0, 0.0), Vector2(-0.55, -0.55), Vector2(0.0, -0.72),
        Vector2(0.65, -0.5), Vector2(1.0, 0.0), Vector2(0.65, 0.5),
        Vector2(0.0, 0.72), Vector2(-0.55, 0.55)
    ]
    var pts: PackedVector2Array = PackedVector2Array()
    for u in unit:
        var uv: Vector2 = u
        pts.append(uv * r)
    draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.85))
    draw_line(Vector2(-1.15, 0.0) * r, Vector2(1.0, 0.0) * r, outline_color, 3.0, true)
    pts.append(pts[0])
    draw_polyline(pts, outline_color, 2.5, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _snowflake(c: Vector2, r: float) -> void:
    for i in range(3):
        var a: float = (PI / 3.0) * float(i)
        var d: Vector2 = Vector2(cos(a), sin(a)) * r
        draw_line(c - d, c + d, accent, 4.0, true)
        # pontas em "V"
        for sign_value in [-1.0, 1.0]:
            var tip: Vector2 = c + d * float(sign_value)
            var back: Vector2 = -d.normalized() * float(sign_value) * r * 0.22
            var side: Vector2 = Vector2(-d.y, d.x).normalized() * r * 0.16
            draw_line(tip, tip + back + side, accent, 3.0, true)
            draw_line(tip, tip + back - side, accent, 3.0, true)
    draw_arc(c, r * 0.18, 0.0, TAU, 16, outline_color, 2.0, true)

func _music_note(c: Vector2, r: float) -> void:
    var head: Vector2 = c + Vector2(-r * 0.28, r * 0.55)
    draw_circle(head, r * 0.34, Color(accent.r, accent.g, accent.b, 0.9))
    draw_arc(head, r * 0.34, 0.0, TAU, 20, outline_color, 2.5, true)
    var stem_bottom: Vector2 = head + Vector2(r * 0.32, -r * 0.05)
    var stem_top: Vector2 = stem_bottom + Vector2(0.0, -r * 1.15)
    draw_line(stem_bottom, stem_top, outline_color, 4.0, true)
    var flag: PackedVector2Array = PackedVector2Array([
        stem_top,
        stem_top + Vector2(r * 0.55, r * 0.20),
        stem_top + Vector2(r * 0.50, r * 0.55),
        stem_top + Vector2(r * 0.05, r * 0.38)
    ])
    draw_colored_polygon(flag, Color(accent.r, accent.g, accent.b, 0.9))
    flag.append(flag[0])
    draw_polyline(flag, outline_color, 2.0, true)
