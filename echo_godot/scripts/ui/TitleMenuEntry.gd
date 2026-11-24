extends Button
class_name TitleMenuEntry

var active: bool = false:
    set(value):
        active=value
        queue_redraw()

func _ready() -> void:
    mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    for state in ["normal","hover","pressed","focus","disabled"]:
        add_theme_stylebox_override(state,StyleBoxEmpty.new())
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        add_theme_color_override(state,Color(0,0,0,0))
    add_theme_font_override("font",BattleHudStyle.FONT)
    add_theme_font_size_override("font_size",30)

func _draw() -> void:
    var at := Vector2(40 if active else 34,33)
    var color: Color = BattleHudStyle.GOLD if active else BattleHudStyle.CREAM
    draw_string(BattleHudStyle.FONT,at+Vector2(2,3),text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,BattleHudStyle.INK)
    draw_string(BattleHudStyle.FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,color)
    if active:
        BattleHudStyle.draw_arrow(self,Vector2(14,24),1,12,BattleHudStyle.GOLD)
