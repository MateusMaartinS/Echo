extends Node2D
class_name SeasonStageScenery

# Continuous 1280 px landscape below the HUD. Small particles stay at the cast.
var season: String = "winter"
var boss_title: String = "BÓREAS"
var motion_time: float = 0.0
var music_beat: float = 0.0

func _process(delta: float) -> void:
    if not Conductor.is_playing():
        return
    motion_time+=delta
    music_beat=Conductor.get_current_beat()
    queue_redraw()

func _draw() -> void:
    match season:
        "tutorial":
            _tutorial()
        "winter":
            _winter()
        "autumn":
            _autumn()
        "spring":
            _spring()
    _names()

func _box(x: float, y: float, width: float, height: float, color: String) -> void:
    draw_rect(Rect2(x,y,width,height),Color(color))

func _polygon(points: Array, color: String) -> void:
    draw_colored_polygon(PackedVector2Array(points),Color(color))

func _strong_beat() -> float:
    return maxf(0.0,1.0-fposmod(music_beat,4.0)*2.0)

func _crown(at: Vector2, width: float, height: float, color: String) -> void:
    _box(at.x-width*.5+8,at.y-height*.5,width-16,height,color)
    _box(at.x-width*.5,at.y-height*.5+8,width,height-16,color)
    _box(at.x-width*.5+18,at.y-height*.5-6,width-36,height+12,color)

func _platform(top: float, surface: String, front: String, edge: String) -> void:
    _polygon([Vector2(16,top+4),Vector2(30,top-2),Vector2(292,top-2),Vector2(306,top+4),Vector2(292,top+12),Vector2(30,top+12)],front)
    _box(22,top-2,280,4,surface)
    _box(28,top+4,268,2,edge)

func _tutorial() -> void:
    # A quiet rehearsal room keeps the mentor clear and the note fields legible.
    _box(0,0,1280,720,"#272438")
    _box(0,196,1280,364,"#34354d")
    _box(0,560,1280,160,"#3c3547")
    for x in range(0,1280,64):
        _box(x,196,2,364,"#3d3b54")
    for y in [260,390,518]:
        _box(0,y,1280,2,"#48465c")
    # Pixel sound panels and small beat lights stay at the outer edges.
    for x in [12,280]:
        _box(x,104,26,160,"#1b1b2b")
        _box(x+4,110,18,148,"#4b405d")
        for i in range(6):
            var height: float = 8+float((i*7+int(music_beat))%4)*6
            _box(x+6+i*3,188-height,2,height,"#8d78a3")
    _box(0,554,1280,6,"#756782")
    _box(0,612,1280,4,"#584c62")
    _box(0,674,1280,46,"#332d3d")
    for x in range(0,1280,96):
        _box(x,680,48,2,"#55485e")
    _platform(346,"#b8a2c4","#51435f","#82718f")
    _platform(672,"#b8a2c4","#51435f","#82718f")
    _box(32,328,8,14,"#9c8aaf")
    _box(284,328,8,14,"#9c8aaf")
    _box(32,654,8,14,"#9c8aaf")
    _box(284,654,8,14,"#9c8aaf")

func _winter() -> void:
    _box(0,0,1280,720,"#142438")
    _box(0,216,1280,188,"#1b3048")
    _box(0,404,1280,152,"#254259")
    # Low-contrast pixel ribbons: a slow aurora above the silhouettes.
    _aurora(134,Color("#62c8b5"),0.0)
    _aurora(168,Color("#8886be"),1.8)
    _aurora(190,Color("#58bacb"),3.0)
    _polygon([Vector2(-14,426),Vector2(46,258),Vector2(110,394),Vector2(166,280),Vector2(246,424),Vector2(286,310),Vector2(340,422),Vector2(422,298),Vector2(504,430),Vector2(574,266),Vector2(662,432),Vector2(744,310),Vector2(824,434),Vector2(902,286),Vector2(1006,426),Vector2(1102,274),Vector2(1204,426),Vector2(1296,316),Vector2(1296,576),Vector2(-14,576)],"#344f68")
    _polygon([Vector2(20,324),Vector2(46,258),Vector2(78,326),Vector2(54,312),Vector2(42,318)],"#698698")
    _polygon([Vector2(138,340),Vector2(166,280),Vector2(200,342),Vector2(176,330),Vector2(162,338)],"#718c9b")
    _polygon([Vector2(0,526),Vector2(62,452),Vector2(120,514),Vector2(206,440),Vector2(322,528),Vector2(414,456),Vector2(510,520),Vector2(626,444),Vector2(748,530),Vector2(870,464),Vector2(984,522),Vector2(1114,448),Vector2(1296,526),Vector2(1296,576),Vector2(0,576)],"#426175")
    # The lower stage stands on the lake; the upper stage is a raised ice shelf.
    _box(0,550,1280,170,"#608a9c")
    _box(0,550,1280,6,"#a0c7d2")
    _box(0,622,1280,98,"#7597a4")
    for y in [574,606,642,714]:
        _box(2,y,48,2,"#9ec0ca")
        _box(264,y+8,42,2,"#a7cbd1")
        for x in range(396,1280,188):
            _box(x,y+4,58,2,"#8db4c1")
    _polygon([Vector2(34,684),Vector2(58,674),Vector2(264,674),Vector2(290,684),Vector2(262,692),Vector2(60,692)],"#4d7589")
    _platform(346,"#c5e4e8","#527a91","#82b7c7")
    _polygon([Vector2(26,358),Vector2(42,358),Vector2(34,374)],"#8db9c9")
    _polygon([Vector2(276,358),Vector2(292,358),Vector2(286,370)],"#8db9c9")
    _platform(672,"#cae8e8","#4a7188","#8dbfcf")
    _crystal(Vector2(14,658),18,44)
    _crystal(Vector2(305,654),18,52)
    _crystal(Vector2(9,328),12,26)
    _crystal(Vector2(308,326),12,30)
    # Sparse flakes stay near the edges, far from both note fields.
    for i in range(15):
        var edge_x: float = 6+fposmod(float(i*19),36) if i%2==0 else 278+fposmod(float(i*13),36)
        var x: float = edge_x+round(sin(motion_time*.35+float(i))*3)*2
        var y: float = 102+fposmod(float(i*47)+motion_time*10,568)
        draw_rect(Rect2(Vector2(x,round(y/2)*2),Vector2(2,2)),Color("#b4d9df"))
        if i%5==0:
            draw_rect(Rect2(x-2,round(y/2)*2+2,6,2),Color("#7fb2c5"))

func _aurora(base_y: float, color: Color, phase: float) -> void:
    var ribbon := PackedVector2Array()
    for x in range(-12,1297,12):
        var y: float = base_y+sin(float(x)*.018+motion_time*.12+phase)*18
        ribbon.append(Vector2(x,round(y/4)*4))
    for x in range(1296,-13,-12):
        var y: float = base_y+sin(float(x)*.018+motion_time*.12+phase)*18+18
        ribbon.append(Vector2(x,round(y/4)*4))
    draw_colored_polygon(ribbon,Color(color,.18))

func _crystal(base: Vector2, width: float, height: float) -> void:
    var pulse: float = _strong_beat()
    var color: Color = Color("#609cac").lerp(Color("#b5e3e6"),pulse*.35)
    var points := PackedVector2Array([base+Vector2(-width*.5,-height*.25),base+Vector2(-width*.4,-height*.7),base+Vector2(0,-height),base+Vector2(width*.5,-height*.6),base+Vector2(width*.5,0),base])
    draw_colored_polygon(points,color)
    _polygon([base,base+Vector2(0,-height),base+Vector2(width*.5,-height*.6),base+Vector2(width*.5,0)],"#42778f")
    draw_line(base+Vector2(0,-height),base,Color("#a5dee3"),2,false)

func _autumn() -> void:
    _box(0,0,1280,720,"#40303b")
    _box(0,264,1280,230,"#544048")
    _box(0,494,1280,226,"#6c4f4b")
    # Copper and burgundy woodland, kept to the sides of the performers.
    for x in [-12,32,278,316]:
        _box(x,132,12,450,"#392c38")
        _box(x+10,210,4,352,"#6a4546")
    _crown(Vector2(14,156),120,94,"#673d47")
    _crown(Vector2(24,126),102,60,"#895044")
    _crown(Vector2(302,162),110,100,"#714043")
    _crown(Vector2(308,126),90,56,"#9b5b42")
    _crown(Vector2(-6,442),100,112,"#784447")
    _crown(Vector2(326,434),94,104,"#875144")
    for x in range(426,1380,184):
        _box(x,134,10,428,"#392c38")
        _box(x+10,218,4,344,"#6a4546")
        _crown(Vector2(x+6,148),142,94,"#673d47")
        _crown(Vector2(x+18,112),122,60,"#895044")
        _crown(Vector2(x-10,428),116,90,"#784447")
    # Stone amphitheatre terraces behind the wooden stage.
    for terrace in range(4):
        var y: float = 570+terrace*28
        _box(8-terrace*6,y,1280+terrace*12,18,"#705651")
        _box(8-terrace*6,y,1280+terrace*12,3,"#987563")
        _box(22+terrace*4,y+8,36,2,"#594349")
        _box(270-terrace*4,y+8,30,2,"#594349")
    for x in [6,296]:
        _box(x,482,18,126,"#665053")
        _box(x-4,476,26,8,"#8c6a5e")
        _box(x+5,488,3,112,"#9a7764")
        _box(x-3,604,24,6,"#493942")
    _box(0,690,1280,30,"#b18b69")
    for i in range(104):
        var x: float = fposmod(float(i*53),1280)
        var y: float = 694+fposmod(float(i*7),24)
        if x>=328 and x<1260:
            continue # Quiet foreground behind the footer legend and progress.
        _box(x,y,6 if i%2 else 8,2,"#b8794b" if i%3 else "#8b4c4a")
    _wood_stage(346)
    _wood_stage(672)
    _lantern(Vector2(18,278))
    _lantern(Vector2(302,278))
    _lantern(Vector2(12,566))
    _lantern(Vector2(308,566))
    for i in range(8):
        var x: float = 12+fposmod(float(i*41)+motion_time*9,34) if i%2==0 else 276+fposmod(float(i*19)+motion_time*7,36)
        var y: float = 106+fposmod(float(i*79)+motion_time*15,550)
        _leaf(Vector2(round(x/2)*2,round(y/2)*2),Color("#bf7d4e") if i%2 else Color("#9c4e53"))
    # Short wind strokes at the edges; no streaks across the HUD.
    for edge in [0,278]:
        var y: float = 414+round(sin(motion_time*.6+float(edge))*3)*2
        _box(edge,y,28,2,"#99705c")
        _box(edge+18,y+4,18,2,"#99705c")

func _wood_stage(top: float) -> void:
    _platform(top,"#bf9165","#60434a","#9e7254")
    for x in range(46,290,34):
        _box(x,top+2,2,8,"#42303b")
    _box(28,top+12,8,10,"#42303b")
    _box(286,top+12,8,10,"#42303b")

func _lantern(base: Vector2) -> void:
    var glow: float = .10+_strong_beat()*.05
    draw_rect(Rect2(base-Vector2(16,36),Vector2(32,32)),Color(1,.65,.28,glow))
    _box(base.x-2,base.y-14,4,32,"#3e303b")
    _box(base.x-7,base.y-32,14,20,"#49313a")
    _box(base.x-4,base.y-28,8,12,"#d8a363")
    _box(base.x-8,base.y-34,16,3,"#b17b50")
    _box(base.x-1,base.y-28,2,12,"#8f5c48")

func _leaf(center: Vector2, color: Color) -> void:
    var points := PackedVector2Array([center+Vector2(-4,-2),center+Vector2(0,-6),center+Vector2(6,-2),center+Vector2(2,4),center+Vector2(-4,4)])
    draw_colored_polygon(points,color)
    draw_line(center+Vector2(-2,4),center+Vector2(2,-2),Color("#59414b"),2,false)

func _spring() -> void:
    _box(0,0,1280,720,"#bfd8d2")
    _box(0,298,1280,222,"#acc9bb")
    _box(0,520,1280,200,"#94b29c")
    # Distant blossom trees frame the sky instead of filling the silhouettes.
    for x in [12,296]:
        _box(x,174,10,370,"#839b86")
        _box(x-6,210,6,34,"#839b86")
    _crown(Vector2(2,164),98,86,"#c79ab1")
    _crown(Vector2(10,140),104,54,"#e5bbc8")
    _crown(Vector2(312,164),98,82,"#c4a9c6")
    _crown(Vector2(310,138),102,54,"#dfc1d2")
    for x in [448,692,966,1244]:
        _box(x,166,8,378,"#839b86")
        _crown(Vector2(x+2,152),132,82,"#c4a9c6")
        _crown(Vector2(x-4,126),126,54,"#e5bbc8")
    # Gazebo with a quiet sage roof, pillars, and climbing vines at its edges.
    _polygon([Vector2(4,488),Vector2(44,460),Vector2(128,426),Vector2(198,426),Vector2(282,460),Vector2(318,488)],"#7a9d8b")
    _polygon([Vector2(40,478),Vector2(128,438),Vector2(198,438),Vector2(282,478)],"#a4bfa4")
    _box(8,486,306,8,"#d4d7b5")
    for x in [22,292]:
        _box(x,494,8,180,"#c8cdb0")
        _box(x-3,492,14,6,"#718f81")
        _box(x-4,666,16,6,"#718f81")
        for j in range(10):
            var vine_x: float = x+round(sin(float(j)*1.7)*2)*2
            var vine_y: float = 480+float(j)*18
            _box(vine_x,vine_y,2,20,"#688e75")
            _polygon([Vector2(vine_x,vine_y),Vector2(vine_x-6,vine_y-2),Vector2(vine_x-8,vine_y+4),Vector2(vine_x-2,vine_y+6)],"#83a27f")
    # Layered beds remain behind the stage and along the bottom edge.
    for bed in range(3):
        var y: float = 546+bed*54
        _box(0,y,1280,10,"#a5bb91")
        _box(0,y+10,1280,24,"#829e83")
        for side in [18,296]:
            _flower(Vector2(side,y+6),bed+side)
            _flower(Vector2(side-12,y+14),bed+side+2)
    _platform(346,"#d9d7b7","#7f9683","#a9ba9e")
    _box(28,358,6,12,"#9fb19a")
    _box(290,358,6,12,"#9fb19a")
    _platform(672,"#e2d9ba","#82947d","#bdc9a4")
    _box(0,710,1280,10,"#8da78b")
    for i in range(10):
        var x: float = 8+fposmod(float(i*29)+motion_time*6,38) if i%2==0 else 278+fposmod(float(i*17)+motion_time*5,32)
        var y: float = 116+fposmod(float(i*59)+motion_time*8,542)
        _box(round(x/2)*2,round(y/2)*2,4,2,"#edc2d4" if i%3 else "#d6b8db")
    _butterfly(Vector2(36+round(sin(motion_time*.4)*4)*2,232+round(sin(motion_time*.6)*3)*2),0)
    _butterfly(Vector2(280+round(sin(motion_time*.3+2)*3)*2,446+round(sin(motion_time*.5)*3)*2),1)

func _flower(base: Vector2, seed_value: int) -> void:
    var center := base+Vector2(round(sin(motion_time*.9+float(seed_value)))*2,0)
    var color: Color = Color("#dbabbd") if seed_value%2 else Color("#c4acd1")
    draw_rect(Rect2(base+Vector2(0,2),Vector2(2,8)),Color("#6e8e76"))
    for offset in [Vector2(-4,0),Vector2(4,0),Vector2(0,-4),Vector2(0,4)]:
        draw_rect(Rect2(center+offset-Vector2(2,2),Vector2(4,4)),color)
    draw_rect(Rect2(center-Vector2(2,2),Vector2(4,4)),Color("#e7d5a0"))

func _butterfly(center: Vector2, phase: int) -> void:
    var wing: float = 2.0 if int(motion_time*3+phase)%2 else 4.0
    draw_rect(Rect2(center-Vector2(wing+1,2),Vector2(wing,4)),Color("#b9a1c6"))
    draw_rect(Rect2(center+Vector2(1,-2),Vector2(wing,4)),Color("#d2aac0"))
    draw_rect(Rect2(center-Vector2(1,2),Vector2(2,6)),Color("#6c8879"))

func _names() -> void:
    for y in [364,686]:
        draw_rect(Rect2(52,y,220,24),Color(.07,.10,.16,.72))
    draw_string(BattleHudStyle.FONT,Vector2(30,382),"VOCÊ",HORIZONTAL_ALIGNMENT_CENTER,264,20,BattleHudStyle.CREAM)
    draw_string(BattleHudStyle.FONT,Vector2(30,704),boss_title,HORIZONTAL_ALIGNMENT_CENTER,264,20,BattleHudStyle.GOLD)
