shader_type canvas_item;
render_mode unshaded;
uniform sampler2D rock_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 field_size = vec2(650.0, 450.0);
uniform float phase = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
void fragment() {
	float mask = texture(TEXTURE, UV).a;
	vec2 p = UV * field_size;
	// Coordenadas globais: a textura atravessa bordas internas sem reiniciar.
	vec2 warp = vec2(noise(p * 0.005 + vec2(5.2, 1.7)), noise(p * 0.006 + vec2(8.7, 9.2)));
	vec2 sample_uv = p * 1.65 / vec2(506.0, 193.0) + (warp - 0.5) * 0.025 + vec2(0.173, 0.271);
	// Amostras deslocadas cobrem bordas da foto sem repetir uma figura espelhada.
	sample_uv = fract(sample_uv);
	vec2 weights = smoothstep(vec2(0.0), vec2(0.14), sample_uv) * (1.0 - smoothstep(vec2(0.86), vec2(1.0), sample_uv));
	vec3 a = texture(rock_texture, sample_uv).rgb;
	vec3 b = texture(rock_texture, fract(sample_uv + vec2(0.5, 0.0))).rgb;
	vec3 c = texture(rock_texture, fract(sample_uv + vec2(0.0, 0.5))).rgb;
	vec3 d = texture(rock_texture, fract(sample_uv + vec2(0.5, 0.5))).rgb;
	vec3 rock = mix(mix(d, c, weights.x), mix(b, a, weights.x), weights.y);
	float molten = smoothstep(0.1, 0.5, rock.r - max(rock.g, rock.b) * 0.72);
	float variation = 0.87 + noise(p * 0.021) * 0.22;
	float pulse = 0.94 + sin(phase * 1.6 + noise(p * 0.017) * 5.0) * 0.06;
	vec3 color = rock * variation;
	color += molten * vec3(0.13, 0.045, 0.0) * pulse;
	color *= mix(0.60, 1.0, mask);
	COLOR = vec4(color, mask * 0.98);
}
