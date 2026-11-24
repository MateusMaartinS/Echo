extends PaperMusician
class_name SpritePlayer

# Original PNGs are selected with atlas regions, never rewritten or recolored.
const FOOT_Y: float = 96.0
const MANIFEST: String = "res://assets/characters/player/animations/manifest.json"
const ACTIONS := ["up","right","left","down"]
const ATTACK_SECONDS: float = 0.045
const RELEASE_SECONDS: float = 0.065

var visual: Node2D
var sprite: Sprite2D
var animations: Dictionary = {}
var animation_name: String = ""
var frame_index: int = -1
var action_elapsed: float = 0.0
var cleanup_material: ShaderMaterial

func _manifest_path() -> String:
    return MANIFEST

func _ready() -> void:
    visual = Node2D.new()
    visual.position = Vector2(0,FOOT_Y)
    add_child(visual)
    sprite = Sprite2D.new()
    sprite.centered = false
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    visual.add_child(sprite)
    var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_manifest_path())) as Dictionary
    var definitions: Dictionary = config.get(outfit,config.get("classic",{}))
    for action in definitions:
        var definition: Dictionary = definitions[action]
        var sheet: Texture2D = load(str(definition["texture"])) as Texture2D
        var frames: Array[AtlasTexture] = []
        var anchors: Array[Vector2] = []
        for frame_data in definition["frames"]:
            var region: Array = frame_data["region"]
            var frame := AtlasTexture.new()
            frame.atlas = sheet
            frame.region = Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
            frame.filter_clip = true
            frames.append(frame)
            anchors.append(Vector2(float(frame_data["anchor"][0]),float(frame_data["anchor"][1])))
        animations[action] = {"frames":frames,"anchors":anchors,"scale":float(definition["scale"]),"cleanup":bool(definition.get("alpha_cleanup",false))}
    # Suppress low-alpha contamination only on the female down sheet.
    # Original RGB and opaque artwork remain unchanged, including on disk.
    var cleanup_shader := Shader.new()
    cleanup_shader.code = "shader_type canvas_item; void fragment() { COLOR.a *= smoothstep(0.45, 0.65, COLOR.a); }"
    cleanup_material = ShaderMaterial.new()
    cleanup_material.shader = cleanup_shader
    _show_frame("idle",0)

func play_pose(lane: int, hold_seconds: float = 0.0) -> void:
    if lane < 0 or lane >= ACTIONS.size():
        return
    super.play_pose(lane,hold_seconds)
    action_elapsed = 0.0
    if sprite != null:
        _show_frame(ACTIONS[lane],0)

func _show_frame(action: String, index: int) -> void:
    if animation_name == action and frame_index == index:
        return
    animation_name = action
    frame_index = index
    var animation: Dictionary = animations[action]
    var scale_value: float = float(animation["scale"])
    sprite.texture = animation["frames"][index]
    sprite.scale = Vector2.ONE*scale_value
    sprite.position = -(animation["anchors"][index] as Vector2)*scale_value
    sprite.material = cleanup_material if bool(animation["cleanup"]) else null

func _process(delta: float) -> void:
    if frozen or sprite == null:
        return
    pose_remaining = maxf(0.0,pose_remaining-delta)
    action_elapsed += delta
    if preview_pose >= -1:
        if preview_pose >= 0:
            _show_frame(ACTIONS[preview_pose],1)
        else:
            _show_frame("idle",0)
    elif pose_remaining > 0.0 and pose_lane >= 0:
        # The middle drawing sustains the note, then the final drawing releases it.
        var index: int = 0 if action_elapsed < ATTACK_SECONDS else (2 if pose_remaining <= RELEASE_SECONDS else 1)
        _show_frame(ACTIONS[pose_lane],index)
    else:
        var beat_phase: float = fposmod(rhythm_beat,1.0)
        _show_frame("idle",0 if beat_phase < .25 else (1 if beat_phase < .60 else 2))

func _draw() -> void:
    pass
