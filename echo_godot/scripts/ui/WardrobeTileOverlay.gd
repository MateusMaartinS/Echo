extends Control
class_name WardrobeTileOverlay

var tile: WardrobeSkinTile

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    if tile == null:
        return
    if not tile.unlocked:
        draw_rect(Rect2(6,6,size.x-16,145),Color(.06,.04,.10,.46))
        draw_arc(Vector2(29,21),8,PI,TAU,6,BattleHudStyle.CREAM,3,false)
        draw_rect(Rect2(17,19,24,21),BattleHudStyle.INK)
        draw_rect(Rect2(17,19,24,21),BattleHudStyle.CREAM,false,2)
        draw_rect(Rect2(27,27,4,7),BattleHudStyle.GOLD)
    if tile.equipped:
        draw_rect(Rect2(size.x-105,12,91,26),BattleHudStyle.INK)
        draw_rect(Rect2(size.x-105,12,91,26),BattleHudStyle.GOLD,false,2)
        draw_string(BattleHudStyle.FONT,Vector2(size.x-100,31),"EM USO",HORIZONTAL_ALIGNMENT_LEFT,82,20,BattleHudStyle.GOLD)
