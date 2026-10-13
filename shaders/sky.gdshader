shader_type sky;
// Day/night sky: colour gradient, a sun disc, a moon disc and stars.
// DayNight (scripts/daynight.gd) drives every uniform; directions point TOWARD the body.

uniform vec3 top_color : source_color = vec3(0.22, 0.48, 0.86);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.84, 0.95);
uniform vec3 ground_color : source_color = vec3(0.3, 0.42, 0.3);
uniform vec3 sun_dir = vec3(0.4, 0.7, 0.4);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform vec3 moon_dir = vec3(-0.4, -0.7, 0.4);
uniform vec3 moon_color : source_color = vec3(0.85, 0.9, 1.0);
uniform float star_amount = 0.0;
uniform float overcast = 0.0;     // 0 clear .. 1 fully overcast: fades the sun, the moon (DayNight greys the colours)
uniform float flash = 0.0;        // lightning: lights the whole sky for a moment

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	float clear = 1.0 - overcast;
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_color, top_color, pow(clamp(h, 0.0, 1.0), 0.55));
	} else {
		col = mix(horizon_color, ground_color, smoothstep(0.0, 0.25, -h));
	}

	vec3 sd = normalize(sun_dir);
	float sun_cos = dot(d, sd);
	// warm glow around the sun, bigger when it is low
	float low = 1.0 - clamp(sd.y * 1.6, 0.0, 1.0);
	col += sun_color * pow(max(sun_cos, 0.0), 24.0) * (0.25 + 0.5 * low) * smoothstep(-0.25, 0.1, sd.y) * clear;
	col += sun_color * smoothstep(0.9993, 0.9997, sun_cos) * 6.0 * clear;

	vec3 md = normalize(moon_dir);
	float moon_cos = dot(d, md);
	float moon_up = smoothstep(-0.1, 0.1, md.y);
	col += moon_color * pow(max(moon_cos, 0.0), 80.0) * 0.12 * moon_up * clear;
	col = mix(col, moon_color * 1.4, smoothstep(0.99935, 0.9996, moon_cos) * moon_up * clear);

	// stars: a jittered grid on the sphere
	if (star_amount > 0.001 && h > -0.02) {
		vec3 p = d * 140.0;
		vec3 id = floor(p);
		vec3 f = fract(p) - 0.5;
		float r = hash13(id);
		float star = step(0.985, r) * smoothstep(0.28, 0.0, length(f));
		float twinkle = 0.65 + 0.35 * sin(TIME * (1.5 + r * 4.0) + r * 40.0);
		col += vec3(0.9, 0.95, 1.0) * star * twinkle * star_amount * smoothstep(0.0, 0.2, h);
	}
	col += vec3(0.70, 0.78, 1.0) * flash * 0.9;
	COLOR = col;
}
