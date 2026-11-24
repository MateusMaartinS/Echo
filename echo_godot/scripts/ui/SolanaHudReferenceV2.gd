extends "res://scripts/ui/SolanaHudReference.gd"

# Isolated visual readability bench: no Battle, Judge, chart or save changes.
const TOPS := [130.0,432.0]
const HIT_X: float = 478.0
const HERO_FEET := Vector2(162,346)
const SOLANA_FEET := Vector2(162,672)
const BPM: float = 160.0
const PERIOD: float = 12.0
const SPEED: float = 448.0

var pixel_font: Font
var demo_time: float = 0.0
var playing: bool = true
var exporting: bool = false
var events: Array[Dictionary] = []
var feedback: String = ""
var feedback_time: float = -10.0
var feedback_lane: int = 2
var combo: int = 0
var hit_times := [-10.0,-10.0]
var hit_lanes := [0,0]
var score_example: int = 6240

func _ready() -> void:
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    pixel_font=load("res://assets/fonts/echo_pixel.fnt") as Font
    exporting="--export-solana-hud-v2" in OS.get_cmdline_user_args() or "--export-solana-hud-animation" in OS.get_cmdline_user_args()
    hero=SkinCatalog.create_player("classic_female") as SpritePlayer
    solana=BossCatalog.create_lord("summer") as SpriteLord
    add_child(hero)
    add_child(solana)
    _fit_character(hero,HERO_HEIGHT,HERO_FEET)
    _fit_character(solana,BOSS_HEIGHT,SOLANA_FEET)
    _build_menu()
    _make_sequence()
    player_turn=false
    print("HUD V2: visible heights ",HERO_HEIGHT," / ",BOSS_HEIGHT,"; fixed 1.3 ratio; ",events.size()," synthetic events / 12s; 160 BPM")
    if "--export-solana-hud-v2" in OS.get_cmdline_user_args():
        await _export_stills()
        get_tree().quit()
    elif "--export-solana-hud-animation" in OS.get_cmdline_user_args():
        await _export_animation()
        get_tree().quit()

func _fit_character(actor: SpritePlayer, height: float, feet: Vector2) -> void:
    super._fit_character(actor,height,feet)
    # Keep the idle normalization stable when the original pose anchors change.
    var anchor: Vector2 = actor.animations["idle"]["anchors"][0]
    var native_y: float = -anchor.y*actor.sprite.scale.y
    actor.visual.position.y+=actor.sprite.position.y-native_y
    actor.sprite.position.y=native_y

func _box(fill: Color, border: Color, width: int = 1, _radius: int = 0) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color=fill
    style.border_color=border
    style.set_border_width_all(maxi(2,width))
    style.set_corner_radius_all(0)
    return style

func _text(at: Vector2, value: String, size: int, color: Color = CREAM, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(pixel_font,at.round(),value.to_upper(),alignment,width,30 if size>=23 else 20,color)

func _style_button(button: Button) -> void:
    super._style_button(button)
    button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    button.add_theme_font_override("font",pixel_font)
    button.add_theme_font_size_override("font_size",20)

func _build_menu() -> void:
    super._build_menu()
    for label in [menu_title,controls]:
        label.add_theme_font_override("font",pixel_font)
        label.add_theme_font_size_override("font_size",30 if label == menu_title else 20)
    controls.text="CIMA      D / ↑\nDIREITA   F / →\nESQUERDA  J / ←\nBAIXO     K / ↓\nESPAÇO: PAUSAR DEMO\nESC: ABRIR / FECHAR PAUSA"

func _make_sequence() -> void:
    var lanes := [0,1,2,3,2,0,3,1]
    for field in range(2):
        for index in range(64):
            var lane: int = lanes[index%lanes.size()]
            var at: float = fposmod(.5+index*(60.0/BPM/2.0)+(60.0/BPM*4.0 if field == 0 else 0.0),PERIOD)
            var fire: bool = index%12 == 7
            var hold: float = 60.0/BPM if index%16 == 5 else 0.0
            events.append({"field":field,"lane":lane,"at":at,"fire":fire,"hold":hold,"index":index})
            if index%8 == 3:
                events.append({"field":field,"lane":(lane+2)%4,"at":at,"fire":false,"hold":0.0,"index":index+100})
    events.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["at"])<float(b["at"]))

func _process(delta: float) -> void:
    if not exporting and playing and menu != null and not menu.visible:
        _advance(delta)

func _advance(delta: float) -> void:
    var before: float = demo_time
    demo_time+=delta
    player_turn=fposmod(demo_time,PERIOD)>=6.0
    for period in range(int(floor(before/PERIOD)),int(floor(demo_time/PERIOD))+1):
        for event in events:
            var at: float = period*PERIOD+float(event["at"])
            if at<=before or at>demo_time:
                continue
            var field: int = int(event["field"])
            var active_field: int = 0 if fposmod(at,PERIOD)>=6.0 else 1
            if field != active_field:
                continue
            if bool(event["fire"]) and field == 0:
                continue # Autoplay avoids the fire lane; it is not a scoring note.
            var actor: SpritePlayer = hero if field == 0 else solana
            actor.play_pose(int(event["lane"]),maxf(.22,float(event["hold"])))
            hit_times[field]=at
            hit_lanes[field]=int(event["lane"])
            if field == 0:
                feedback="ERRO" if int(event["index"])%17 == 15 else ("BOM" if int(event["index"])%7 == 4 else "PERFEITO")
                combo=0 if feedback == "ERRO" else combo+1
                score_example+=0 if feedback == "ERRO" else 100
                feedback_time=at
                feedback_lane=int(event["lane"])
    for actor in [hero,solana]:
        actor.rhythm_beat=demo_time*BPM/60.0
        actor._process(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_ESCAPE:
            _toggle_menu()
        elif event.physical_keycode == KEY_SPACE and not menu.visible:
            playing=not playing

func _steps(rect: Rect2) -> PackedVector2Array:
    var x: float = rect.position.x
    var y: float = rect.position.y
    var r: float = rect.end.x
    var b: float = rect.end.y
    return PackedVector2Array([Vector2(x+6,y),Vector2(r-6,y),Vector2(r-6,y+2),Vector2(r-2,y+2),Vector2(r-2,y+6),Vector2(r,y+6),Vector2(r,b-6),Vector2(r-2,b-6),Vector2(r-2,b-2),Vector2(r-6,b-2),Vector2(r-6,b),Vector2(x+6,b),Vector2(x+6,b-2),Vector2(x+2,b-2),Vector2(x+2,b-6),Vector2(x,b-6),Vector2(x,y+6),Vector2(x+2,y+6),Vector2(x+2,y+2),Vector2(x+6,y+2)])

func _panel(rect: Rect2, fill: Color, edge: Color, line: float = 2.0, shadow: bool = true) -> void:
    if shadow:
        draw_colored_polygon(_steps(Rect2(rect.position+Vector2(4,4),rect.size)),INK)
    var points: PackedVector2Array = _steps(rect)
    draw_colored_polygon(points,fill)
    points.append(points[0])
    draw_polyline(points,edge,line,false)

func _draw() -> void:
    if pixel_font == null:
        return
    _draw_beach()
    _draw_scorebar()
    _draw_jetty()
    _text(Vector2(30,382),"VOCÊ",20,CREAM,264,HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(30,704),"SOLANA",20,GOLD,264,HORIZONTAL_ALIGNMENT_CENTER)
    _draw_field(0,player_turn)
    _draw_field(1,not player_turn)
    _draw_sequence()
    _draw_feedback()
    # Fixed position; direction and actor name make the owner explicit.
    _panel(Rect2(648,382,412,36),GOLD,INK,2,false)
    _arrow(Vector2(674,400),0 if player_turn else 3,10,INK)
    _text(Vector2(696,409),"SUA VEZ / VOCÊ" if player_turn else "OBSERVE / SOLANA",20,INK,342,HORIZONTAL_ALIGNMENT_CENTER)
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
    _text(Vector2(125,47),"SOLANA/VERÃO",20,GOLD)
    _metric(342,"PONTUAÇÃO","%06d" % score_example)
    _metric(551,"COMBO","X%d" % combo)
    _metric(707,"PRECISÃO","98,6%")
    _text(Vector2(898,34),"ENERGIA",20,MUTED)
    _text(Vector2(1050,34),"86%",20,CREAM,55,HORIZONTAL_ALIGNMENT_RIGHT)
    draw_rect(Rect2(898,44,207,16),INK)
    for cell in range(20):
        draw_rect(Rect2(902+cell*10,48,8,8),GOLD if cell<17 else Color("#5f4d60"))

func _metric(x: float, title: String, value: String) -> void:
    _text(Vector2(x,34),title,20,MUTED)
    _text(Vector2(x,64),value,30)

func _draw_field(index: int, active: bool) -> void:
    var top: float = TOPS[index]
    _panel(Rect2(FIELD_X,top,FIELD_W,FIELD_H),Color("#262239") if active else Color("#191929"),GOLD if active else Color("#776279"),3 if active else 2)
    _text(Vector2(FIELD_X,top-16),"SEU ECO" if index == 0 else "MELODIA DA SOLANA",20,CREAM if active else MUTED)
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
    var age: float = demo_time-float(hit_times[index])
    if age>=0 and age<.22:
        var center := Vector2(HIT_X,top+30+58*int(hit_lanes[index]))
        var radius: float = 24+floor(age/.05)*2
        var color := Color(LANE_COLORS[int(hit_lanes[index])],1.0-age/.24)
        for sign_x in [-1,1]:
            for sign_y in [-1,1]:
                draw_rect(Rect2(center+Vector2(sign_x*radius-2,sign_y*18-2),Vector2(4,4)),color)

func _arrow(center: Vector2, lane: int, size: float, color: Color) -> void:
    var points: PackedVector2Array = Lanes.arrow_points(lane,center,size)
    for i in range(points.size()):
        points[i]=(points[i]/2.0).round()*2.0
    draw_colored_polygon(points,color)
    points.append(points[0])
    draw_polyline(points,Color(INK,color.a),4 if size>=16 else 2,false)

func _draw_sequence() -> void:
    for cycle in range(int(floor(demo_time/PERIOD))-1,int(floor(demo_time/PERIOD))+2):
        for event in events:
            var at: float = cycle*PERIOD+float(event["at"])
            var age: float = demo_time-at
            var hold: float = float(event["hold"])
            if age>0 and (bool(event["fire"]) or hold<=0 or age>hold):
                continue
            var x: float = HIT_X+maxf(0,at-demo_time)*SPEED
            if x>1230:
                continue
            var field: int = int(event["field"])
            var lane: int = int(event["lane"])
            if bool(event["fire"]):
                _fire_note(Vector2(x,TOPS[field]+30+58*lane),lane,1.0 if (player_turn if field == 0 else not player_turn) else .9)
            else:
                _note(field,lane,x,maxf(0,hold-maxf(0,age))*SPEED)

func _note(field: int, lane: int, x: float, tail: float = 0.0) -> void:
    var active: bool = player_turn if field == 0 else not player_turn
    var color := Color(LANE_COLORS[lane],1.0 if active else .9)
    var center := Vector2(round(x/2)*2,TOPS[field]+30+58*lane)
    var length: float = minf(tail,1238-center.x)
    if length>0:
        draw_rect(Rect2(center-Vector2(0,7),Vector2(length,14)),INK)
        draw_rect(Rect2(center-Vector2(0,3),Vector2(length,6)),color)
    _arrow(center,lane,20,color)

func _fire_note(center: Vector2, lane: int = -1, alpha: float = 1.0, size: float = 1.0) -> void:
    var points := PackedVector2Array([Vector2(0,-25),Vector2(6,-10),Vector2(12,-17),Vector2(18,-3),Vector2(18,8),Vector2(11,20),Vector2(0,25),Vector2(-11,20),Vector2(-18,10),Vector2(-17,-1),Vector2(-9,-12),Vector2(-9,1),Vector2(-2,-7)])
    for i in range(points.size()):
        points[i]=((center+points[i]*size)/2).round()*2
    draw_colored_polygon(points,Color(Color("#ff7857"),alpha))
    points.append(points[0])
    draw_polyline(points,Color(INK,alpha),4 if size>=1 else 2,false)
    if lane>=0:
        _arrow(center+Vector2(0,7)*size,lane,10*size,Color(CREAM,alpha))
    for offset in [Vector2(-10,-28),Vector2(8,-34),Vector2(18,-24)]:
        draw_rect(Rect2((center+offset*size).round(),Vector2.ONE*maxf(2,4*size)),Color(GOLD,alpha))

func _draw_feedback() -> void:
    if not player_turn or demo_time-feedback_time>.8 or feedback == "":
        return
    var y: float = TOPS[0]+30+58*feedback_lane
    var color: Color = CORAL if feedback == "ERRO" else GOLD if feedback == "BOM" else LANE_COLORS[0]
    _text(Vector2(346,y-2),feedback,20,color,98,HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(346,y+22),"X%d" % combo,20,CREAM,98,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_footer() -> void:
    _fire_note(Vector2(350,702),-1,1,.32)
    _text(Vector2(368,710),"EVITE O FOGO",20,INK)
    draw_rect(Rect2(626,698,472,4),Color("#6e4e69"))
    draw_rect(Rect2(626,698,472*fposmod(demo_time,PERIOD)/PERIOD,4),GOLD)
    _text(Vector2(1108,710),"00:%02d/00:12" % int(fposmod(demo_time,PERIOD)),20,INK,148,HORIZONTAL_ALIGNMENT_RIGHT)

func _snapshot(path: String) -> void:
    queue_redraw()
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(path)

func _export_stills() -> void:
    for active_player in [true,false]:
        demo_time=8.9 if active_player else 2.9
        player_turn=active_player
        combo=34
        feedback="PERFEITO"
        feedback_time=demo_time-.08
        feedback_lane=2
        hit_times[0]=feedback_time
        hit_lanes[0]=2
        await _snapshot("res://art_preview/hud_solana_v2_%s.png" % ("sua_vez" if player_turn else "observe"))
    menu.visible=true
    _toggle_controls()
    await _snapshot("res://art_preview/hud_solana_v2_controles.png")
    menu.visible=false

func _export_animation() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(1280,720))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/hud_reference_frames/solana_v2"))
    await get_tree().process_frame
    demo_time=0.0
    for frame in range(144):
        _advance(1.0/12.0)
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://.godot/hud_reference_frames/solana_v2/frame_%03d.png" % frame)
    print("HUD V2: 144 animation frames exported at 12 fps")
