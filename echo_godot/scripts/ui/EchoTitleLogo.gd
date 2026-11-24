extends Control
class_name EchoTitleLogo

# Original drawn pixel lettering. No system font, subtitle or raster resampling.
const CELL: float = 14.0
const LETTERS := [
    ["1111111","1111111","1100000","1100000","1111110","1111110","1100000","1100000","1111111","1111111"],
    ["0111110","1111111","1100011","1100000","1100000","1100000","1100000","1100011","1111111","0111110"],
    ["1100011","1100011","1100011","1100011","1111111","1111111","1100011","1100011","1100011","1100011"],
    ["0111110","1111111","1100011","1100011","1100011","1100011","1100011","1100011","1111111","0111110"]
]

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    for pass_index in range(3):
        for letter in range(LETTERS.size()):
            for row in range(10):
                for column in range(7):
                    if LETTERS[letter][row][column]!="1":
                        continue
                    var rect := Rect2((letter*9+column)*CELL,row*CELL,CELL,CELL)
                    if pass_index==0:
                        var shadow: Rect2 = rect.grow(5)
                        shadow.position+=Vector2(10,12)
                        draw_rect(shadow,Color("#090a15"))
                    elif pass_index==1:
                        draw_rect(rect.grow(4),BattleHudStyle.INK)
                    else:
                        draw_rect(rect,Color("#fff0d5") if row<4 else Color("#f7d691") if row<7 else Color("#dca868"))
