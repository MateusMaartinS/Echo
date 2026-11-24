extends Control
class_name WardrobeControlsHint

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _keycap(at: Vector2, width: float, caption: String) -> void:
    draw_rect(Rect2(at+Vector2(2,3),Vector2(width,26)),BattleHudStyle.INK)
    draw_rect(Rect2(at,Vector2(width,26)),Color("#272437"))
    draw_rect(Rect2(at,Vector2(width,26)),BattleHudStyle.MUTED,false,2)
    draw_string(BattleHudStyle.FONT,at+Vector2(0,20),caption,HORIZONTAL_ALIGNMENT_CENTER,width,20,BattleHudStyle.CREAM)

func _draw() -> void:
    for i in range(4):
        _keycap(Vector2(i*33,0),27,["←","→","↑","↓"][i])
    _keycap(Vector2(302,0),74,"ENTER")
    _keycap(Vector2(577,0),50,"ESC")
    for entry in [[Vector2(147,20),"SELECIONAR"],[Vector2(390,20),"EQUIPAR"],[Vector2(640,20),"VOLTAR"]]:
        draw_string(BattleHudStyle.FONT,entry[0],entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,20,BattleHudStyle.CREAM)
