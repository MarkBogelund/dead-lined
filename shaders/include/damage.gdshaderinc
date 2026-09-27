// Critical-health presentation: recolours the sprite to a pulsing red and glitches scorched pixels in and out.
// Driven by TurretBase._set_critical().

group_uniforms damage;
// 0 = intact, 1 = critically damaged.
uniform float damage_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_dark : source_color = vec4(0.16, 0.03, 0.05, 1.0);
uniform vec4 damage_light : source_color = vec4(0.85, 0.22, 0.18, 1.0);
// How much of the sprite's own colour the red ramp replaces, at the weakest and strongest point of the pulse.
uniform float tint_min : hint_range(0.0, 1.0) = 0.5;
uniform float tint_max : hint_range(0.0, 1.0) = 0.9;
// Full tint pulses per second.
uniform float tint_pulse_speed = 1.2;
uniform float damage_darkness : hint_range(0.0, 1.0) = 0.2;
uniform vec4 crack_color : source_color = vec4(0.08, 0.02, 0.03, 1.0);
// Share of cells that glitch on in any given interval.
uniform float crack_density : hint_range(0.0, 1.0) = 0.12;
// Crack cell size in world pixels; above 1 the cracks clump instead of looking like static.
uniform float crack_size = 2.0;
// Seconds between a cell's chances to glitch on.
uniform float glitch_interval = 0.3;
// Share of that interval a glitched cell stays visible.
uniform float glitch_duty : hint_range(0.0, 1.0) = 0.35;
group_uniforms;

float damage_hash(vec2 p) {
	return fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453);
}

float damage_hash_cycle(vec2 p, float cycle) {
	return fract(sin(dot(vec3(p, cycle), vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// world_position keeps the crack grid on world pixels, including on rotating parts.
vec3 apply_damage(vec3 color, vec2 world_position, float time) {
	if (damage_amount <= 0.0) {
		return color;
	}
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 red = mix(damage_dark.rgb, damage_light.rgb, smoothstep(0.1, 0.9, luminance));
	float tint = mix(tint_min, tint_max, 0.5 + 0.5 * sin(time * tint_pulse_speed * 6.2831853));
	vec3 damaged = mix(color, red, tint) * (1.0 - damage_darkness);

	// Each cell rolls independently per interval, so cracks pop in place instead of drifting across the sprite.
	vec2 cell = floor(world_position / max(crack_size, 1.0));
	float phase = time / max(glitch_interval, 0.01) + damage_hash(cell) * 7.3;
	float glitch = step(1.0 - crack_density, damage_hash_cycle(cell, floor(phase))) * step(fract(phase), glitch_duty);
	damaged = mix(damaged, crack_color.rgb, glitch);
	return mix(color, damaged, damage_amount);
}
