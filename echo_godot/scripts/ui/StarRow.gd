extends Control
class_name StarRow

# Fileira de estrelas desenhada por código (sem depender de fonte/imagem).
# `filled` pode ser animado (tween) de 0 até N: cada estrela "estoura" ao encher.

const INK: Color = Color("#174A9A")
const GOLD: Color = Color(0.96, 0.74, 0.12, 1.0)

var outline_color: Color = INK
var pixel_art: bool = false

var total: int = 4:
    set(value):
        total = value
        queue_redraw()

var filled: float = 0.0:
    set(value):
        filled = value
        queue_redraw()

func _draw() -> void:
    if total <= 0:
        return
    var cell: float = minf(size.y, size.x / float(total))
    var start_x: float = (size.x - cell * float(total)) * 0.5
    for i in range(total):
        var center: Vector2 = Vector2(start_x + cell * (float(i) + 0.5), size.y * 0.5)
        var amount: float = clampf(filled - float(i), 0.0, 1.0)
        var radius: float = cell * 0.44
        if amount > 0.0:
            radius *= 1.0 + 0.35 * sin(PI * amount)   # "pop" enquanto enche
        _star(center, radius, amount)

func _star(center: Vector2, radius: float, amount: float) -> void:
    var pts: PackedVector2Array = PackedVector2Array()
    for k in range(10):
        var a: float = -PI * 0.5 + (TAU / 10.0) * float(k)
        var r: float = radius if k % 2 == 0 else radius * 0.45
        var point: Vector2 = center + Vector2(cos(a), sin(a)) * r
        pts.append((point/2.0).round()*2.0 if pixel_art else point)
    if amount > 0.0:
        draw_colored_polygon(pts, Color(GOLD.r, GOLD.g, GOLD.b, 0.35 + 0.65 * amount))
    else:
        draw_colored_polygon(pts, Color(0.90, 0.89, 0.86, 0.9))
    pts.append(pts[0])
    draw_polyline(pts, outline_color if amount > 0.0 else Color(outline_color.r, outline_color.g, outline_color.b, 0.45), 2.0, not pixel_art)
