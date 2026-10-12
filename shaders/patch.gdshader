shader_type spatial;
// A round ground patch with a ragged soft edge (village square, camp, quarry, crypt, pond shore).
// Put it on a square PlaneMesh; UV 0..1 covers the square.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley;

uniform vec3 base_color : source_color = vec3(0.66, 0.58, 0.40);
uniform vec3 edge_color : source_color = vec3(0.40, 0.34, 0.22);
uniform bool cobble = false;
uniform float cobble_size = 1.7;

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
	float d = length(UV - vec2(0.5)) * 2.0;
	float n = vnoise(p * 0.45) * 0.6 + vnoise(p * 2.1) * 0.4;
	vec3 c = base_color * (0.84 + 0.32 * n);
	if (cobble) {
		vec2 q = p * cobble_size;
		q.x += floor(q.y) * 0.5;
		vec2 f = fract(q);
		// fade the stone pattern out with distance so it does not shimmer
		float aa = clamp(1.0 - (fwidth(q.x) + fwidth(q.y)) * 2.0, 0.0, 1.0);
		float gap = clamp(step(f.x, 0.07) + step(f.y, 0.07), 0.0, 1.0) * aa;
		float stone = mix(0.5, hash(floor(q)), aa);
		c = mix(base_color * (0.78 + 0.40 * stone), edge_color * 0.7, gap);
	}
	float ragged = (vnoise(p * 0.9) - 0.5) * 0.25;
	float inside = 1.0 - smoothstep(0.80, 1.0, d + ragged);
	c = mix(edge_color, c, smoothstep(0.0, 0.5, inside));
	ALBEDO = c;
	ALPHA = clamp(inside * 1.5, 0.0, 1.0);
	ROUGHNESS = 1.0;
}
