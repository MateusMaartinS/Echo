extends Node2D

func _ready() -> void:
    queue_redraw()

func _draw() -> void:
    # Papel base
    draw_rect(Rect2(0, 0, 1280, 720), Color("#F4F1E8"))
    # Manchas suaves de papel amassado, desenhadas por primitivas para manter o protótipo sem assets externos.
    for i in 28:
        var x := float((i * 197) % 1280)
        var y := float((i * 113) % 720)
        var r := float(20 + (i % 5) * 12)
        draw_circle(Vector2(x, y), r, Color(1.0, 1.0, 1.0, 0.035))
    for i in 18:
        var x1 := float((i * 281) % 1280)
        var y1 := float((i * 149) % 720)
        var x2 := x1 + 80 + (i % 4) * 25
        var y2 := y1 + ((-1 if i % 2 == 0 else 1) * (20 + (i % 3) * 15))
        draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.4, 0.4, 0.4, 0.035), 2.0)
