extends Node2D

# Run this scene to audition the winter choreography without a chart.
var singer: PaperLord
var small_singer: PaperLord
var time: float = 0.0
var last_step: int = -1
var automatic: bool = true
const SEQUENCE := [-1,2,-1,3,-1,0,-1,1]

func _ready() -> void:
    singer = PaperLord.new()
    singer.season = "winter"
    singer.position = Vector2(445,405)
    singer.scale = Vector2(1.65,1.65)
    add_child(singer)
    small_singer = PaperLord.new()
    small_singer.season = "winter"
    small_singer.position = Vector2(973,406)
    small_singer.scale = Vector2(.83,.83)
    add_child(small_singer)

func _process(delta: float) -> void:
    time += delta
    singer.rhythm_beat = time * 1.5
    small_singer.rhythm_beat = singer.rhythm_beat
    if automatic:
        var step: int = int(time / .65) % SEQUENCE.size()
        if step != last_step:
            last_step = step
            var lane: int = SEQUENCE[step]
            if lane >= 0:
                _pose(lane)

func _pose(lane: int) -> void:
    singer.play_pose(lane,.42)
    small_singer.play_pose(lane,.42)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var lane: int = Lanes.lane_for_key(event.physical_keycode)
        if lane >= 0:
            automatic = false
            _pose(lane)
        elif event.physical_keycode == KEY_SPACE:
            automatic = not automatic
            last_step = -1

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#f7f3e9"))
    var ink := SeasonMenuStyle.INK
    draw_string(ThemeDB.fallback_font,Vector2(62,80),"ECHO  /  CANTORA DO INVERNO",HORIZONTAL_ALIGNMENT_LEFT,-1,30,ink)
    draw_string(ThemeDB.fallback_font,Vector2(62,119),"Estudo de animação • casaco azul, gorro colorido, luvas e microfone",HORIZONTAL_ALIGNMENT_LEFT,-1,19,ink)
    draw_line(Vector2(220,566),Vector2(670,566),Color(.23,.24,.21,.18),1.0)
    draw_line(Vector2(879,489),Vector2(1064,489),Color(.23,.24,.21,.18),1.0)
    draw_string(ThemeDB.fallback_font,Vector2(806,531),"TAMANHO NA PARTIDA",HORIZONTAL_ALIGNMENT_CENTER,330,18,ink)
    draw_string(ThemeDB.fallback_font,Vector2(62,660),"Setas / D F J K: testar poses   •   ESPAÇO: alternar sequência automática",HORIZONTAL_ALIGNMENT_LEFT,-1,18,ink)
