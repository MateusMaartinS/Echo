extends Node2D

@export_enum("summer", "winter", "autumn", "spring") var season: String = "summer"
const SEASON_TITLES := {"summer":"DO VERÃO","winter":"DO INVERNO","autumn":"DO OUTONO","spring":"DA PRIMAVERA"}
const DETAILS := {"summer":"Cabelo solar • vestido com sóis • microfone e chama • arte original preservada", "winter":"Cabelo de gelo • capa azul • microfone e cristais • arte original preservada", "autumn":"Sobretudo com folhas • cachecol dourado • microfone e folhas ao vento • arte original preservada", "spring":"Vestido de pétalas • coroa de flores • cabelo rosa e flor flutuante • arte original preservada"}

const POSE_TITLES := ["REPOUSO","CIMA","DIREITA","ESQUERDA","BAIXO"]
const SEQUENCE := [-1,0,-1,1,-1,2,-1,3]
var singers: Array[PaperMusician] = []
var boss_id: String = ""
var exporting: bool = false
var automatic: bool = true
var time: float = 0.0
var last_step: int = -1

func _ready() -> void:
    boss_id = str(BossCatalog.SPRITE_BOSSES[season]["id"])
    exporting = ("--export-%s-preview" % boss_id) in OS.get_cmdline_user_args()
    if exporting:
        for column in range(5):
            var singer := BossCatalog.create_lord(season)
            singer.position = Vector2(140+column*250,380)
            singer.scale = Vector2(1.2,1.2)
            singer.preview_pose = column-1
            add_child(singer)
            singers.append(singer)
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://art_preview/%s_poses.png" % boss_id)
        get_tree().quit()
    else:
        for index in range(2):
            var singer := BossCatalog.create_lord(season)
            singer.position = Vector2(430,395) if index == 0 else Vector2(973,420)
            singer.scale = Vector2(1.75,1.75) if index == 0 else Vector2(.83,.83)
            add_child(singer)
            singers.append(singer)
    queue_redraw()

func _process(delta: float) -> void:
    if exporting:
        return
    time += delta
    for singer in singers:
        singer.rhythm_beat = time*1.6
    if automatic:
        var step: int = int(time/.7) % SEQUENCE.size()
        if step != last_step:
            last_step=step
            for singer in singers:
                if SEQUENCE[step]<0:
                    singer.pose_remaining=0.0
                else:
                    singer.play_pose(SEQUENCE[step],.44)

func _unhandled_input(event: InputEvent) -> void:
    if exporting or not event is InputEventKey or not event.pressed or event.echo:
        return
    var lane: int = Lanes.lane_for_key(event.physical_keycode)
    if lane>=0:
        automatic=false
        for singer in singers:
            singer.play_pose(lane,.5)
    elif event.physical_keycode == KEY_SPACE:
        automatic=not automatic
        last_step=-1

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#f7f3e9"))
    var ink: Color = SeasonMenuStyle.INK
    draw_string(ThemeDB.fallback_font,Vector2(42,73),"ECHO  /  %s — CHEFE %s" % [BossCatalog.display_name(season),SEASON_TITLES[season]],HORIZONTAL_ALIGNMENT_LEFT,-1,30,ink)
    draw_string(ThemeDB.fallback_font,Vector2(42,112),str(DETAILS[season]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,ink)
    if exporting:
        for column in range(5):
            var x: float = 140+column*250
            draw_line(Vector2(x-100,497),Vector2(x+100,497),Color(.23,.24,.21,.16),1.0)
            draw_string(ThemeDB.fallback_font,Vector2(x-110,552),POSE_TITLES[column],HORIZONTAL_ALIGNMENT_CENTER,220,20,ink)
        draw_string(ThemeDB.fallback_font,Vector2(42,663),"Cinco ações • três quadros por sequência • sustentação nas notas longas e pausa na contagem",HORIZONTAL_ALIGNMENT_LEFT,-1,17,ink)
    else:
        draw_line(Vector2(220,564),Vector2(650,564),Color(.23,.24,.21,.16),1.0)
        draw_line(Vector2(875,501),Vector2(1070,501),Color(.23,.24,.21,.16),1.0)
        draw_string(ThemeDB.fallback_font,Vector2(805,540),"TAMANHO NA PARTIDA",HORIZONTAL_ALIGNMENT_CENTER,330,18,ink)
        draw_string(ThemeDB.fallback_font,Vector2(42,663),"Setas / D F J K: testar poses   •   ESPAÇO: alternar sequência automática",HORIZONTAL_ALIGNMENT_LEFT,-1,18,ink)
