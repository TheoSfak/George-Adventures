shader_type spatial;
// Paths: a soft-edged ribbon of packed dirt, or village cobblestones.
// UV.x runs across the path (0..1), UV.y along it.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley;

uniform vec3 base_color : source_color = vec3(0.66, 0.52, 0.33);
uniform vec3 edge_color : source_color = vec3(0.40, 0.33, 0.20);
uniform bool cobble = false;
uniform float edge_soft = 0.22;

uniform vec2 world_offset = vec2(0.0);   // see ground.gdshader
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
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - vec3(world_offset.x, 0.0, world_offset.y);
}

void fragment() {
	vec2 p = wpos.xz;
	float n = vnoise(p * 0.55) * 0.6 + vnoise(p * 2.3) * 0.4;
	vec3 c = base_color * (0.84 + 0.32 * n);
	if (cobble) {
		vec2 q = p * 1.7;
		q.x += floor(q.y) * 0.5;
		vec2 f = fract(q);
		// fade the stone pattern out with distance so it does not shimmer
		float aa = clamp(1.0 - (fwidth(q.x) + fwidth(q.y)) * 2.0, 0.0, 1.0);
		float gap = clamp(step(f.x, 0.07) + step(f.y, 0.07), 0.0, 1.0) * aa;
		float stone = mix(0.5, hash(floor(q)), aa);
		vec3 stone_col = base_color * (0.78 + 0.40 * stone);
		c = mix(stone_col, edge_color * 0.7, gap);
	}
	// darker, ragged border where the path meets the grass
	float across = abs(UV.x - 0.5) * 2.0;
	float ragged = (vnoise(p * 1.3) - 0.5) * 0.35;
	float inside = 1.0 - smoothstep(1.0 - edge_soft, 1.0, across + ragged);
	c = mix(edge_color, c, smoothstep(0.0, 0.5, inside));
	ALBEDO = c;
	ALPHA = clamp(inside * 1.6, 0.0, 1.0);
	ROUGHNESS = 1.0;
}
