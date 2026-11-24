extends Control
class_name SeasonCardVista

# Pixel postcards using the same palettes and landmarks as the battle arenas.
var season: String = "tutorial"
var clock: float = 0.0
var animated: bool = false

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    clip_contents=true
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
    if animated:
        clock+=delta
        queue_redraw()

func _box(x: float, y: float, w: float, h: float, color: String) -> void:
    draw_rect(Rect2(round(x),round(y),round(w),round(h)),Color(color))

func _poly(points: Array, color: String) -> void:
    var pixels := PackedVector2Array()
    for point in points:
        pixels.append(Vector2(round(point.x),round(point.y)))
    draw_colored_polygon(pixels,Color(color))

func _tree(x: float, y: float, color: String, blossom: String) -> void:
    _box(x-2,y-98,4,98,color)
    _box(x-18,y-104,36,42,blossom)
    _box(x-26,y-94,52,22,blossom)
    _box(x-10,y-110,20,54,blossom)

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    match season:
        "winter":
            _box(0,0,w,h,"#142438")
            for ribbon in range(2):
                for x in range(0,int(w)+8,8):
                    var y: float = 24+ribbon*17+round(sin(float(x)*.03+clock*.15+ribbon)*6)*2
                    _box(x,y,8,8,"#34586a" if ribbon==0 else "#41435f")
            _poly([Vector2(0,h*.74),Vector2(w*.24,h*.30),Vector2(w*.52,h*.72),Vector2(w*.80,h*.38),Vector2(w,h*.70),Vector2(w,h),Vector2(0,h)],"#426175")
            _poly([Vector2(w*.14,h*.48),Vector2(w*.24,h*.30),Vector2(w*.36,h*.49),Vector2(w*.24,h*.45)],"#93bac9")
            _box(0,h-26,w,26,"#7597a4")
            _box(0,h-26,w,3,"#b4d8df")
            _poly([Vector2(8,h-10),Vector2(6,h-42),Vector2(14,h-52),Vector2(22,h-32),Vector2(22,h-10)],"#75c0cf")
        "summer":
            _box(0,0,w,h,"#654153")
            _box(0,h*.36,w,h*.42,"#aa736f")
            _box(w*.72,26,28,36,"#edb989")
            _box(w*.72-4,34,36,20,"#edb989")
            _box(0,h*.66,w,h*.34,"#657987")
            _poly([Vector2(0,h-18),Vector2(w*.45,h-32),Vector2(w,h-24),Vector2(w,h),Vector2(0,h)],"#d0ac87")
            _box(24,h-120,4,96,"#514e54")
            _box(6,h-124,44,4,"#6c866e")
            _box(14,h-132,30,4,"#6c866e")
            _box(24,h-142,4,18,"#6c866e")
        "autumn":
            _box(0,0,w,h,"#40303b")
            _box(0,h*.5,w,h*.5,"#6c4f4b")
            _tree(14,h-30,"#392c38","#895044")
            _tree(w-12,h-36,"#392c38","#714043")
            for terrace in range(3):
                _box(0,h-26+terrace*8,w,6,"#987563" if terrace%2==0 else "#705651")
            for x in [8,w-14]:
                _box(x,h-72,6,42,"#49313a")
                _box(x-2,h-76,10,12,"#d8a363")
        "spring":
            _box(0,0,w,h,"#bfd8d2")
            _box(0,h*.66,w,h*.34,"#94b29c")
            _tree(10,h-32,"#839b86","#e5bbc8")
            _tree(w-8,h-34,"#839b86","#c4a9c6")
            _poly([Vector2(26,h-68),Vector2(w*.4,h-110),Vector2(w*.62,h-110),Vector2(w-24,h-68)],"#7a9d8b")
            _box(26,h-68,w-50,5,"#d4d7b5")
            _box(30,h-63,5,48,"#c8cdb0")
            _box(w-34,h-63,5,48,"#c8cdb0")
            _box(0,h-18,w,18,"#a5bb91")
        _:
            _box(0,0,w,h,"#354f50")
            _poly([Vector2(0,h*.70),Vector2(w*.24,h*.46),Vector2(w*.56,h*.66),Vector2(w,h*.50),Vector2(w,h),Vector2(0,h)],"#668474")
            _poly([Vector2(0,h*.86),Vector2(w*.4,h*.72),Vector2(w,h*.82),Vector2(w,h),Vector2(0,h)],"#89a486")
            _poly([Vector2(w*.36,h),Vector2(w*.48,h*.74),Vector2(w*.54,h*.74),Vector2(w*.66,h)],"#c2b18d")
    # Quiet particles along the postcard edges, below its portrait and badges.
    if season in ["winter","spring","autumn"]:
        for i in range(6):
            var x: float = 6+fposmod(float(i*17),22) if i%2==0 else w-26+fposmod(float(i*11),20)
            var y: float = 48+fposmod(float(i*31)+clock*5,h-60)
            _box(x,y,2,2,"#b4d9df" if season=="winter" else "#edc2d4" if season=="spring" else "#bf7d4e")
