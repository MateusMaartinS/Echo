shader_type canvas_item;

uniform float noise_strength : hint_range(0.0, 0.2) = 0.04;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float n = random(UV * 400.0);
    vec3 paper = tex.rgb + (n - 0.5) * noise_strength;
    COLOR = vec4(paper, tex.a);
}
