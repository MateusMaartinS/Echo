extends Control

const PAPER := Color("#F6F2E8")
const INK := Color("#174A9A")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1209
	for i in range(70):
		var p := Vector2(rng.randf_range(0.0, size.x), rng.randf_range(0.0, size.y))
		var alpha: float = rng.randf_range(0.012, 0.035)
		draw_circle(p, rng.randf_range(8.0, 35.0), Color(0.3, 0.28, 0.25, alpha))
