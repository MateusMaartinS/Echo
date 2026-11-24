extends Node2D
class_name PaperMusician

# Paper puppet: joint positions are shared by the clothing and stick limbs.
# Coordinates fit the portrait space to the left of the rhythm tracks.
const GRAPHITE := Color("#393b35")
const PENCIL := Color(0.23, 0.24, 0.21, 0.22)
const WHITE := Color("#fffdf4")
const CARGO := Color("#7e9160")
const CARGO_SHADE := Color("#697b50")
const IDLE := [Vector2(0,-60), Vector2(0,-30), Vector2(0,20), Vector2(-30,-5), Vector2(-39,14), Vector2(31,-5), Vector2(39,14), Vector2(-18,57), Vector2(-24,88), Vector2(20,57), Vector2(29,88)]
# head, shoulders, hips, left elbow/hand, right elbow/hand, left knee/foot, right knee/foot
const POSES := [
    [Vector2(0,-66), Vector2(0,-35), Vector2(0,18), Vector2(-34,-61), Vector2(-54,-91), Vector2(34,-61), Vector2(54,-91), Vector2(-18,55), Vector2(-28,88), Vector2(19,55), Vector2(30,88)],
    [Vector2(30,-57), Vector2(17,-27), Vector2(-2,21), Vector2(-22,-20), Vector2(-31,-2), Vector2(36,-4), Vector2(34,17), Vector2(-29,51), Vector2(-49,82), Vector2(34,53), Vector2(48,78)],
    [Vector2(-27,-59), Vector2(-14,-29), Vector2(7,20), Vector2(-36,-10), Vector2(-33,13), Vector2(26,-29), Vector2(39,-44), Vector2(-27,56), Vector2(-45,79), Vector2(28,52), Vector2(50,83)],
    [Vector2(0,-20), Vector2(0,10), Vector2(0,52), Vector2(-35,18), Vector2(-49,0), Vector2(35,18), Vector2(49,0), Vector2(-40,65), Vector2(-68,68), Vector2(40,65), Vector2(68,68)],
]

var outfit: String = "classic"

var joints: Array = IDLE.duplicate()
var pose_lane: int = -1
var pose_remaining: float = 0.0
var rhythm_beat: float = 0.0
var frozen: bool = false
var preview_pose: int = -2 # -2 animates; -1 idle; 0..3 holds a preview pose

func play_pose(lane: int, hold_seconds: float = 0.0) -> void:
    if lane < 0 or lane >= Lanes.COUNT:
        return
    pose_lane = lane
    pose_remaining = maxf(0.22, hold_seconds)

func release_pose(lane: int) -> void:
    if pose_lane == lane:
        pose_remaining = minf(pose_remaining, 0.10)

# Skins can supply their own choreography while retaining the shared tweening.
func _idle_joints() -> Array:
    return IDLE

func _pose_joints(lane: int) -> Array:
    return POSES[lane]

func _process(delta: float) -> void:
    if frozen:
        return
    if preview_pose >= -1:
        joints = _idle_joints().duplicate() if preview_pose == -1 else _pose_joints(preview_pose).duplicate()
    else:
        pose_remaining = maxf(0.0, pose_remaining - delta)
        var target: Array = _pose_joints(pose_lane) if pose_remaining > 0.0 and pose_lane >= 0 else _idle_joints()
        var blend: float = 1.0 - exp(-delta * (26.0 if pose_remaining > 0.0 else 14.0))
        for i in joints.size():
            joints[i] = (joints[i] as Vector2).lerp(target[i], blend)
    queue_redraw()

func _stroke(points: Array, width: float = 2.1, color: Color = GRAPHITE) -> void:
    var line := PackedVector2Array(points)
    draw_polyline(line, color, width, true)
    # A second, fixed pencil pass adds texture without flickering every frame.
    var rough := PackedVector2Array()
    for i in line.size() - 1:
        var a: Vector2 = line[i]
        var b: Vector2 = line[i + 1]
        rough.append(a + Vector2(-0.7, 0.6))
        rough.append(a.lerp(b, 0.47) + Vector2(0.7, -0.6))
    rough.append(line[-1] + Vector2(-0.4, 0.8))
    draw_polyline(rough, PENCIL, 0.9, true)

func _paper_polygon(points: Array, fill: Color) -> void:
    draw_colored_polygon(PackedVector2Array(points), fill)
    var closed: Array = points.duplicate()
    closed.append(points[0])
    _stroke(closed)

func _draw() -> void:
    var bob: float = sin(rhythm_beat * TAU) * 1.5 if preview_pose == -2 and pose_remaining <= 0.0 else 0.0
    draw_set_transform(Vector2(0, bob))
    var head: Vector2 = joints[0]
    var shoulder: Vector2 = joints[1]
    var hip: Vector2 = joints[2]
    var down: Vector2 = (hip - shoulder).normalized()
    var right := Vector2(down.y, -down.x)
    var palette: Dictionary = {
        "classic": [WHITE,CARGO,CARGO_SHADE],
        "spring": [Color("#f2d4d3"),Color("#a1b481"),Color("#82976b")],
        "summer": [Color("#8dc5c2"),Color("#e4a462"),Color("#cd8854")],
        "autumn": [Color("#bd895c"),Color("#83705b"),Color("#6e5f4e")],
        "winter": [Color("#4d88a6"),Color("#64788c"),Color("#506375")]
    }
    var colors: Array = palette.get(outfit,palette["classic"])
    # Bare stick arms, deliberately kept thin relative to the clothing.
    for side in [0, 1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        _stroke([shoulder + right * sign_x * 17.0, joints[3 + side * 2], joints[4 + side * 2]], 3.5)
    if outfit in ["autumn","winter"]:
        for side in [0,1]:
            var arm := PackedVector2Array([shoulder+right*(-17.0 if side == 0 else 17.0),joints[3+side*2],(joints[3+side*2] as Vector2).lerp(joints[4+side*2],.72)])
            draw_polyline(arm,GRAPHITE,16.0,true)
            draw_circle(joints[3+side*2],8.0,GRAPHITE,true,-1,true)
            draw_polyline(arm,colors[0],12.0,true)
            draw_circle(joints[3+side*2],6.0,colors[0],true,-1,true)
    # Bare shins are behind the cargo shorts and sneakers.
    for side in [0, 1]:
        _stroke([joints[7 + side * 2], joints[8 + side * 2]], 3.7)
    _stroke([head + down * 21.0, shoulder + down * 5.0], 3.0)
    # Individual wide cargo legs follow the upper legs, including the split.
    for side in [0, 1]:
        var sign_x: float = -1.0 if side == 0 else 1.0
        var top: Vector2 = hip + right * sign_x * 10.0
        var knee: Vector2 = joints[7 + side * 2]
        var axis: Vector2 = (knee - top).normalized()
        var across := Vector2(axis.y, -axis.x)
        var hem: Vector2 = top.lerp(knee, 0.83)
        _paper_polygon([top - across * 13.0, top + across * 13.0, hem + across * 14.0, hem - across * 14.0], colors[1])
        var pocket: Vector2 = top.lerp(hem, 0.52)
        _paper_polygon([pocket - across * 8.0, pocket + across * 8.0, pocket + across * 8.0 + axis * 10.0, pocket - across * 8.0 + axis * 10.0], colors[2])
        _stroke([pocket - across * 8.0 + axis * 3.0, pocket + across * 8.0 + axis * 3.0], 1.0)
    # Oversized white T-shirt, sleeves aimed toward the elbows.
    var left: Vector2 = shoulder - right * 18.0
    var rr: Vector2 = shoulder + right * 18.0
    var le: Vector2 = left.lerp(joints[3], 0.55)
    var re: Vector2 = rr.lerp(joints[5], 0.55)
    _paper_polygon([shoulder - right * 8.0 - down * 5.0, left - down * 3.0, le - down * 7.0, le + down * 8.0, left + down * 16.0, hip - right * 21.0 + down * 3.0, hip + right * 21.0 + down * 3.0, rr + down * 16.0, re + down * 8.0, re - down * 7.0, rr - down * 3.0, shoulder + right * 8.0 - down * 5.0], colors[0])
    _stroke([shoulder - right * 8.0 - down * 5.0, shoulder + down * 2.0, shoulder + right * 8.0 - down * 5.0], 1.2)
    _stroke([hip - right * 18.0, hip + right * 17.0], 1.0)
    _stroke([hip - right * 15.0 - down * 9.0, hip - right * 11.0 - down * 18.0], 1.0, PENCIL)
    _outfit_details(shoulder,hip,down,right)
    # Empty circular face, like the references, with a slightly uneven contour.
    var outline: Array = []
    for i in range(49):
        var angle: float = TAU * float(i) / 48.0
        var radius: float = 23.5 + sin(angle * 3.0 + 0.8) * 0.7 + cos(angle * 5.0) * 0.35
        outline.append(head + Vector2(cos(angle) * radius, sin(angle) * radius * 1.06))
    _paper_polygon(outline, WHITE)
    if outfit == "winter":
        _paper_polygon([head-right*24-down*7,head-right*18-down*27,head-down*32,head+right*18-down*26,head+right*24-down*7],Color("#bc5770"))
        _stroke([head-right*24-down*7,head+right*24-down*7],5.0,Color("#e1c9a6"))
        draw_circle(head-down*35,5.0,Color("#e1c9a6"),true,-1,true)
    for side in [0, 1]:
        _shoe(joints[8 + side * 2], -1.0 if side == 0 else 1.0)

func _shoe(foot: Vector2, facing: float) -> void:
    var points: Array = []
    for v in [Vector2(-8,-9), Vector2(3,-11), Vector2(10,-5), Vector2(17,-3), Vector2(20,4), Vector2(18,8), Vector2(-9,8)]:
        points.append(foot + Vector2(v.x * facing, v.y))
    _paper_polygon(points, WHITE)
    _stroke([foot + Vector2(-8 * facing,4), foot + Vector2(18 * facing,4)], 1.2)
    for i in range(3):
        _stroke([foot + Vector2(float(i) * 3.0 * facing,-6), foot + Vector2((float(i) * 3.0 + 4.0) * facing,-2)], 1.1)

func _outfit_details(shoulder: Vector2, hip: Vector2, down: Vector2, right: Vector2) -> void:
    if outfit == "spring":
        for offset in [Vector2(-8,14),Vector2(8,28),Vector2(-6,39)]:
            var center: Vector2 = shoulder+right*offset.x+down*offset.y
            for petal in range(5):
                draw_circle(center+Vector2.from_angle(float(petal)*TAU/5.0)*2.7,2.0,Color("#b56b88"),true,-1,true)
            draw_circle(center,1.3,Color("#f3df9f"),true,-1,true)
    elif outfit == "summer":
        for offset in [16.0,24.0]:
            _stroke([shoulder-right*17+down*offset,shoulder+right*17+down*offset],3.0,Color("#edf0cf"))
    elif outfit in ["autumn","winter"]:
        _stroke([shoulder+down*8,hip],2.0,Color("#e2cfaf"))
        var color := Color("#a9523b") if outfit == "autumn" else Color("#bc5770")
        var neck: Vector2 = shoulder-down*2
        _paper_polygon([neck+right*6,neck+right*16,neck+right*24+down*28,neck+right*12+down*30],color)
        _paper_polygon([neck-right*12-down*4,neck+right*12-down*4,neck+right*13+down*6,neck-right*12+down*6],color)
