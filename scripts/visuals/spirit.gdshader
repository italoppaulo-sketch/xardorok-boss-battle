shader_type canvas_item;
varying vec4 vertex_modulate;
void vertex() {
    vertex_modulate = COLOR;
}
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float shimmer = 0.92 + 0.08 * sin(TIME * 3.0 + UV.y * 12.0);
    vec3 ethereal = mix(tex.rgb, vec3(0.55, 0.85, 1.0), 0.58);
    COLOR = vec4(ethereal * 1.25, tex.a * 0.56 * shimmer) * vertex_modulate;
}
