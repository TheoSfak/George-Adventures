shader_type spatial;
// Calm pond water: teal depth colour, drifting light patches, sky reflection at grazing angles.
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.07, 0.30, 0.40);
uniform vec3 shallow_color : source_color = vec3(0.22, 0.62, 0.62);
uniform vec3 sky_color : source_color = vec3(0.70, 0.86, 0.98);

varying vec3 wpos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float w1 = vnoise(p * 0.35 + vec2(TIME * 0.08, TIME * 0.05));
	float w2 = vnoise(p * 0.9 - vec2(TIME * 0.06, -TIME * 0.09));
	float ripple = (w1 + w2) * 0.5;
	vec3 c = mix(deep_color, shallow_color, smoothstep(0.3, 0.75, ripple));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	c = mix(c, sky_color, fres * 0.6);
	ALBEDO = c;
	ALPHA = 0.88;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	METALLIC = 0.0;
}
