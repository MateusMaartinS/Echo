extends Control
class_name TitleControlsHint

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE

func _keycap(at: Vector2, width: float, caption: String) -> void:
    draw_rect(Rect2(at+Vector2(2,3),Vector2(width,26)),Color("#090a15"))
    draw_rect(Rect2(at,Vector2(width,26)),Color("#272437"))
    draw_rect(Rect2(at,Vector2(width,26)),BattleHudStyle.MUTED,false,2)
    draw_string(BattleHudStyle.FONT,at+Vector2(0,20),caption,HORIZONTAL_ALIGNMENT_CENTER,width,20,BattleHudStyle.CREAM)

func _draw() -> void:
    _keycap(Vector2.ZERO,26,"↑")
    _keycap(Vector2(32,0),26,"↓")
    _keycap(Vector2(228,0),74,"ENTER")
    _keycap(Vector2(460,0),50,"ESC")
    for entry in [[Vector2(70,20),"SELECIONAR"],[Vector2(314,20),"CONFIRMAR"],[Vector2(522,20),"VOLTAR"]]:
        draw_string(BattleHudStyle.FONT,entry[0]+Vector2(1,2),entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,20,BattleHudStyle.INK)
        draw_string(BattleHudStyle.FONT,entry[0],entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,20,BattleHudStyle.CREAM)
