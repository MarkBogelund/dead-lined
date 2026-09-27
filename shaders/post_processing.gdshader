shader_type canvas_item;

// Composite world-only post-processing. Add future effects here so screen reads chain correctly.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

group_uniforms screen_effects;
uniform float desaturation_amount : hint_range(0.0, 1.0) = 0.0;
uniform float max_desaturation : hint_range(0.0, 1.0) = 0.3;
uniform float darken : hint_range(0.0, 1.0) = 0.1;
group_uniforms;

group_uniforms color_overlay;
uniform vec4 overlay_color : source_color = vec4(0.4, 0.0, 0.0, 1.0);
uniform float overlay_intensity : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luminance), max_desaturation * desaturation_amount);
	color *= 1.0 - darken * desaturation_amount;

	float distance_from_center = length(UV * 2.0 - 1.0);
	float vignette = smoothstep(0.2, 1.3, distance_from_center);
	float overlay_weight = overlay_color.a * vignette * overlay_intensity;
	color = mix(color, overlay_color.rgb, overlay_weight);
	COLOR = vec4(color, 1.0);
}