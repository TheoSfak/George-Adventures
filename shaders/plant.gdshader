shader_type spatial;
// Grass tufts, flowers and crops (MultiMesh instances). They sway gently in the wind.
// Per-instance colour comes from INSTANCE_CUSTOM. The mesh's vertex-colour alpha says
// how a vertex is coloured:
//   alpha ~ 1.0  flat instance colour        (flower petals, cabbages)
//   alpha ~ 0.5  instance colour, dark base -> light tip   (grass blades)
//   alpha ~ 0.0  fixed vertex colour         (stems, flower centres)
render_mode cull_disabled, diffuse_burley;

uniform float sway : hint_range(0.0, 1.0) = 0.35;
uniform float blade_height = 0.5;

varying vec3 tint;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float gust = sin(TIME * 1.7 + origin.x * 0.45 + origin.z * 0.31);
	VERTEX.x += gust * sway * h * 0.28;
	VERTEX.z += gust * sway * h * 0.16;
	float a = COLOR.a;
	if (a < 0.25) {
		tint = COLOR.rgb;
	} else if (a < 0.75) {
		tint = INSTANCE_CUSTOM.rgb * (0.55 + 0.65 * clamp(VERTEX.y / blade_height, 0.0, 1.0));
	} else {
		tint = INSTANCE_CUSTOM.rgb;
	}
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 0.85;
}
