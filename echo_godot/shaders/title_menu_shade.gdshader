shader_type canvas_item;
render_mode unshaded;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * vec2(1.05, 0.95);
    float shade = 1.0 - smoothstep(0.22, 0.54, length(p));
    COLOR = vec4(0.025, 0.02, 0.045, shade * 0.72);
}
