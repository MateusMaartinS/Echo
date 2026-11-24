extends Control
class_name SeasonVista

# Small paper landscapes, shared by the title screen and stage postcards.
@export_enum("spring", "summer", "autumn", "winter", "tutorial") var season: String = "tutorial"
var clock: float = 0.0
var animated: bool = true
const SKIES := {"spring": "#eddcdb", "summer": "#f4db9e", "autumn": "#e6cbb0", "winter": "#d4e3e8", "tutorial": "#e3e7d5"}
const HILLS := {"spring": "#a8ba88", "summer": "#72aeb0", "autumn": "#b68a62", "winter": "#a3bdc8", "tutorial": "#aebc92"}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true

func _process(delta: float) -> void:
    if animated and is_visible_in_tree():
        clock += delta
        queue_redraw()

func _polygon(points: Array, color: Color) -> void:
    var scaled := PackedVector2Array()
    for point in points:
        scaled.append((point as Vector2) * size)
    draw_colored_polygon(scaled, color)

func _draw() -> void:
    var sky := Color(SKIES.get(season, SKIES["tutorial"]))
    var hill := Color(HILLS.get(season, HILLS["tutorial"]))
    draw_rect(Rect2(Vector2.ZERO, size), sky)
    var sun: Vector2 = size * Vector2(0.76, 0.22)
    draw_circle(sun, size.y * 0.15, Color(1.0, 0.98, 0.86, 0.32), true, -1, true)
    draw_circle(sun, size.y * 0.105, Color("#f8ecc6"), true, -1, true)
    _polygon([Vector2(0,.62), Vector2(.18,.49), Vector2(.43,.58), Vector2(.69,.42), Vector2(1,.53), Vector2(1,1), Vector2(0,1)], hill.lightened(0.23))
    if season == "winter":
        _polygon([Vector2(.38,.58), Vector2(.69,.18), Vector2(.96,.59)], Color("#9fb8c6"))
        _polygon([Vector2(.56,.36), Vector2(.69,.18), Vector2(.81,.36), Vector2(.72,.32), Vector2(.66,.37), Vector2(.62,.32)], Color("#f4f5ed"))
    _polygon([Vector2(0,.80), Vector2(.25,.65), Vector2(.54,.79), Vector2(.82,.68), Vector2(1,.74), Vector2(1,1), Vector2(0,1)], hill)
    if season == "summer":
        _polygon([Vector2(0,.9), Vector2(.23,.83), Vector2(.55,.9), Vector2(1,.81), Vector2(1,1), Vector2(0,1)], Color("#e6cc91"))
        for row in range(3):
            var points := PackedVector2Array()
            for i in range(30):
                var x: float = float(i) / 29.0 * size.x
                points.append(Vector2(x, size.y * (0.69 + float(row) * 0.05) + sin(x * .035 + clock * .55 + row) * 2.0))
            draw_polyline(points, Color(0.97, .98, .89, .45), 1.2, true)
        _palm(size * Vector2(.13,.84))
    elif season == "winter":
        _polygon([Vector2(0,.92), Vector2(.26,.79), Vector2(.58,.89), Vector2(1,.8), Vector2(1,1), Vector2(0,1)], Color("#edf1e9"))
        _pine(size * Vector2(.12,.87), size.y * .32)
        _pine(size * Vector2(.88,.81), size.y * .25)
    elif season in ["spring", "autumn"]:
        _tree(size * Vector2(.15,.86), season == "spring")
        for i in range(8):
            var p := Vector2(size.x * (float(i) + .5) / 8.0, size.y * (.86 + sin(float(i) * 2.4) * .07))
            if season == "spring":
                for petal in range(5):
                    draw_circle(p + Vector2.from_angle(float(petal) * TAU / 5.0) * 3.0, 2.7, Color("#e8b4c4"), true, -1, true)
                draw_circle(p, 1.8, Color("#f5dda0"), true, -1, true)
            else:
                _leaf(p, float(i), 5.0)
    else:
        # Winding path for the first steps of the tutorial.
        _polygon([Vector2(.42,1), Vector2(.49,.78), Vector2(.58,.68), Vector2(.59,.67), Vector2(.52,.8), Vector2(.64,1)], Color("#e5d7b5"))
    # Sparse drifting petals, leaves, or snow. Fixed seeds keep the paper steady.
    for i in range(9):
        var t: float = float(i)
        var x: float = fposmod(t * .137 + sin(clock * .25 + t) * .02, 1.0) * size.x
        var y: float = fposmod(t * .213 + clock * (.016 if season == "winter" else .01), .88) * size.y
        if season == "autumn":
            _leaf(Vector2(x,y), t + clock * .3, 3.0)
        elif season == "winter":
            draw_circle(Vector2(x,y), 1.6, Color(1,1,.96,.75), true, -1, true)
        elif season == "spring":
            draw_circle(Vector2(x,y), 2.0, Color(.95,.75,.79,.75), true, -1, true)
    # Fine pencil hatching, static rather than animated noise.
    for i in range(32):
        var p := Vector2(fposmod(float(i) * .618, 1.0) * size.x, fposmod(float(i) * .347, 1.0) * size.y)
        draw_line(p, p + Vector2(8,-2), Color(.3,.29,.23,.045), 1.0, true)

func _tree(base: Vector2, flowering: bool) -> void:
    var h: float = size.y * .40
    var trunk := Color("#806c53")
    draw_line(base, base - Vector2(0,h), trunk, 4.0, true)
    for i in range(5):
        var angle: float = -2.9 + float(i) * .64
        var tip: Vector2 = base - Vector2(0,h * .5) + Vector2.from_angle(angle) * h * .7
        draw_line(base - Vector2(0,h * .3), tip, trunk, 2.0, true)
        draw_circle(tip, h * .33, Color("#dbaab5") if flowering else Color("#c78750"), true, -1, true)
        draw_arc(tip, h * .33, .3, 2.7, 16, Color(.35,.3,.25,.14), 1.0, true)

func _palm(base: Vector2) -> void:
    var top: Vector2 = base + Vector2(size.y * .07,-size.y * .44)
    draw_polyline(PackedVector2Array([base, base.lerp(top,.5) + Vector2(-3,0), top]), Color("#94774e"), 4.0, true)
    for i in range(5):
        var angle: float = -PI + float(i) * PI / 4.0
        var tip: Vector2 = top + Vector2.from_angle(angle) * size.y * .19 + Vector2(0,8)
        draw_polyline(PackedVector2Array([top, top.lerp(tip,.5) - Vector2(0,6), tip]), Color("#698b6b"), 5.0, true)

func _pine(base: Vector2, height: float) -> void:
    draw_line(base, base - Vector2(0,height), Color("#667e80"), 3.0, true)
    for i in range(3):
        var y: float = -height + float(i) * height * .22
        var w: float = height * (.22 + float(i) * .1)
        draw_colored_polygon(PackedVector2Array([base + Vector2(0,y), base + Vector2(w,y+height*.45), base + Vector2(-w,y+height*.45)]), Color("#829c99"))

func _leaf(p: Vector2, angle: float, radius: float) -> void:
    var a: Vector2 = Vector2.from_angle(angle) * radius
    var b := Vector2(-a.y,a.x) * .45
    draw_colored_polygon(PackedVector2Array([p-a, p+b, p+a, p-b]), Color("#b66e46"))
    draw_line(p-a, p+a, Color("#8f674a"), .7, true)
