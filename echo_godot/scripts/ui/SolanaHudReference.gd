extends Node2D

# Visual proposal only. Battle, note timing, controls and saved data are untouched.
const INK := Color("#151122")
const CREAM := Color("#fff0d5")
const MUTED := Color("#c9a8b7")
const GOLD := Color("#f7cc80")
const CORAL := Color("#ff9b87")
const LANE_COLORS := [Color("#83deec"),Color("#ff9d89"),Color("#c3adfa"),Color("#f2d887")]
const FIELD_X: float = 336.0
const FIELD_W: float = 920.0
const FIELD_H: float = 244.0
const FIELD_TOPS := [130.0,416.0]
const TARGET_X: float = 394.0
const HERO_HEIGHT: float = 196.0
const BOSS_HEIGHT: float = HERO_HEIGHT*1.3

var player_turn: bool = true
var hero: SpritePlayer
var solana: SpriteLord
var menu: ColorRect
var menu_title: Label
var controls: Label
var controls_button: Button
var normalization: Dictionary = {}

func _ready() -> void:
    hero=SkinCatalog.create_player("classic_female") as SpritePlayer
    solana=BossCatalog.create_lord("summer") as SpriteLord
    add_child(hero)
    add_child(solana)
    _fit_character(hero,HERO_HEIGHT,Vector2(162,368))
    _fit_character(solana,BOSS_HEIGHT,Vector2(162,654))
    _build_menu()
    print("HUD REFERENCE: hero=",HERO_HEIGHT,"px; Solana=",BOSS_HEIGHT,"px; ratio=",BOSS_HEIGHT/HERO_HEIGHT,"; visible bounds=",normalization)
    if "--export-solana-hud-reference" in OS.get_cmdline_user_args():
        for active_player in [true,false]:
            player_turn=active_player
            queue_redraw()
            await get_tree().process_frame
            await RenderingServer.frame_post_draw
            await RenderingServer.frame_post_draw
            var suffix: String = "sua_vez" if player_turn else "observe"
            get_viewport().get_texture().get_image().save_png("res://art_preview/hud_solana_%s.png" % suffix)
        _toggle_menu()
        _toggle_controls()
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://art_preview/hud_solana_controles.png")
        get_tree().quit()

func _fit_character(actor: SpritePlayer, height: float, feet: Vector2) -> void:
    actor.set_process(false)
    actor._show_frame("idle",0)
    var atlas: AtlasTexture = actor.sprite.texture as AtlasTexture
    var sheet: Image = atlas.atlas.get_image()
    if sheet.is_compressed():
        sheet.decompress()
    sheet.convert(Image.FORMAT_RGBA8)
    var data: PackedByteArray = sheet.get_data()
    var region: Rect2i = Rect2i(atlas.region)
    var top: int = region.size.y
    var bottom: int = -1
    for y in range(region.size.y):
        for x in range(region.size.x):
            var k: int = ((region.position.y+y)*sheet.get_width()+region.position.x+x)*4
            if data[k+3]>=128:
                top=mini(top,y)
                bottom=maxi(bottom,y)
    var visible_height: float = float(bottom-top+1)
    var image_scale: float = actor.sprite.scale.x
    var scale_value: float = height/(visible_height*image_scale)
    actor.scale=Vector2.ONE*scale_value
    # Feet are positioned by the visible soles, not the transparent PNG canvas.
    actor.sprite.position.y=-float(bottom+1)*image_scale
    actor.position=feet-Vector2(0,SpritePlayer.FOOT_Y*scale_value)
    normalization[actor.outfit]={"source_visible_height":visible_height,"target_height":height,"outer_scale":scale_value,"feet":feet}

func _box(fill: Color, border: Color, width: int = 1, radius: int = 12) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color=fill
    style.border_color=border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    return style

func _text(at: Vector2, value: String, size: int, color: Color = CREAM, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(ThemeDB.fallback_font,at,value,alignment,width,size,color)

func _build_menu() -> void:
    var pause := Button.new()
    pause.text="PAUSA"
    pause.position=Vector2(1148,29)
    pause.size=Vector2(92,34)
    pause.focus_mode=Control.FOCUS_NONE
    _style_button(pause)
    pause.pressed.connect(_toggle_menu)
    add_child(pause)
    menu=ColorRect.new()
    menu.color=Color(.035,.02,.07,.86)
    menu.size=Vector2(1280,720)
    menu.z_index=20
    menu.visible=false
    add_child(menu)
    var panel := Panel.new()
    panel.position=Vector2(414,166)
    panel.size=Vector2(452,390)
    panel.add_theme_stylebox_override("panel",_box(Color("#251c35"),GOLD,2,16))
    menu.add_child(panel)
    menu_title=Label.new()
    menu_title.text="PAUSA"
    menu_title.position=Vector2(30,24)
    menu_title.size=Vector2(392,40)
    menu_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    menu_title.add_theme_font_size_override("font_size",25)
    menu_title.add_theme_color_override("font_color",CREAM)
    panel.add_child(menu_title)
    controls=Label.new()
    controls.text="CIMA        D / ↑\nDIREITA     F / →\nESQUERDA    J / ←\nBAIXO       K / ↓\n\nESC: abrir ou fechar a pausa"
    controls.position=Vector2(42,84)
    controls.size=Vector2(368,164)
    controls.add_theme_font_size_override("font_size",18)
    controls.add_theme_color_override("font_color",CREAM)
    controls.visible=false
    panel.add_child(controls)
    controls_button=Button.new()
    controls_button.text="CONTROLES"
    controls_button.position=Vector2(42,270)
    controls_button.size=Vector2(368,40)
    _style_button(controls_button)
    controls_button.pressed.connect(_toggle_controls)
    panel.add_child(controls_button)
    var resume := Button.new()
    resume.text="CONTINUAR"
    resume.position=Vector2(42,324)
    resume.size=Vector2(368,40)
    _style_button(resume)
    resume.pressed.connect(_toggle_menu)
    panel.add_child(resume)

func _style_button(button: Button) -> void:
    button.add_theme_stylebox_override("normal",_box(Color("#38263f"),Color("#a77b73"),1,8))
    button.add_theme_stylebox_override("hover",_box(Color("#57404e"),GOLD,1,8))
    button.add_theme_stylebox_override("pressed",_box(Color("#4c3345"),GOLD,2,8))
    button.add_theme_color_override("font_color",CREAM)
    button.add_theme_font_size_override("font_size",13)

func _toggle_menu() -> void:
    menu.visible=not menu.visible
    if menu.visible:
        controls.visible=false
        menu_title.text="PAUSA"
        controls_button.text="CONTROLES"

func _toggle_controls() -> void:
    controls.visible=not controls.visible
    menu_title.text="CONTROLES" if controls.visible else "PAUSA"
    controls_button.text="VOLTAR" if controls.visible else "CONTROLES"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_ESCAPE:
            _toggle_menu()
        elif event.physical_keycode == KEY_SPACE and not menu.visible:
            player_turn=not player_turn
            queue_redraw()

func _draw() -> void:
    _draw_sunset()
    _draw_scorebar()
    _draw_stage(Vector2(162,369),player_turn)
    _draw_stage(Vector2(162,655),not player_turn)
    _text(Vector2(32,114),"ECHO  /  VERÃO",12,Color("#ffe5c0"))
    _text(Vector2(30,393),"VOCÊ",13,CREAM,264,HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(30,686),"SOLANA",17,GOLD,264,HORIZONTAL_ALIGNMENT_CENTER)
    _draw_field(0,player_turn)
    _draw_field(1,not player_turn)
    _draw_example_notes()
    var turn_y: float = 94.0 if player_turn else 380.0
    draw_style_box(_box(GOLD,Color("#50313e"),1,9),Rect2(1072,turn_y,184,29))
    _text(Vector2(1072,turn_y+20),"SUA VEZ" if player_turn else "OBSERVE",15,INK,184,HORIZONTAL_ALIGNMENT_CENTER)
    if player_turn:
        _text(Vector2(762,115),"PERFEITO!",13,LANE_COLORS[0])
    _draw_footer()

func _draw_sunset() -> void:
    var top := Color("#34203f")
    var middle := Color("#a94d67")
    var bottom := Color("#ed9973")
    for y in range(720):
        var t: float = float(y)/719.0
        var color: Color = top.lerp(middle,t/.62) if t<.62 else middle.lerp(bottom,(t-.62)/.38)
        draw_rect(Rect2(0,y,1280,1),color)
    draw_circle(Vector2(154,491),154,Color(1,.7,.37,.08))
    draw_circle(Vector2(154,491),137,Color(1,.73,.39,.13))
    draw_circle(Vector2(154,491),119,Color("#f7ba78"))
    for y in range(503,615,17):
        draw_line(Vector2(0,y),Vector2(318,y),Color("#c57579"),4)
    draw_colored_polygon(PackedVector2Array([Vector2(0,574),Vector2(71,547),Vector2(143,559),Vector2(208,530),Vector2(318,571),Vector2(318,720),Vector2(0,720)]),Color("#513149"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,629),Vector2(93,599),Vector2(187,624),Vector2(318,590),Vector2(318,720),Vector2(0,720)]),Color("#2f233a"))
    # Decoration stays on the stage and outer edges, outside the note fields.
    draw_polyline(PackedVector2Array([Vector2(19,673),Vector2(29,626),Vector2(26,578),Vector2(16,544)]),Color("#302137"),7,true)
    for end in [Vector2(-35,516),Vector2(2,501),Vector2(64,508),Vector2(84,536),Vector2(69,560),Vector2(-26,550)]:
        draw_line(Vector2(16,544),end,Color("#302137"),5,true)
    var rng := RandomNumberGenerator.new()
    rng.seed=731
    for i in range(29):
        var x: float = rng.randf_range(9,311) if i<21 else rng.randf_range(1264,1278)
        var y: float = rng.randf_range(155,690)
        draw_circle(Vector2(x,y),rng.randf_range(1,2),Color(1,.69,.35,rng.randf_range(.18,.45)))

func _draw_scorebar() -> void:
    draw_style_box(_box(Color("#211a31"),Color("#765065"),1,12),Rect2(20,14,1240,66))
    _text(Vector2(36,44),"ECHO",25,CREAM)
    _text(Vector2(125,43),"SOLANA / VERÃO",12,GOLD)
    _metric(342,"PONTUAÇÃO","006240")
    _metric(551,"COMBO","×34")
    _metric(707,"PRECISÃO","98,6%")
    _text(Vector2(898,34),"ENERGIA",10,MUTED)
    _text(Vector2(1050,34),"86%",11,CREAM,55,HORIZONTAL_ALIGNMENT_RIGHT)
    draw_style_box(_box(Color("#151322"),Color("#665068"),1,6),Rect2(898,44,207,14))
    draw_style_box(_box(Color("#f7c880"),Color(0,0,0,0),0,5),Rect2(901,47,173,8))

func _metric(x: float, title: String, value: String) -> void:
    _text(Vector2(x,33),title,10,MUTED)
    _text(Vector2(x,60),value,23,CREAM)

func _draw_stage(feet: Vector2, active: bool) -> void:
    draw_set_transform(feet,0,Vector2(1,.18))
    draw_circle(Vector2.ZERO,124,Color(.09,.065,.14,.6))
    draw_arc(Vector2.ZERO,122,0,TAU,70,Color(1,.72,.43,.65 if active else .26),3,true)
    draw_arc(Vector2.ZERO,110,0,PI,35,Color(1,.5,.34,.34 if active else .13),8,true)
    draw_set_transform(Vector2.ZERO)

func _draw_field(index: int, active: bool) -> void:
    var top: float = FIELD_TOPS[index]
    var rect := Rect2(FIELD_X,top,FIELD_W,FIELD_H)
    if active:
        draw_style_box(_box(Color(1,.7,.45,.08),Color(1,.7,.45,.13),1,15),rect.grow(5))
    draw_style_box(_box(Color("#211b32"),GOLD if active else Color("#78546c"),2 if active else 1,12),rect)
    _text(Vector2(FIELD_X,top-15),"SEU ECO" if index == 0 else "MELODIA DA SOLANA",11,CREAM if active else MUTED)
    for lane in range(4):
        var y: float = top+30+58*lane
        draw_style_box(_box(Color(LANE_COLORS[lane],.045 if active else .025),Color(0,0,0,0),0,5),Rect2(FIELD_X+7,y-25,FIELD_W-14,50))
        draw_line(Vector2(TARGET_X+39,y),Vector2(1237,y),Color(LANE_COLORS[lane],.17 if active else .075),1,true)
    draw_style_box(_box(Color("#151426"),Color("#68536a"),1,8),Rect2(TARGET_X-28,top+7,56,FIELD_H-14))
    for lane in range(4):
        _arrow(Vector2(TARGET_X,top+30+58*lane),lane,19,Color(LANE_COLORS[lane],1.0 if active else .56))

func _arrow(center: Vector2, lane: int, size: float, color: Color) -> void:
    var points: PackedVector2Array = Lanes.arrow_points(lane,center,size)
    var outline: PackedVector2Array = Lanes.arrow_outline(lane,center,size)
    draw_colored_polygon(points,color)
    draw_polyline(outline,Color(INK,color.a),3,true)

func _note(field: int, lane: int, x: float, tail: float = 0.0) -> void:
    var active: bool = player_turn if field == 0 else not player_turn
    var color := Color(LANE_COLORS[lane],1.0 if active else .5)
    var center := Vector2(x,FIELD_TOPS[field]+30+58*lane)
    if tail>0:
        draw_line(center,center+Vector2(tail,0),Color(INK,color.a),14,true)
        draw_line(center,center+Vector2(tail,0),color,8,true)
        draw_circle(center+Vector2(tail,0),4,color)
    _arrow(center,lane,21,color)

func _fire(center: Vector2, alpha: float = 1.0, size: float = 1.0) -> void:
    var points := PackedVector2Array([Vector2(0,-25),Vector2(6,-10),Vector2(12,-17),Vector2(18,-3),Vector2(18,8),Vector2(11,20),Vector2(0,25),Vector2(-11,20),Vector2(-18,10),Vector2(-17,-1),Vector2(-9,-12),Vector2(-9,1),Vector2(-2,-7)])
    for i in range(points.size()):
        points[i]=center+points[i]*size
    draw_colored_polygon(points,Color(Color("#ff7559"),alpha))
    var outline: PackedVector2Array = points.duplicate()
    outline.append(points[0])
    draw_polyline(outline,Color(INK,alpha),3,true)
    var core := PackedVector2Array([center+Vector2(0,-8)*size,center+Vector2(8,7)*size,center+Vector2(5,17)*size,center+Vector2(-4,18)*size,center+Vector2(-8,9)*size])
    draw_colored_polygon(core,Color(GOLD,alpha))
    for at in [Vector2(-10,-28),Vector2(8,-33),Vector2(16,-24)]:
        draw_circle(center+at*size,1.7*size,Color(GOLD,alpha*.8))

func _draw_example_notes() -> void:
    _note(0,0,663,139)
    _note(0,0,1082)
    _note(0,1,802)
    _note(0,2,526)
    _note(0,2,961)
    _note(0,3,882)
    _fire(Vector2(1171,334),1.0 if player_turn else .5)
    _note(1,0,574)
    _note(1,1,797)
    _note(1,2,1007,124)
    _note(1,3,692)
    _note(1,0,1101)
    _fire(Vector2(1171,504),.5 if player_turn else 1.0)

func _draw_footer() -> void:
    _fire(Vector2(350,693),.95,.33)
    _text(Vector2(368,699),"EVITE AS CHAMAS",11,CREAM)
    draw_line(Vector2(626,690),Vector2(1111,690),Color("#6e4e69"),4,true)
    draw_line(Vector2(626,690),Vector2(869,690),GOLD,4,true)
    draw_circle(Vector2(869,690),4,GOLD)
    _text(Vector2(1130,699),"01:24 / 02:48",11,CREAM,126,HORIZONTAL_ALIGNMENT_RIGHT)
