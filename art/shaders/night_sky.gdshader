shader_type sky;
// The sky behind the diorama: the zone's own background colour by day, and after dark a sprinkle of stars and the moon.
// It only shows where the world stops (past an edge, or when photo mode swings the camera round), and the game's camera
// never looks above the horizon, so the sky is laid on the screen rather than the world: the camera's own axes
// (SkyAndLight sets cam_*) turn each view ray into a position on the picture, with the moon up in the top corner band
// and the stars all over. Kept very cheap: a hash per pixel for the stars, one disc for the moon. `stars` and `moon_on`
// are 0 by day.
uniform vec3 base_colour : source_color = vec3(0.1, 0.13, 0.22);
uniform vec3 top_colour : source_color = vec3(0.03, 0.04, 0.1);
uniform float stars = 0.0;      // 0..1, how much of the star field shows
uniform float twinkle = 1.0;    // 0 under Reduce Flashing: steady stars
uniform float moon_on = 0.0;    // 0..1
uniform vec2 moon_pos = vec2(0.7, 0.88);  // where the moon sits on the picture: x -1.78..1.78 across, y -1..1 up
uniform float moon_phase = 0.5; // 0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter
uniform vec3 cam_right = vec3(1.0, 0.0, 0.0);
uniform vec3 cam_up = vec3(0.0, 1.0, 0.0);
uniform vec3 cam_fwd = vec3(0.0, 0.0, -1.0);
uniform float half_tan = 0.2679;  // tan of half the camera's vertical field of view

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void sky() {
	float z = dot(EYEDIR, cam_fwd);
	vec2 p = vec2(dot(EYEDIR, cam_right), dot(EYEDIR, cam_up)) / (max(z, 0.05) * half_tan);  // y: -1 bottom, 1 top of the picture
	vec3 col = mix(base_colour, top_colour, stars * smoothstep(-1.0, 1.0, p.y));
	if (stars > 0.0) {
		vec2 uv = p * 17.0;
		vec2 id = floor(uv);
		vec2 f = fract(uv) - 0.5;
		float h = hash12(id);
		if (h > 0.93) {
			vec2 off = (vec2(hash12(id + 7.1), hash12(id + 13.7)) - 0.5) * 0.5;
			float r = mix(0.09, 0.2, hash12(id + 3.3));
			float s = smoothstep(r, 0.0, length(f - off));
			float tw = 1.0 - twinkle * 0.45 * (0.5 + 0.5 * sin(TIME * (1.5 + h * 5.0) + h * 60.0));
			vec3 tint = mix(vec3(0.85, 0.9, 1.0), vec3(1.0, 0.92, 0.78), hash12(id + 21.0));
			col += tint * s * tw * stars * (0.55 + 0.45 * (h - 0.93) * 14.0);
		}
	}
	if (moon_on > 0.0) {
		float radius = 0.07;
		vec2 q = (p - moon_pos) / radius;
		q.x *= 1.0;
		float rr = dot(q, q);
		if (rr < 6.0) {
			col += vec3(0.75, 0.82, 1.0) * smoothstep(6.0, 0.0, rr) * 0.14 * moon_on;
			if (rr < 1.0) {
				vec3 n = vec3(q, sqrt(1.0 - rr));
				float a = moon_phase * 6.28318;
				vec3 light = vec3(sin(a), 0.0, -cos(a));
				float lit = smoothstep(-0.04, 0.06, dot(n, light));
				float maria = 0.86 + 0.14 * hash12(floor(q * 4.0 + 8.0));
				vec3 disc = mix(vec3(0.07, 0.08, 0.12), vec3(0.95, 0.93, 0.82) * maria, lit);  // earthshine on the dark side
				col = mix(col, disc, smoothstep(1.0, 0.92, sqrt(rr)) * moon_on);
			}
		}
	}
	COLOR = col;
}
