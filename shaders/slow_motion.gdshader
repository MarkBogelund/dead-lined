shader_type canvas_item;

// Full-screen slow-motion look: desaturates (and slightly darkens) everything drawn below this overlay.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float max_desaturation : hint_range(0.0, 1.0) = 0.85;
uniform float darken : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luminance), max_desaturation * amount);
	COLOR = vec4(color * (1.0 - darken * amount), 1.0);
}
