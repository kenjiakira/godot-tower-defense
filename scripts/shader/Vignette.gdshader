shader_type canvas_item;

uniform float edge_start = 0.82;
uniform float softness = 0.22;
uniform vec4 color : source_color = vec4(0.02, 0.015, 0.01, 0.38);

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    uv.x *= 1.45;

    float d = length(uv);

    float mask = smoothstep(edge_start, edge_start + softness, d);

    COLOR = vec4(color.rgb, color.a * mask);
}