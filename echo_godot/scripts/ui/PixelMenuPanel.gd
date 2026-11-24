extends Panel
class_name PixelMenuPanel

var fill: Color = Color("#211a31")
var edge: Color = Color("#776279")
var highlighted: bool = false:
    set(value):
        highlighted=value
        queue_redraw()

func _init() -> void:
    add_theme_stylebox_override("panel",StyleBoxEmpty.new())

func _draw() -> void:
    BattleHudStyle.draw_panel(self,Rect2(Vector2.ZERO,size),fill,edge if highlighted else edge.darkened(.42),3 if highlighted else 2)
