shader_type canvas_item;

uniform float jitter_strength = 0.002;

void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 40.0) * jitter_strength;
    COLOR = texture(TEXTURE, uv) * COLOR;
}
