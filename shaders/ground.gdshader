shader_type spatial;
// Rich meadow ground: large soft patches of light and dark green, a few dry-grass
// areas, fine speckle. No texture needed - it is all procedural noise in world space.
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 grass_light : source_color = vec3(0.50, 0.70, 0.27);
uniform vec3 grass_mid : source_color = vec3(0.34, 0.56, 0.21);
uniform vec3 grass_dark : source_color = vec3(0.23, 0.42, 0.17);
uniform vec3 dry_grass : source_color = vec3(0.66, 0.63, 0.32);
uniform float darken = 1.0;
uniform bool clip_south_sea = false;
global uniform float wetness;            // 0 dry .. 1 soaked (set by Weather); darkens the ground

uniform vec2 world_offset = vec2(0.0);   // far-away regions (the Frontier) subtract their origin: float noise breaks at thousands of metres
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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - vec3(world_offset.x, 0.0, world_offset.y);
}

void fragment() {
	if (clip_south_sea && world_offset == vec2(0.0)) {
		if ((wpos.z >= 85.0 && wpos.x >= -195.0 && wpos.x <= 55.5) || wpos.z >= 220.0) {
			discard;
		}
	}
	vec2 p = wpos.xz;
	float large = fbm(p * 0.016);
	float mid = fbm(p * 0.085 + 11.0);
	float fine = vnoise(p * 1.6);
	float speck = vnoise(p * 6.5);
	vec3 c = mix(grass_dark, grass_mid, smoothstep(0.28, 0.62, large));
	c = mix(c, grass_light, smoothstep(0.40, 0.78, mid) * 0.8);
	c = mix(c, dry_grass, smoothstep(0.62, 0.86, fbm(p * 0.011 + 31.0)) * 0.5);
	c *= 0.90 + 0.20 * fine;
	c += (speck - 0.5) * 0.06;
	ALBEDO = c * darken * (1.0 - 0.28 * wetness);
	ROUGHNESS = 0.97;
	SPECULAR = 0.04;
}
