extends SpritePlayer
class_name SpriteLord

# Bosses share the beat, hold and pause animation controller with the player.
# Their artwork is stored separately from unlockable player outfits.
var frame_materials: Dictionary = {}

func _ready() -> void:
    var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_manifest_path()))
    var definitions: Dictionary = config.get(outfit,{})
    for action in definitions:
        var definition: Dictionary = definitions[action]
        for index in range(definition["frames"].size()):
            var frame: Dictionary = definition["frames"][index]
            if not frame.has("exclude_rect"):
                continue
            # Some source sheets interleave the bounds of neighboring frames.
            # Hide only that neighbor's pixels; keep the source PNG untouched.
            var sheet: Texture2D = load(str(definition["texture"])) as Texture2D
            var excluded: Array = frame["exclude_rect"]
            var material := ShaderMaterial.new()
            var shader := Shader.new()
            shader.code = "shader_type canvas_item; uniform vec4 excluded_region; void fragment() { if (UV.x >= excluded_region.x && UV.y >= excluded_region.y && UV.x < excluded_region.z && UV.y < excluded_region.w) { COLOR.a = 0.0; } }"
            material.shader=shader
            material.set_shader_parameter("excluded_region",Vector4(float(excluded[0])/sheet.get_width(),float(excluded[1])/sheet.get_height(),float(excluded[0]+excluded[2])/sheet.get_width(),float(excluded[1]+excluded[3])/sheet.get_height()))
            frame_materials["%s_%d" % [action,index]]=material
    super._ready()

func _show_frame(action: String, index: int) -> void:
    super._show_frame(action,index)
    var key: String = "%s_%d" % [action,index]
    if frame_materials.has(key):
        sprite.material=frame_materials[key]

func _manifest_path() -> String:
    return "res://assets/characters/bosses/manifest.json"
