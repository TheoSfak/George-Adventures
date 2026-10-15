shader_type spatial;
render_mode cull_disabled;
// Slowly flowing lava for the Ash Valley (ash_valley.gd): two layers of noise drift in different
// directions, the hot parts glow. world_offset keeps the noise coordinates small far away from the
// origin (the valley stands at x = 6000), like the ground shaders.

uniform vec3 hot_color : source_color = vec3(1.0, 0.66, 0.14);
uniform vec3 cool_color : source_color = vec3(0.30, 0.035, 0.01);
uniform float flow_speed = 0.10;
uniform float scale = 0.2;
uniform float energy = 2.0;
uniform vec2 world_offset = vec2(0.0);

varying vec2 flat_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amp * noise(p);
		p = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80)) * p * 2.03 + vec2(7.3, 1.9);
		amp *= 0.5;
	}
	return value;
}

void vertex() {
	flat_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - world_offset;
}

void fragment() {
	float t = TIME * flow_speed;
	vec2 uv = flat_pos * scale;
	float a = fbm(uv + vec2(t, t * 0.6));
	float b = fbm(uv * 1.7 - vec2(t * 0.8, -t));
	float heat = smoothstep(0.36, 0.74, a * 0.55 + b * 0.55);
	heat = heat * heat * (3.0 - 2.0 * heat);
	vec3 col = mix(cool_color, hot_color, heat);
	ALBEDO = col * 0.15;
	EMISSION = col * energy * (0.35 + 1.1 * heat);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
