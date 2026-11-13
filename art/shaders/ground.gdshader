shader_type spatial;
// The zone's ground: vertex colour like the solid material, plus weather. Vertex alpha 0 marks hard
// surfaces (roads, cobbles, platforms) that darken and shine when `wet`; `frost` rimes the flat tops.
// Medium and High graphics (SkyAndLight.apply_quality) add three touches, all 0 on Low so it looks as it always has:
// `ao` darkens the ground at the foot of walls and banks (UV.x, baked per corner by ZoneBuilder), `detail` mottles
// soft ground (UV.y: 1 grass, 0.5 paths and sand, 0 paving and floors) and `clouds` drifts cloud shadows over it.
uniform float wet = 0.0;
uniform float frost = 0.0;
uniform float ao = 0.0;
uniform float detail = 0.0;
uniform float clouds = 0.0;
// The season on the soft ground (Seasonal.tint_ground sets these from the date, as it does for the trees): spring freshens
// the grass and scatters daisies, autumn burns it to ochre, winter bleaches it pale. Roads and floors (UV.y 0) never change.
uniform float spring = 0.0;
uniform float autumn = 0.0;
uniform float winter = 0.0;
uniform vec2 cloud_drift = vec2(0.35, 0.12);  // world units a second

varying float up;
varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	up = (MODEL_MATRIX * vec4(NORMAL, 0.0)).y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = COLOR.rgb;  // vertex colours arrive linear here, as the solid material sees them
	float hard = 1.0 - COLOR.a;
	float level = smoothstep(0.6, 0.95, up);
	if (detail > 0.0) {
		// soft ground: broad patches of lusher and drier growth, then a fine speckle of tufts and clover
		float soft = UV.y * level;
		float patches = vnoise(world_pos.xz * 0.55) * 0.65 + vnoise(world_pos.xz * 1.7) * 0.35;
		float speck = vnoise(world_pos.xz * 9.0);
		vec3 lush = c * vec3(0.84, 0.95, 0.84);
		vec3 dry = c * vec3(1.06, 1.02, 0.84);
		c = mix(c, mix(lush, dry, smoothstep(0.3, 0.75, patches)), soft * detail * 0.45);
		c *= 1.0 + (speck - 0.5) * 0.16 * soft * detail;
	}
	float grass = smoothstep(0.7, 1.0, UV.y) * level;
	if (grass > 0.0) {
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, c * vec3(0.9, 1.12, 0.78) + vec3(0.0, 0.025, 0.0), spring * 0.45 * grass);
		c = mix(c, vec3(0.62, 0.4, 0.14) * (0.55 + lum * 1.7), autumn * 0.7 * grass);
		c = mix(c, vec3(lum) * vec3(1.12, 1.16, 1.18) + vec3(0.07, 0.075, 0.085), winter * 0.55 * grass);
		if (spring > 0.0 && detail > 0.0) {
			float daisy = step(0.985, vnoise(world_pos.xz * 7.3 + 11.0));
			c = mix(c, mix(vec3(0.95, 0.95, 0.88), vec3(0.97, 0.85, 0.3), step(0.5, hash(floor(world_pos.xz * 7.3)))), daisy * spring * grass * 0.7);
		}
	}
	if (ao > 0.0) {
		float occ = smoothstep(0.0, 1.0, UV.x);
		c *= 1.0 - occ * ao * 0.42;
	}
	c *= 1.0 - wet * (0.12 + 0.24 * hard);
	c = mix(c, vec3(0.6, 0.66, 0.74), frost * level * (0.38 - 0.14 * hard));
	if (clouds > 0.0) {
		vec2 cp = world_pos.xz * 0.07 + TIME * cloud_drift * 0.07;
		float cloud = smoothstep(0.52, 0.78, vnoise(cp) * 0.7 + vnoise(cp * 2.3 + 4.1) * 0.3);
		c *= 1.0 - cloud * clouds * 0.15;
	}
	ALBEDO = c;
	ROUGHNESS = mix(1.0, 0.32, wet * hard);
	SPECULAR = 0.55 * wet * hard;
}
