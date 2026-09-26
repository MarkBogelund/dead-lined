// Max-level presentation: gold recolor with a sweeping diagonal glint and twinkling pixels.
// Driven by TurretBase._set_gold_shine().

group_uniforms gold;
// 0 = normal turret, 1 = fully upgraded gold.
uniform float gold_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 gold_dark : source_color = vec4(0.42, 0.25, 0.04, 1.0);
uniform vec4 gold_light : source_color = vec4(1.0, 0.86, 0.36, 1.0);
// How much of the sprite's own colour is replaced by the gold ramp.
uniform float gold_blend : hint_range(0.0, 1.0) = 0.6;
uniform vec4 shine_color : source_color = vec4(1.0, 0.97, 0.82, 1.0);
uniform float shine_strength : hint_range(0.0, 1.0) = 0.85;
// Width in world pixels of the diagonal glint band.
uniform float shine_width = 2.0;
uniform float shine_speed = 70.0;
uniform float shine_interval = 2.2;
uniform float sparkle_density : hint_range(0.0, 1.0) = 0.05;
uniform float sparkle_speed = 1.3;
group_uniforms;

float gold_shine_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// world_position keeps the effect on the world-pixel grid, including on rotating parts.
vec3 apply_gold_shine(vec3 color, vec2 world_position, float time) {
	if (gold_amount <= 0.0) {
		return color;
	}
	vec2 pixel = floor(world_position);
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 gold = mix(gold_dark.rgb, gold_light.rgb, smoothstep(0.1, 0.9, luminance));
	vec3 golden = mix(color, gold, gold_blend);

	float band_spacing = max(shine_interval * shine_speed, shine_width + 1.0);
	float phase = mod(pixel.x + pixel.y - time * shine_speed, band_spacing);
	float glint = step(phase, shine_width) * shine_strength;

	float seed = gold_shine_hash(pixel);
	float twinkle = step(1.0 - sparkle_density, seed) * step(0.88, fract(time * sparkle_speed + seed * 13.0));
	float sparkle = twinkle * step(0.35, luminance);

	golden = mix(golden, shine_color.rgb, max(glint, sparkle));
	return mix(color, golden, gold_amount);
}
