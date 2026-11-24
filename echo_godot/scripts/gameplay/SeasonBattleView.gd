extends Node2D
class_name SeasonBattleView

# Live presentation only: timing, input and scoring remain with Battle/Judge.
const INK := BattleHudStyle.INK
const CREAM := BattleHudStyle.CREAM
const MUTED := BattleHudStyle.MUTED
const GOLD := BattleHudStyle.GOLD
const CORAL := BattleHudStyle.CORAL
const LANE_COLORS := BattleHudStyle.LANE_COLORS
const TOPS := BattleHudStyle.TOPS
const HIT_X: float = BattleHudStyle.HIT_X
const FIELD_X: float = 336.0
const FIELD_W: float = 920.0
const FIELD_H: float = 244.0

var battle: Node2D
var score: ScoreManager
var player_turn: bool = false
var active_field: String = "OPPONENT"
var feedback: String = ""
var feedback_time: float = -10.0
var feedback_lane: int = 2
var feedback_color: Color = CREAM
var hit_times := [-10.0,-10.0]
var hit_lanes := [0,0]
var hit_positive := [true,true]
var season: String = "summer"
var boss_title: String = "SOLANA"
var season_title: String = "VERÃO"
var melody_title: String = "MELODIA DA SOLANA"
var scenery: SeasonStageScenery

func setup(battle_ref: Node2D, score_ref: ScoreManager) -> void:
    battle=battle_ref
    score=score_ref
    season=str(battle.level.get("season","summer"))
    boss_title=BossCatalog.display_name(season)
    season_title=str(battle.level.get("name","VERÃO"))
    melody_title="MELODIA DA "+boss_title
    if season=="winter":
        boss_title="BÓREAS"
        melody_title="MELODIA DE BÓREAS"
    elif season=="autumn":
        melody_title="MELODIA DE SILAS"
    elif season=="tutorial":
        melody_title="MELODIA DO MENTOR"
    if season!="summer":
        # A continuous landscape below this canvas; HUD panels stay above it.
        scenery=SeasonStageScenery.new()
        scenery.show_behind_parent=true
        scenery.season=season
        scenery.boss_title=boss_title
        add_child(scenery)
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    for path in ["TopBar","Phase","RoundInfo","Judgment","Help"]:
        (battle.hud.get_node(path) as CanvasItem).hide()
    var pause: Button = battle.hud.get_node("Back") as Button
    pause.position=Vector2(1148,29)
    pause.size=Vector2(92,34)
    BattleHudStyle.style_button(pause)

func set_active_field(field_name: String) -> void:
    active_field=field_name
    player_turn=field_name=="PLAYER"
    battle.player_spawner.modulate.a=1.0 if player_turn else .9
    battle.opponent_spawner.modulate.a=.9 if player_turn else 1.0
    queue_redraw()

func pulse_lord(lane: int) -> void:
    if lane<0 or lane>3:
        return
    hit_times[1]=Conductor.get_song_position()
    hit_lanes[1]=lane

func show_judgment(result: String, lane: int) -> void:
    var texts: Dictionary = {"Perfect":"PERFEITO","Good":"BOM","Bad":"QUASE","Miss":"ERRO","Error":"ERRO","Fire":"FOGO!","Ice":"GELO!","HoldOK":"SEGUROU","HoldBreak":"SOLTOU"}
    feedback=str(texts.get(result,"ERRO"))
    feedback_lane=clampi(lane,0,3)
    feedback_time=Conductor.get_song_position()
    var positive: bool = result in ["Perfect","Good","Bad","HoldOK"]
    feedback_color=LANE_COLORS[0] if result in ["Perfect","HoldOK"] else GOLD if result in ["Good","Bad"] else CORAL
    hit_times[0]=feedback_time
    hit_lanes[0]=feedback_lane
    hit_positive[0]=positive

func _process(_delta: float) -> void:
    queue_redraw()

func _text(at: Vector2, value: String, size: int, color: Color = CREAM, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(BattleHudStyle.FONT,at.round(),value.to_upper(),alignment,width,30 if size>=23 else 20,color)

func _panel(rect: Rect2, fill: Color, edge: Color, line: float = 2.0, shadow: bool = true) -> void:
    BattleHudStyle.draw_panel(self,rect,fill,edge,line,shadow)

func _arrow(center: Vector2, lane: int, size: float, color: Color) -> void:
    BattleHudStyle.draw_arrow(self,center,lane,size,color)

func _fire_note(center: Vector2, lane: int = -1, alpha: float = 1.0, size: float = 1.0) -> void:
    BattleHudStyle.draw_fire(self,center,lane,alpha,size)

func _draw() -> void:
    if battle==null or score==null:
        return
    if scenery==null:
        _draw_beach()
    _draw_scorebar()
    if scenery==null:
        _draw_jetty()
        _text(Vector2(30,382),"VOCÊ",20,CREAM,264,HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(30,704),boss_title,20,GOLD,264,HORIZONTAL_ALIGNMENT_CENTER)
    _draw_field(0,player_turn)
    _draw_field(1,not player_turn)
    _draw_feedback()
    _panel(Rect2(648,382,412,36),GOLD,INK,2,false)
    _arrow(Vector2(674,400),0 if player_turn else 3,10,INK)
    var turn: String = "SUA VEZ / VOCÊ" if player_turn else "OBSERVE / "+boss_title
    if battle.phase=="IDLE":
        turn="SEM NOTAS" if battle.phrases.is_empty() else "VERIFIQUE O ÁUDIO"
    elif battle.phase=="FINISHED":
        turn="FIM DA APRESENTAÇÃO"
    _text(Vector2(696,409),turn,20,INK,342,HORIZONTAL_ALIGNMENT_CENTER)
    draw_rect(Rect2(852,374 if player_turn else 420,4,8 if player_turn else 12),GOLD)
    _draw_footer()

func _draw_beach() -> void:
    var sky := [Color("#34233e"),Color("#493047"),Color("#654153"),Color("#835565"),Color("#aa736f")]
    for index in range(15):
        draw_rect(Rect2(0,index*32,1280,32),sky[mini(index/3,4)])
    # Quiet beach scenery: flat sea, a few wave fragments and open sand.
    draw_rect(Rect2(0,320,1280,244),Color("#657987"))
    draw_rect(Rect2(0,322,1280,4),Color("#a6a6a1"))
    for band in range(11):
        var dy: float = -44+band*8
        var half: float = floor(sqrt(maxf(0,44*44-dy*dy))/4)*4
        draw_rect(Rect2(67-half,260+dy,half*2,8),Color("#e9b584"))
    for wave in [Rect2(28,376,54,2),Rect2(218,402,58,2),Rect2(26,456,34,2),Rect2(224,506,60,2),Rect2(8,538,74,2)]:
        draw_rect(wave,Color("#9ba7a6"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,560),Vector2(72,556),Vector2(72,552),Vector2(166,552),Vector2(166,560),Vector2(270,560),Vector2(270,568),Vector2(1280,568),Vector2(1280,720),Vector2(0,720)]),Color("#d0ac87"))
    draw_rect(Rect2(0,560,84,4),Color("#ead1aa"))
    draw_rect(Rect2(170,564,100,4),Color("#ead1aa"))
    draw_rect(Rect2(0,648,320,72),Color("#c39a78"))
    # A small palm at the far edge leaves both character silhouettes clear.
    for i in range(9):
        draw_rect(Rect2(16+i/3*2,604-i*6,4,6),Color("#514e54"))
    for frond in [Rect2(0,540,26,4),Rect2(24,536,20,4),Rect2(44,540,16,4),Rect2(4,548,18,4),Rect2(27,544,17,4)]:
        draw_rect(frond,Color("#514e54"))
    draw_colored_polygon(PackedVector2Array([Vector2(48,678),Vector2(68,672),Vector2(246,672),Vector2(266,678),Vector2(246,684),Vector2(68,684)]),Color("#936c5d"))

func _draw_jetty() -> void:
    draw_rect(Rect2(22,346,280,12),Color("#634856"))
    draw_rect(Rect2(22,344,280,4),Color("#cfaa87"))
    draw_rect(Rect2(26,358,6,14),Color("#4b3b4c"))
    draw_rect(Rect2(290,358,6,14),Color("#4b3b4c"))
    for x in range(46,290,34):
        draw_rect(Rect2(x,348,2,8),Color("#352b3b"))

func _draw_scorebar() -> void:
    _panel(Rect2(20,14,1240,66),Color("#211a31"),Color("#947286"))
    _text(Vector2(36,48),"ECHO",30)
    _text(Vector2(125,47),boss_title+"/"+season_title,20,GOLD)
    _metric(342,"PONTUAÇÃO","%06d" % score.score)
    _metric(551,"COMBO","X%d" % score.combo)
    _metric(707,"PRECISÃO",("%.1f%%" % score.get_accuracy()).replace(".",","))
    _text(Vector2(898,34),"ENERGIA",20,MUTED)
    _text(Vector2(1050,34),"%.0f%%" % score.energy,20,CREAM,55,HORIZONTAL_ALIGNMENT_RIGHT)
    draw_rect(Rect2(898,44,207,16),INK)
    for cell in range(20):
        draw_rect(Rect2(902+cell*10,48,8,8),GOLD if float(cell)<score.energy/5.0 else Color("#5f4d60"))

func _metric(x: float, title: String, value: String) -> void:
    _text(Vector2(x,34),title,20,MUTED)
    _text(Vector2(x,64),value,30)

func _draw_field(index: int, active: bool) -> void:
    var top: float = TOPS[index]
    _panel(Rect2(FIELD_X,top,FIELD_W,FIELD_H),Color("#262239") if active else Color("#191929"),GOLD if active else Color("#776279"),3 if active else 2)
    var title: String = "SEU ECO" if index == 0 else melody_title
    if season=="spring":
        # Pixel outline keeps the approved lettering readable against daylight.
        for offset in [Vector2(-2,0),Vector2(2,0),Vector2(0,-2),Vector2(0,2)]:
            draw_string(BattleHudStyle.FONT,Vector2(FIELD_X,top-16)+offset,title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,INK)
    _text(Vector2(FIELD_X,top-16),title,20,CREAM if active else MUTED)
    for lane in range(4):
        var y: float = top+30+58*lane
        draw_rect(Rect2(HIT_X+34,y-25,FIELD_X+FIELD_W-HIT_X-42,50),Color(LANE_COLORS[lane],.055 if active else .025))
        draw_line(Vector2(HIT_X+34,y),Vector2(1238,y),Color(LANE_COLORS[lane],.22 if active else .15),2,false)
    draw_rect(Rect2(HIT_X-28,top+8,56,FIELD_H-16),Color("#151526"))
    draw_rect(Rect2(HIT_X-2,top+8,4,FIELD_H-16),CREAM if active else Color("#a799ae"))
    for lane in range(4):
        _arrow(Vector2(HIT_X,top+30+58*lane),lane,20,Color(LANE_COLORS[lane],1.0 if active else .9))
    draw_rect(Rect2(HIT_X-8,top+6,16,4),CREAM if active else MUTED)
    draw_rect(Rect2(HIT_X-8,top+FIELD_H-10,16,4),CREAM if active else MUTED)
    var age: float = Conductor.get_song_position()-float(hit_times[index])
    if age>=0 and age<.22:
        var center := Vector2(HIT_X,top+30+58*int(hit_lanes[index]))
        var radius: float = 24+floor(age/.05)*2
        var color := Color(LANE_COLORS[int(hit_lanes[index])] if hit_positive[index] else CORAL,1.0-age/.24)
        for sign_x in [-1,1]:
            for sign_y in [-1,1]:
                draw_rect(Rect2(center+Vector2(sign_x*radius-2,sign_y*18-2),Vector2(4,4)),color)

func _draw_feedback() -> void:
    if not player_turn or feedback=="" or Conductor.get_song_position()-feedback_time>.65:
        return
    var y: float = TOPS[0]+30+58*feedback_lane
    _text(Vector2(346,y-2),feedback,20,feedback_color,98,HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(346,y+22),"X%d" % score.combo,20,CREAM,98,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_footer() -> void:
    if season=="summer":
        _fire_note(Vector2(350,702),-1,1,.32)
    elif season=="tutorial":
        _arrow(Vector2(350,702),0,9,LANE_COLORS[0])
    else:
        _mechanic_icon(Vector2(350,702))
    var hints: Dictionary = {"tutorial":"OUÇA E REPITA","summer":"EVITE O FOGO","winter":"EVITE O GELO","autumn":"DEIXE AS FOLHAS","spring":"MEMORIZE AS NOTAS"}
    _text(Vector2(368,710),str(hints.get(season,"")),20,INK)
    var now: float = Conductor.get_song_position()
    var duration: float = maxf(Conductor.beat_to_seconds(battle.last_player_beat+.8),.01)
    draw_rect(Rect2(626,698,472,4),Color("#6e4e69"))
    draw_rect(Rect2(626,698,472*clampf(now/duration,0,1),4),GOLD)
    _text(Vector2(1108,710),"%s/%s" % [_time(now),_time(duration)],20,INK,148,HORIZONTAL_ALIGNMENT_RIGHT)

func _time(seconds: float) -> String:
    return "%02d:%02d" % [int(seconds)/60,int(seconds)%60]

func _mechanic_icon(center: Vector2) -> void:
    if season=="winter":
        for direction in [Vector2(0,9),Vector2(8,5),Vector2(8,-5)]:
            draw_line(center-direction,center+direction,Color("#83deec"),2,false)
    elif season=="autumn":
        var leaf := PackedVector2Array([center+Vector2(-8,6),center+Vector2(-6,-6),center+Vector2(8,-8),center+Vector2(6,6)])
        draw_colored_polygon(leaf,Color("#dd985c"))
        draw_line(center+Vector2(-8,8),center+Vector2(6,-6),INK,2,false)
    else:
        for direction in [Vector2(-6,0),Vector2(6,0),Vector2(0,-6),Vector2(0,6)]:
            draw_rect(Rect2(center+direction-Vector2(3,3),Vector2(6,6)),Color("#de92b9"))
        draw_rect(Rect2(center-Vector2(2,2),Vector2(4,4)),GOLD)

func style_result(victory: bool) -> void:
    var panel: Panel = battle.hud.get_node("ResultPanel") as Panel
    panel.position=Vector2(300,144)
    panel.size=Vector2(680,440)
    panel.add_theme_stylebox_override("panel",BattleHudStyle.box(Color("#211a31"),GOLD,4))
    for child in panel.get_children():
        if child is Label:
            child.add_theme_font_override("font",BattleHudStyle.FONT)
            child.add_theme_font_size_override("font_size",20)
            child.add_theme_color_override("font_color",CREAM)
        elif child is StarRow:
            child.position=Vector2(240,84)
    var title: Label = panel.get_node("Title") as Label
    title.text="ECO COMPLETO" if victory else "FIM DA APRESENTAÇÃO"
    title.position=Vector2(20,24)
    title.size=Vector2(640,44)
    title.add_theme_font_size_override("font_size",30)
    var stats: Label = panel.get_node("Stats") as Label
    stats.position=Vector2(30,126)
    stats.size=Vector2(620,130)
    stats.text="PONTUAÇÃO  %d\nPRECISÃO  %.1f%%\nNOTAS  %d / %d\nMAIOR COMBO  %d" % [score.score,score.get_accuracy(),score.hit_notes,score.total_notes,score.max_combo]
    var hint: Label = panel.get_node("Hint") as Label
    hint.position=Vector2(30,268)
    hint.size=Vector2(620,148)
    hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    hint.text=hint.text.to_upper().replace("—","-")
    hint.add_theme_color_override("font_color",GOLD)
