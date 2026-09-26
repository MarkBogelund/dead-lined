// Damage feedback: blends the whole sprite toward flash_color. Driven by TurretBase._play_hit_flash().

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

vec3 apply_hit_flash(vec3 color) {
	return mix(color, flash_color.rgb, flash_amount);
}
