shader_type canvas_item;

// Composite world-only post-processing. Add future effects here so screen reads chain correctly.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

group_uniforms screen_effects;
uniform float desaturation_amount : hint_range(0.0, 1.0) = 0.0;
uniform float max_desaturation : hint_range(0.0, 1.0) = 0.3;
uniform float darken : hint_range(0.0, 1.0) = 0.1;
group_uniforms;

group_uniforms low_capacity;
uniform float danger_amount : hint_range(0.0, 1.0) = 0.0;
uniform float danger_glitch_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float danger_chromatic_aberration : hint_range(0.0, 1.0) = 0.65;
uniform float danger_red_tint : hint_range(0.0, 1.0) = 1.0;
uniform float danger_screen_coverage : hint_range(0.0, 1.0) = 0.54;
group_uniforms;

group_uniforms color_overlay;
uniform vec4 overlay_color : source_color = vec4(0.4, 0.0, 0.0, 1.0);
uniform float overlay_intensity : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

float danger_hash(vec3 value) {
	return fract(sin(dot(value, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float vignette_distance = length(centered) / 1.41421356;
	float effective_coverage = danger_screen_coverage * danger_amount;
	float coverage_start = 1.0 - effective_coverage;
	float coverage_feather = min(0.12, min(effective_coverage, 1.0 - effective_coverage));
	coverage_feather = max(coverage_feather, 2.0 * max(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y));
	float spatial_coverage = smoothstep(coverage_start, coverage_start + coverage_feather, vignette_distance);
	spatial_coverage *= step(0.0001, effective_coverage);
	spatial_coverage = mix(spatial_coverage, 1.0, step(0.9999, effective_coverage));
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float pattern = floor(TIME * 6.0);
	vec2 glitch_cell = floor(SCREEN_UV * screen_size / vec2(12.0, 3.0));
	float cell_seed = danger_hash(vec3(glitch_cell, pattern));
	float effective_glitch = danger_glitch_intensity * danger_amount;
	float glitch_density = mix(0.08, 0.28, effective_glitch);
	float glitch_gate = step(1.0 - glitch_density, cell_seed) * spatial_coverage;
	float glitch_direction = step(0.5, danger_hash(vec3(glitch_cell.yx, pattern + 19.0))) * 2.0 - 1.0;
	vec2 glitch_offset = vec2(glitch_direction * 9.0 * effective_glitch * glitch_gate, 0.0) * SCREEN_PIXEL_SIZE;

	vec2 radial_direction = normalize(centered + vec2(0.0001));
	float effective_chromatic = danger_chromatic_aberration * danger_amount;
	vec2 chromatic_offset = radial_direction * 6.0 * effective_chromatic * spatial_coverage * SCREEN_PIXEL_SIZE;
	vec2 sample_uv = clamp(SCREEN_UV + glitch_offset, vec2(0.0), vec2(1.0));
	float red = texture(screen_texture, clamp(sample_uv + chromatic_offset, vec2(0.0), vec2(1.0))).r;
	float green = texture(screen_texture, sample_uv).g;
	float blue = texture(screen_texture, clamp(sample_uv - chromatic_offset, vec2(0.0), vec2(1.0))).b;
	vec3 color = vec3(red, green, blue);
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	float total_desaturation = clamp(max_desaturation * desaturation_amount + 0.38 * danger_amount * spatial_coverage, 0.0, 1.0);
	color = mix(color, vec3(luminance), total_desaturation);
	color *= 1.0 - darken * desaturation_amount;
	vec3 fully_red = vec3(max(luminance, 0.08), 0.0, 0.0);
	float effective_red_tint = danger_red_tint * danger_amount;
	color = mix(color, fully_red, effective_red_tint * spatial_coverage);

	float vignette = smoothstep(0.2, 1.3, length(centered));
	float overlay_weight = overlay_color.a * vignette * overlay_intensity;
	color = mix(color, overlay_color.rgb, overlay_weight);
	COLOR = vec4(color, 1.0);
}