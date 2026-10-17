shader_type canvas_item;
render_mode unshaded;
uniform sampler2D rock_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D burn_mask : filter_nearest, repeat_disable;
uniform float seed_phase = 0.0;
// Global sampling never resets at logical cell boundaries. Mirroring avoids seams.
vec2 volcanic_uv(vec2 global_uv) {
    vec2 point = global_uv * vec2(2.7, 2.1);
    point += vec2(sin(seed_phase * 1.7), cos(seed_phase * 1.3)) * 0.23;
    vec2 warp = vec2(sin(point.y * 3.1 + point.x * 1.3 + seed_phase),
                     sin(point.x * 2.9 - point.y * 1.7 + seed_phase * 0.7));
    point += warp * 0.065;
    return vec2(1.0) - abs(mod(point, vec2(2.0)) - vec2(1.0));
}
void fragment() {
    vec4 rock = texture(rock_texture, volcanic_uv(UV));
    float mask = texture(burn_mask, UV).r;
    float lava = smoothstep(0.1, 0.48, rock.r - rock.b);
    float pulse = 0.96 + 0.06 * sin(TIME * 1.7 + UV.x * 12.0 + UV.y * 9.0 + seed_phase);
    vec3 color = rock.rgb * mix(0.9, pulse * 1.18, lava);
    COLOR = vec4(color, mask * 0.98);
}
