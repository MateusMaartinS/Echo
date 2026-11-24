extends RefCounted
class_name BattleHudStyle

# Approved geometry shared by the four seasonal arenas, receptors and notes.
const INK := Color("#151122")
const CREAM := Color("#fff0d5")
const MUTED := Color("#c9a8b7")
const GOLD := Color("#f7cc80")
const CORAL := Color("#ff9b87")
const LANE_COLORS := [Color("#83deec"),Color("#ff9b87"),Color("#c3adfa"),Color("#f2d887")]
const FONT: Font = preload("res://assets/fonts/echo_pixel.fnt")
const TOPS := [130.0,432.0]
const PLAYER_LANES: Array[float] = [160.0,218.0,276.0,334.0]
const OPPONENT_LANES: Array[float] = [462.0,520.0,578.0,636.0]
const HIT_X: float = 478.0
const SPAWN_X: float = 1230.0
const HERO_HEIGHT: float = 196.0
const BOSS_HEIGHT: float = 254.8
const HERO_FEET := Vector2(162,346)
const BOSS_FEET := Vector2(162,672)

static func box(fill: Color, border: Color, width: int = 2) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color=fill
    style.border_color=border
    style.set_border_width_all(width)
    style.set_corner_radius_all(0)
    style.shadow_color=INK
    style.shadow_size=0
    style.shadow_offset=Vector2(4,4)
    return style

static func style_button(button: Button) -> void:
    button.add_theme_font_override("font",FONT)
    button.add_theme_font_size_override("font_size",20)
    button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    for state in ["normal","hover","pressed","focus"]:
        button.add_theme_stylebox_override(state,box(Color("#33263e") if state=="normal" else Color("#57415b"),GOLD if state in ["hover","focus"] else MUTED))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        button.add_theme_color_override(state,CREAM)

static func fit_sprite(actor: SpritePlayer, height: float, feet: Vector2) -> Dictionary:
    # Measure the visible idle drawing once, keeping all original pose anchors.
    actor._show_frame("idle",0)
    var atlas: AtlasTexture = actor.sprite.texture as AtlasTexture
    var sheet: Image = atlas.atlas.get_image()
    if sheet.is_compressed():
        sheet.decompress()
    sheet.convert(Image.FORMAT_RGBA8)
    var data: PackedByteArray = sheet.get_data()
    var region := Rect2i(atlas.region)
    var top: int = region.size.y
    var bottom: int = -1
    for y in range(region.size.y):
        for x in range(region.size.x):
            var k: int = ((region.position.y+y)*sheet.get_width()+region.position.x+x)*4
            if data[k+3]>=128:
                top=mini(top,y)
                bottom=maxi(bottom,y)
    if bottom<top:
        return {}
    var visible_height: float = float(bottom-top+1)
    var image_scale: float = actor.sprite.scale.y
    var scale_value: float = height/(visible_height*image_scale)
    actor.scale=Vector2.ONE*scale_value
    var anchor: Vector2 = actor.animations["idle"]["anchors"][0]
    var native_y: float = -anchor.y*image_scale
    actor.visual.position.y=SpritePlayer.FOOT_Y-float(bottom+1)*image_scale-native_y
    actor.position=feet-Vector2(0,SpritePlayer.FOOT_Y*scale_value)
    return {"source_visible_height":visible_height,"height":height,"feet":feet,"scale":scale_value}

static func steps(rect: Rect2) -> PackedVector2Array:
    var x: float = rect.position.x
    var y: float = rect.position.y
    var r: float = rect.end.x
    var b: float = rect.end.y
    return PackedVector2Array([Vector2(x+6,y),Vector2(r-6,y),Vector2(r-6,y+2),Vector2(r-2,y+2),Vector2(r-2,y+6),Vector2(r,y+6),Vector2(r,b-6),Vector2(r-2,b-6),Vector2(r-2,b-2),Vector2(r-6,b-2),Vector2(r-6,b),Vector2(x+6,b),Vector2(x+6,b-2),Vector2(x+2,b-2),Vector2(x+2,b-6),Vector2(x,b-6),Vector2(x,y+6),Vector2(x+2,y+6),Vector2(x+2,y+2),Vector2(x+6,y+2)])

static func draw_panel(canvas: CanvasItem, rect: Rect2, fill: Color, edge: Color, line: float = 2.0, shadow: bool = true) -> void:
    if shadow:
        canvas.draw_colored_polygon(steps(Rect2(rect.position+Vector2(4,4),rect.size)),INK)
    var points: PackedVector2Array = steps(rect)
    canvas.draw_colored_polygon(points,fill)
    points.append(points[0])
    canvas.draw_polyline(points,edge,line,false)

static func draw_arrow(canvas: CanvasItem, center: Vector2, lane: int, size: float, color: Color) -> void:
    var points: PackedVector2Array = Lanes.arrow_points(lane,center,size)
    for i in range(points.size()):
        points[i]=(points[i]/2.0).round()*2.0
    canvas.draw_colored_polygon(points,color)
    points.append(points[0])
    canvas.draw_polyline(points,Color(INK,color.a),4 if size>=16 else 2,false)

static func draw_fire(canvas: CanvasItem, center: Vector2, lane: int = -1, alpha: float = 1.0, size: float = 1.0) -> void:
    var points := PackedVector2Array([Vector2(0,-25),Vector2(6,-10),Vector2(12,-17),Vector2(18,-3),Vector2(18,8),Vector2(11,20),Vector2(0,25),Vector2(-11,20),Vector2(-18,10),Vector2(-17,-1),Vector2(-9,-12),Vector2(-9,1),Vector2(-2,-7)])
    for i in range(points.size()):
        points[i]=((center+points[i]*size)/2).round()*2
    canvas.draw_colored_polygon(points,Color(Color("#ff7857"),alpha))
    points.append(points[0])
    canvas.draw_polyline(points,Color(INK,alpha),4 if size>=1 else 2,false)
    if lane>=0:
        draw_arrow(canvas,center+Vector2(0,7)*size,lane,10*size,Color(CREAM,alpha))
    for offset in [Vector2(-10,-28),Vector2(8,-34),Vector2(18,-24)]:
        canvas.draw_rect(Rect2((center+offset*size).round(),Vector2.ONE*maxf(2,4*size)),Color(GOLD,alpha))
