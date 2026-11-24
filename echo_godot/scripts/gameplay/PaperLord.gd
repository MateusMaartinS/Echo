extends PaperMusician
class_name PaperLord

# Same animated paper skeleton as the player; each season adds its own clothes.
@export_enum("spring", "summer", "autumn", "winter", "tutorial") var season: String = "summer"

const WINTER_IDLE := [Vector2(-2,-62), Vector2(0,-29), Vector2(0,21), Vector2(-28,4), Vector2(-11,13), Vector2(32,0), Vector2(29,-34), Vector2(-15,55), Vector2(-22,88), Vector2(17,55), Vector2(26,88)]
const WINTER_POSES := [
    [Vector2(-3,-65), Vector2(0,-31), Vector2(0,20), Vector2(-25,4), Vector2(-13,12), Vector2(39,-62), Vector2(42,-101), Vector2(-10,50), Vector2(-15,83), Vector2(12,50), Vector2(18,83)],
    [Vector2(20,-54), Vector2(7,-22), Vector2(-6,23), Vector2(-32,-17), Vector2(-62,1), Vector2(41,-7), Vector2(43,-30), Vector2(-27,54), Vector2(-44,88), Vector2(31,54), Vector2(46,88)],
    [Vector2(-23,-55), Vector2(-9,-24), Vector2(8,22), Vector2(-36,-34), Vector2(-61,-35), Vector2(24,7), Vector2(10,-25), Vector2(-27,56), Vector2(-45,88), Vector2(28,52), Vector2(43,88)],
    [Vector2(0,-7), Vector2(-5,23), Vector2(2,57), Vector2(-30,45), Vector2(-11,62), Vector2(28,42), Vector2(26,11), Vector2(-26,70), Vector2(-30,88), Vector2(28,68), Vector2(34,88)],
]
var winter_sway: float = 0.0

func _idle_joints() -> Array:
    return WINTER_IDLE if season == "winter" else IDLE

func _pose_joints(lane: int) -> Array:
    return WINTER_POSES[lane] if season == "winter" else POSES[lane]

func _process(delta: float) -> void:
    super._process(delta)
    if season == "winter" and not frozen:
        var target: float = (joints[1] as Vector2).x * -0.55 + sin(rhythm_beat * TAU) * 2.0
        winter_sway = lerpf(winter_sway, target, 1.0 - exp(-delta * 9.0))

func _draw() -> void:
    if season == "winter":
        _draw_winter_singer()
        return
    var bob: float = sin(rhythm_beat * TAU) * 1.5 if preview_pose == -2 and pose_remaining <= 0.0 else 0.0
    draw_set_transform(Vector2(0, bob))
    var head: Vector2 = joints[0]
    var shoulder: Vector2 = joints[1]
    var hip: Vector2 = joints[2]
    var down: Vector2 = (hip - shoulder).normalized()
    var right := Vector2(down.y, -down.x)
    if season in ["spring", "winter"]:
        _hair(head, down, right)
    if season == "summer":
        _surfboard(joints[6])
    for side in [0, 1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        _stroke([shoulder + right * sign_x * 16.0, joints[3 + side * 2], joints[4 + side * 2]], 3.5)
        _stroke([hip + right * sign_x * 9.0, joints[7 + side * 2], joints[8 + side * 2]], 3.7)
    _stroke([head + down * 21.0, shoulder + down * 5.0], 3.0)
    match season:
        "spring":
            _dress(shoulder, hip, down, right, Color("#f1c7ce"), true)
        "summer":
            _trousers(hip, right, Color("#59aeb1"), 0.78, false)
            _top(shoulder, hip, down, right, Color("#ffe5ab"), false)
            _stroke([shoulder + right * 11.0, hip + right * 12.0], 1.0, Color("#d9a456"))
            _stroke([hip - right * 4.0, hip + down * 9.0, hip + right * 4.0], 1.2)
        "autumn":
            _trousers(hip, right, Color("#83705b"), 1.0, false)
            _top(shoulder, hip, down, right, Color("#c58b54"), true)
            _cardigan(shoulder, hip, down, right)
            _scarf(shoulder, down, right, Color("#b6573e"))
        _:
            _trousers(hip, right, Color("#7e9160"), 0.85, false)
            _top(shoulder, hip, down, right, WHITE, false)
            _scarf(shoulder, down, right, Color("#d2b77c"))
    _face(head)
    if season == "spring":
        _flower(head + Vector2(-17,-18), 5.5, Color("#cb7795"))
        _flower(head + Vector2(-7,-24), 4.2, Color("#e2a1ad"))
    elif season == "summer":
        _stroke([head + Vector2(-22,-3), head + Vector2(23,-3)], 1.6, Color("#b6573e"))
        draw_arc(head, 23.0, PI + 0.1, TAU - 0.1, 24, Color("#d9a456"), 3.5, true)
    for side in [0, 1]:
        var foot: Vector2 = joints[8 + side * 2]
        var facing: float = -1.0 if side == 0 else 1.0
        if season == "summer":
            _sandal(foot, facing)
        elif season in ["winter", "autumn"]:
            _boot(foot, facing, Color("#64788d") if season == "winter" else Color("#735744"))
        else:
            _shoe(foot, facing)

func _top(shoulder: Vector2, hip: Vector2, down: Vector2, right: Vector2, fill: Color, long_sleeves: bool, extension: float = 0.0) -> void:
    var left: Vector2 = shoulder - right * 18.0
    var rr: Vector2 = shoulder + right * 18.0
    # Sleeves follow both arm segments, rather than stretching straight to a hand.
    for side in [0, 1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        var start: Vector2 = shoulder + right * sign_x * 15.0
        var elbow: Vector2 = joints[3 + side * 2]
        var hand: Vector2 = joints[4 + side * 2]
        var end: Vector2 = elbow.lerp(hand, 0.72) if long_sleeves else start.lerp(elbow, 0.55)
        var axis: Vector2 = (elbow - start).normalized()
        var across := Vector2(-axis.y, axis.x)
        if long_sleeves:
            var forearm: Vector2 = (end - elbow).normalized()
            var edge := Vector2(-forearm.y, forearm.x)
            _paper_polygon([start + across * 9.0, elbow + across * 8.0, end + edge * 6.0, end - edge * 6.0, elbow - across * 8.0, start - across * 9.0], fill)
        else:
            _paper_polygon([start + across * 9.0, end + across * 8.0, end - across * 8.0, start - across * 9.0], fill)
    _paper_polygon([left - down * 3.0, shoulder - right * 8.0 - down * 5.0, shoulder + right * 8.0 - down * 5.0, rr - down * 3.0, hip + right * 22.0 + down * extension, hip - right * 22.0 + down * extension], fill)
    _stroke([shoulder - right * 8.0 - down * 5.0, shoulder + down * 3.0, shoulder + right * 8.0 - down * 5.0], 1.1)

func _trousers(hip: Vector2, right: Vector2, fill: Color, length: float, striped: bool) -> void:
    for side in [0, 1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        var top: Vector2 = hip + right * sign_x * 10.0
        var knee: Vector2 = joints[7 + side * 2]
        var axis: Vector2 = (knee - top).normalized()
        var across := Vector2(axis.y, -axis.x)
        var hem: Vector2 = top.lerp(knee, length)
        _paper_polygon([top - across * 12.0, top + across * 12.0, hem + across * 13.0, hem - across * 13.0], fill)
        if season == "summer" or striped:
            _stroke([top.lerp(hem, 0.62) - across * 12.0, top.lerp(hem, 0.62) + across * 12.0], 4.0, Color("#f7e7b8"))
            _stroke([hem - across * 12.0, hem + across * 12.0], 1.0)

func _dress(shoulder: Vector2, hip: Vector2, down: Vector2, right: Vector2, fill: Color, floral: bool) -> void:
    var feet_mid: Vector2 = ((joints[8] as Vector2) + (joints[10] as Vector2)) * 0.5
    var length: float = clampf((feet_mid - hip).dot(down) * 0.65, 12.0, 42.0)
    var hem: Vector2 = hip + down * length
    var spread: float = 35.0 + (10.0 if pose_lane == 3 and pose_remaining > 0.0 or preview_pose == 3 else 0.0)
    _paper_polygon([shoulder - right * 16.0, shoulder + right * 16.0, hip + right * 19.0, hem + right * spread, hem + down * 3.0, hem - right * spread, hip - right * 19.0], fill)
    _stroke([hip - right * 19.0, hip + right * 19.0], 2.4, Color("#8b9c68") if floral else GRAPHITE)
    for sign_x in [-1.0, 1.0]:
        _stroke([hip + right * sign_x * 12.0 + down * 6.0, hem + right * sign_x * 22.0 - down * 3.0], 1.0, PENCIL)
    if floral:
        for v in [Vector2(-8,12), Vector2(8,27), Vector2(-7,42)]:
            _flower(shoulder + right * v.x + down * v.y, 3.1, Color("#b76283"))
        for v in [Vector2(-20,0.55), Vector2(0,0.45), Vector2(20,0.78)]:
            _flower(hip + right * v.x + down * length * v.y, 3.8, Color("#b76283"))

func _hair(head: Vector2, down: Vector2, right: Vector2) -> void:
    var winter: bool = season == "winter"
    var length: float = 75.0 if winter else 47.0
    var fill := Color("#626b79") if winter else Color("#987454")
    _paper_polygon([head - right * 23.0 - down * 7.0, head - right * 13.0 - down * 24.0, head + right * 14.0 - down * 23.0, head + right * 24.0 - down * 5.0, head + right * 29.0 + down * length, head + right * 12.0 + down * (length - 7.0), head - right * 15.0 + down * (length - 4.0), head - right * 30.0 + down * length], fill)
    for sign_x in [-1.0, 1.0]:
        _stroke([head + right * sign_x * 21.0, head + right * sign_x * 24.0 + down * (length - 9.0)], 1.0, PENCIL)

func _face(head: Vector2) -> void:
    var points: Array = []
    for i in range(49):
        var angle: float = TAU * float(i) / 48.0
        var radius: float = 23.5 + sin(angle * 3.0 + 0.8) * 0.7 + cos(angle * 5.0) * 0.35
        points.append(head + Vector2(cos(angle) * radius, sin(angle) * radius * 1.06))
    _paper_polygon(points, WHITE)

func _flower(center: Vector2, size: float, color: Color) -> void:
    for i in range(5):
        var angle: float = TAU * float(i) / 5.0
        var p: Vector2 = center + Vector2.from_angle(angle) * size * 0.68
        draw_circle(p, size * 0.55, color, true, -1, true)
    draw_circle(center, size * 0.35, Color("#f7db86"), true, -1, true)
    _stroke([center + Vector2(1,size), center + Vector2(3,size * 1.8)], 0.8, Color("#7e9160"))

func _scarf(shoulder: Vector2, down: Vector2, right: Vector2, fill: Color) -> void:
    var neck: Vector2 = shoulder - down * 2.0
    _paper_polygon([neck + right * 5.0, neck + right * 18.0, neck + right * 27.0 + down * 31.0, neck + right * 13.0 + down * 34.0], fill)
    _paper_polygon([neck - right * 13.0 - down * 5.0, neck + right * 14.0 - down * 5.0, neck + right * 14.0 + down * 7.0, neck - right * 13.0 + down * 7.0], fill)
    for i in range(4):
        var p: Vector2 = neck + right * (14.0 + float(i) * 3.0) + down * 33.0
        _stroke([p, p + down * 4.0], 1.0)

func _cardigan(shoulder: Vector2, hip: Vector2, down: Vector2, right: Vector2) -> void:
    _paper_polygon([shoulder - right * 6.0, shoulder + right * 6.0, hip + right * 7.0, hip - right * 7.0], Color("#f1ddba"))
    _stroke([shoulder + right * 7.0, hip + right * 8.0], 1.2)
    for i in range(3):
        draw_circle(shoulder.lerp(hip, 0.45 + float(i) * 0.2) + right * 11.0, 1.6, GRAPHITE)
    var leaf: Vector2 = shoulder + down * 22.0 - right * 12.0
    _paper_polygon([leaf - down * 6.0, leaf + right * 5.0, leaf + down * 7.0, leaf - right * 4.0], Color("#9b543d"))
    _stroke([leaf - down * 5.0, leaf + down * 8.0], 0.8)

func _surfboard(hand: Vector2) -> void:
    var center: Vector2 = hand + Vector2(-3, 20)
    var tilt: float = -0.22 + ((joints[1] as Vector2).x / 140.0)
    var points: Array = []
    for i in range(49):
        var angle: float = TAU * float(i) / 48.0
        points.append(center + Vector2(cos(angle) * 13.0, sin(angle) * 52.0).rotated(tilt))
    _paper_polygon(points, Color("#f2be67"))
    _stroke([center + Vector2(0,-49).rotated(tilt), center + Vector2(0,49).rotated(tilt)], 3.0, Color("#b6573e"))
    _stroke([center + Vector2(-10,20).rotated(tilt), center + Vector2(10,20).rotated(tilt)], 3.0, Color("#fff0c7"))

func _sandal(foot: Vector2, facing: float) -> void:
    _paper_polygon([foot + Vector2(-9 * facing,1), foot + Vector2(16 * facing,1), foot + Vector2(19 * facing,7), foot + Vector2(-10 * facing,7)], Color("#b6573e"))
    _stroke([foot + Vector2(-4 * facing,0), foot + Vector2(3 * facing,-6), foot + Vector2(11 * facing,1)], 2.0)

func _boot(foot: Vector2, facing: float, fill: Color) -> void:
    _paper_polygon([foot + Vector2(-8 * facing,-18), foot + Vector2(6 * facing,-18), foot + Vector2(7 * facing,-4), foot + Vector2(17 * facing,-1), foot + Vector2(19 * facing,7), foot + Vector2(-9 * facing,7)], fill)
    _stroke([foot + Vector2(-8 * facing,4), foot + Vector2(18 * facing,4)], 2.0)
    _stroke([foot + Vector2(-7 * facing,-15), foot + Vector2(5 * facing,-15)], 3.0, Color("#ede2c9"))

# Winter study inspired by the supplied singer: paper linework, richer clothing,
# a hand-anchored microphone and a crouch rather than the shared split pose.
func _draw_winter_singer() -> void:
    var bob: float = sin(rhythm_beat * TAU) * 1.5 if preview_pose == -2 and pose_remaining <= 0.0 else 0.0
    draw_set_transform(Vector2(0,bob))
    var head: Vector2 = joints[0]
    var shoulder: Vector2 = joints[1]
    var hip: Vector2 = joints[2]
    var down: Vector2 = (hip-shoulder).normalized()
    var right := Vector2(down.y,-down.x)
    var blue := Color("#397da0")
    var shadow := Color("#305976")
    var red := Color("#bd3e64")
    var fur := Color("#e6cfad")
    # Long hair remains behind the jacket and moves slightly after the torso.
    _paper_polygon([head-right*23-down*6, head-right*12-down*23, head+right*16-down*22, head+right*25,
        head+right*27+down*66+Vector2(winter_sway,0),head+down*59,head-right*29+down*64+Vector2(winter_sway,0)],Color("#62546d"))
    for side in [0,1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        _stroke([hip+right*sign_x*9,joints[7+side*2],joints[8+side*2]],4.2)
        _boot(joints[8+side*2],sign_x,Color("#94594f"))
        # Snow-colored folded boot cuffs.
        var foot: Vector2 = joints[8+side*2]
        _stroke([foot+Vector2(-8*sign_x,-16),foot+Vector2(6*sign_x,-16)],5.0,Color("#f0ecdf"))
    # A dark skirt hem peeks out from the parka.
    _paper_polygon([hip-right*21,hip+right*21,hip+right*24+down*14,hip-right*24+down*14],Color("#514e68"))
    _stroke([head+down*21,shoulder+down*6],3.0)
    # Layered rounded segments tolerate sharply bent elbows without folding a polygon.
    for side in [0,1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        var start: Vector2 = shoulder+right*sign_x*15
        var elbow: Vector2 = joints[3+side*2]
        var wrist: Vector2 = elbow.lerp(joints[4+side*2],.74)
        var sleeve := PackedVector2Array([start,elbow,wrist])
        draw_polyline(sleeve,GRAPHITE,21.0,true)
        draw_circle(elbow,10.5,GRAPHITE,true,-1,true)
        draw_polyline(sleeve,blue,17.0,true)
        draw_circle(elbow,8.5,blue,true,-1,true)
    _paper_polygon([shoulder-right*18-down*3,shoulder-right*8-down*5,shoulder+right*8-down*5,
        shoulder+right*18-down*3,hip+right*22+down*10,hip-right*22+down*10],blue)
    # Colored pencil shade along one side, plus contrast zipper and stitched pockets.
    _paper_polygon([shoulder-right*18,shoulder-right*9+down*6,hip-right*12+down*9,hip-right*22+down*10],shadow)
    _stroke([shoulder+down*8,hip+down*9],4.0,Color("#b7d5d2"))
    _stroke([shoulder+right*3+down*10,hip+right*3+down*9],1.0)
    _stroke([hip-right*21+down*8,hip+right*21+down*8],3.5,Color("#4b4c68"))
    for sign_x in [-1.0,1.0]:
        var pocket: Vector2 = hip+right*sign_x*13-down*10
        _stroke([pocket-right*4-down*2,pocket+right*4-down*2,pocket+right*4+down*6],1.2)
    # Fur-lined hood falls behind the face, rather than covering the expression.
    _stroke([shoulder-right*21+down*3,shoulder-right*25-down*12,shoulder-right*19-down*18],9.0,fur)
    _stroke([shoulder+right*20+down*3,shoulder+right*24-down*10],8.0,fur)
    _face(head)
    _winter_expression(head,down,right)
    _singer_hat(head,down,right)
    # The scarf end lags slightly behind direction changes.
    var neck: Vector2 = shoulder-down*1.0
    var tail: Vector2 = neck-right*24+down*35+Vector2(winter_sway,0)
    _paper_polygon([neck-right*6,neck+right*6,tail+right*7,tail-right*6],red)
    _stroke([tail-right*4-down*3,tail+right*6-down*3],2.0,Color("#dc775a"))
    _paper_polygon([neck-right*19-down*5,neck+right*17-down*5,neck+right*19+down*7,neck-right*17+down*9],red)
    _stroke([neck-right*14+down*5,neck+right*14+down*4],1.3,Color("#8c3658"))
    # Mittens cap the sleeves and stay attached to the animated hands.
    for side in [0,1]:
        var hand: Vector2 = joints[4+side*2]
        var elbow: Vector2 = joints[3+side*2]
        var axis: Vector2 = (hand-elbow).normalized()
        var across := Vector2(-axis.y,axis.x)
        var wrist: Vector2 = elbow.lerp(hand,.74)
        _stroke([wrist-across*5,wrist+across*5],4.0,Color("#4b4c68"))
        _paper_polygon([hand-axis*6-across*5,hand+axis*5-across*6,hand+axis*8+across*1,hand+axis*3+across*7,hand-axis*6+across*5],red)
    _microphone(joints[6],joints[5])

func _singer_hat(head: Vector2, down: Vector2, right: Vector2) -> void:
    _paper_polygon([head-right*25-down*15,head-right*28-down*25,head-right*19-down*39,head+right*2-down*42,
        head+right*20-down*31,head+right*25-down*15],Color("#d66e59"))
    _paper_polygon([head-right*25-down*10,head-right*27-down*25,head-right*19-down*36,head-right*12-down*33,head-right*17-down*10],Color("#a84069"))
    _stroke([head-right*23-down*27,head-right*7-down*33,head+right*12-down*29,head+right*20-down*22],5.0,Color("#4f9eac"))
    _paper_polygon([head-right*25-down*21,head+right*24-down*21,head+right*25-down*10,head-right*24-down*10],Color("#bb4d70"))
    for i in range(7):
        var offset: float = -21.0+float(i)*7.0
        _stroke([head+right*offset-down*19,head+right*offset-down*12],2.5,Color("#e68b61"))
    var pom: Vector2 = head-right*24-down*43
    draw_circle(pom,8.0,Color("#cf605f"),true,-1,true)
    draw_arc(pom,8.0,0,TAU,24,GRAPHITE,1.8,true)
    _stroke([pom-Vector2(3,1),pom+Vector2(3,-2)],2.0,Color("#e99b64"))

func _winter_expression(head: Vector2, down: Vector2, right: Vector2) -> void:
    var lane: int = preview_pose if preview_pose >= -1 else (pose_lane if pose_remaining > 0.0 else -1)
    var left: Vector2 = head-right*9-down*1
    var rr: Vector2 = head+right*9-down*1
    if lane == 0 or lane == 3:
        # Closed eyes on the high note and crouch.
        _stroke([left-right*4+down*1,left-down*2,left+right*4+down*1],2.5)
        _stroke([rr-right*4+down*1,rr-down*2,rr+right*4+down*1],2.5)
    else:
        draw_circle(left,2.8,GRAPHITE,true,-1,true)
        draw_circle(rr,2.8,GRAPHITE,true,-1,true)
        if lane >= 0:
            _stroke([left-right*4-down*7,left+right*4-down*3],2.0)
            _stroke([rr-right*4-down*3,rr+right*4-down*7],2.0)
    var mouth: Vector2 = head+down*12+right*2
    if lane == -1:
        _stroke([mouth-right*6-down*2,mouth-right*2+down*2,mouth+right*4+down*1,mouth+right*7-down*2],1.7)
    else:
        _paper_polygon([mouth-right*4,mouth+right*4,mouth+right*3+down*5,mouth-right*2+down*5],GRAPHITE)

func _microphone(hand: Vector2, elbow: Vector2) -> void:
    # Grip and capsule are derived from the hand at every intermediate frame.
    var direction: Vector2 = ((hand-elbow).normalized()+Vector2(0,-2)).normalized()
    var across := Vector2(-direction.y,direction.x)
    _paper_polygon([hand-direction*7-across*3,hand+direction*17-across*3,hand+direction*17+across*3,hand-direction*7+across*3],Color("#536171"))
    var capsule: Vector2 = hand+direction*22
    draw_circle(capsule,8.5,Color("#738a9a"),true,-1,true)
    draw_arc(capsule,8.5,0,TAU,24,GRAPHITE,2.0,true)
    for offset in [-4.0,0.0,4.0]:
        _stroke([capsule+direction*offset-across*6,capsule+direction*offset+across*6],.8,Color("#3b5264"))
        _stroke([capsule+across*offset-direction*6,capsule+across*offset+direction*6],.8,Color("#3b5264"))
