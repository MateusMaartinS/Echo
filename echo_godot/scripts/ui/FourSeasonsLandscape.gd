extends Control
class_name FourSeasonsLandscape

# A single world seen in four seasons. Geometry stays aligned while palette
# transitions mix in 8 px steps, rather than ending at four hard vertical cuts.
const SEASONS := ["spring","summer","autumn","winter"]
const NAMES := ["PRIMAVERA","VERÃO","OUTONO","INVERNO"]
const PALETTES := [
    ["#729799","#597582","#688b7b","#79967c","#7ba2a5","#8ca587","#b7b492","#cea2b5","#5d635c"],
    ["#927981","#87716e","#8e8b6c","#92946e","#7d9b9d","#aca079","#cab18d","#738b67","#6c6259"],
    ["#76525f","#745665","#82675f","#8c735f","#849391","#9d8067","#bca188","#a67352","#645052"],
    ["#334c64","#49627a","#658294","#91a5b0","#8daeba","#a4bbc3","#b9c7c9","#d8e7df00","#687b85"]
]
var pieces: Array[Dictionary] = []
var spans: Array[Dictionary] = []

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    _build_geometry()
    _build_spans()
    var ambient := Ambient.new()
    ambient.size=Vector2(1280,720)
    ambient.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(ambient)
    queue_redraw()

func _palette(index: int) -> Array[Color]:
    var colors: Array[Color] = []
    for hex in PALETTES[index]:
        colors.append(Color(hex))
    return colors

func _build_spans() -> void:
    for i in range(4):
        var left: float = 0.0 if i==0 else i*320.0+32.0
        var right: float = 1280.0 if i==3 else (i+1)*320.0-32.0
        spans.append({"left":left,"right":right,"palette":_palette(i)})
        if i==3:
            continue
        var current: Array[Color] = _palette(i)
        var next: Array[Color] = _palette(i+1)
        for step in range(8):
            var colors: Array[Color] = []
            for slot in range(current.size()):
                colors.append(current[slot].lerp(next[slot],(float(step)+.5)/8.0))
            left=(i+1)*320.0-32+step*8
            spans.append({"left":left,"right":left+8,"palette":colors})

func _piece(points: Array, slot: int) -> void:
    # Clip convex triangles so a narrow seasonal span cannot split a concave
    # river/path into a self-touching polygon.
    var polygon := PackedVector2Array(points)
    var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
    for i in range(0,triangles.size(),3):
        pieces.append({"points":PackedVector2Array([polygon[triangles[i]],polygon[triangles[i+1]],polygon[triangles[i+2]]]),"slot":slot})

func _rect(rect: Rect2, slot: int) -> void:
    _piece([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)],slot)

func _stroke(a: Vector2, b: Vector2, width: float, slot: int) -> void:
    var side: Vector2 = (b-a).orthogonal().normalized()*width*.5
    _piece([(a-side).snapped(Vector2(2,2)),(b-side).snapped(Vector2(2,2)),(b+side).snapped(Vector2(2,2)),(a+side).snapped(Vector2(2,2))],slot)

func _build_geometry() -> void:
    _piece([Vector2(0,312),Vector2(174,246),Vector2(302,282),Vector2(478,214),Vector2(638,274),Vector2(806,232),Vector2(1038,292),Vector2(1162,226),Vector2(1280,280),Vector2(1280,550),Vector2(0,550)],1)
    _piece([Vector2(0,374),Vector2(182,330),Vector2(398,360),Vector2(576,310),Vector2(746,346),Vector2(948,328),Vector2(1150,372),Vector2(1280,336),Vector2(1280,560),Vector2(0,560)],2)
    _piece([Vector2(0,434),Vector2(190,404),Vector2(396,424),Vector2(622,394),Vector2(820,426),Vector2(1088,410),Vector2(1280,434),Vector2(1280,600),Vector2(0,600)],3)
    _piece([Vector2(0,476),Vector2(200,458),Vector2(424,476),Vector2(658,448),Vector2(870,474),Vector2(1096,456),Vector2(1280,472),Vector2(1280,558),Vector2(1060,536),Vector2(820,554),Vector2(602,532),Vector2(360,550),Vector2(170,530),Vector2(0,548)],4)
    _piece([Vector2(0,558),Vector2(168,538),Vector2(366,562),Vector2(604,542),Vector2(826,566),Vector2(1054,542),Vector2(1280,562),Vector2(1280,720),Vector2(0,720)],5)
    _piece([Vector2(520,720),Vector2(592,616),Vector2(656,570),Vector2(706,554),Vector2(710,556),Vector2(674,588),Vector2(646,628),Vector2(722,720)],6)
    for y in [574,590]:
        _rect(Rect2(0,y,1280,2),8)
    for x in range(0,1281,50):
        _rect(Rect2(x,560,4,48),8)
    for base in [Vector2(320,578),Vector2(960,578)]:
        for offset in [Vector2(-106,-230),Vector2(-64,-276),Vector2(0,-300),Vector2(64,-276),Vector2(106,-230),Vector2(-42,-218),Vector2(42,-218)]:
            var at: Vector2 = base+offset
            _rect(Rect2(at-Vector2(42,38),Vector2(84,76)),7)
            _rect(Rect2(at-Vector2(50,24),Vector2(100,48)),7)
        var branches: Array = [
            [Vector2(0,0),Vector2(-8,-104),Vector2(4,-198),Vector2(-4,-316)],
            [Vector2(-4,-118),Vector2(-64,-176),Vector2(-98,-252)],
            [Vector2(-2,-184),Vector2(60,-244),Vector2(92,-302)],
            [Vector2(-4,-220),Vector2(-48,-272),Vector2(-56,-328)],
            [Vector2(-36,-148),Vector2(-118,-194),Vector2(-144,-238)],
            [Vector2(0,-144),Vector2(80,-182),Vector2(122,-232)]
        ]
        for branch in branches:
            for i in range(branch.size()-1):
                _stroke(base+branch[i],base+branch[i+1],6 if branch==branches[0] else 3,8)

func _clip(points: PackedVector2Array, boundary: float, left_edge: bool) -> PackedVector2Array:
    var result := PackedVector2Array()
    if points.is_empty():
        return result
    var previous: Vector2 = points[-1]
    var previous_inside: bool = previous.x>=boundary if left_edge else previous.x<=boundary
    for point in points:
        var inside: bool = point.x>=boundary if left_edge else point.x<=boundary
        if inside!=previous_inside:
            var ratio: float = (boundary-previous.x)/(point.x-previous.x)
            result.append(Vector2(boundary,lerpf(previous.y,point.y,ratio)))
        if inside:
            result.append(point)
        previous=point
        previous_inside=inside
    var unique := PackedVector2Array()
    for point in result:
        if unique.is_empty() or not unique[-1].is_equal_approx(point):
            unique.append(point)
    if unique.size()>1 and unique[0].is_equal_approx(unique[-1]):
        unique.remove_at(unique.size()-1)
    return unique

func _draw() -> void:
    for span in spans:
        var left: float = span["left"]
        var right: float = span["right"]
        var palette: Array = span["palette"]
        draw_rect(Rect2(left,0,right-left,720),palette[0])
        for piece in pieces:
            var points: PackedVector2Array = _clip(_clip(piece["points"],left,true),right,false)
            var color: Color = palette[int(piece["slot"])]
            var area: float = 0.0
            for i in range(points.size()):
                area+=points[i].cross(points[(i+1)%points.size()])
            if points.size()>=3 and absf(area)>.5 and color.a>0:
                draw_colored_polygon(points,color)

class Ambient extends Control:
    var clock: float = 0.0

    func _process(delta: float) -> void:
        clock+=delta
        queue_redraw()

    func _draw() -> void:
        for i in range(24):
            var x: float = fposmod(float(i*137)+sin(clock*.18+i)*8,1280)
            var y: float = fposmod(float(i*79)+clock*5,640)
            # Keep the center quiet for the logo and menu.
            if x>446 and x<834:
                continue
            var color := Color("#e6bed0") if x<320 else Color("#c69366") if x>640 and x<960 else Color("#b8d6df") if x>=960 else Color("#d9c599")
            draw_rect(Rect2(round(x/2)*2,round(y/2)*2,2,2),Color(color,.45))
