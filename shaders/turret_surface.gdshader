shader_type canvas_item;

// Turret sprite surface. Each effect owns its uniforms and logic in its include.
#include "res://shaders/include/gold_shine.gdshaderinc"
#include "res://shaders/include/hit_flash.gdshaderinc"

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 color = COLOR;
	color.rgb = apply_gold_shine(color.rgb, world_position, TIME);
	color.rgb = apply_hit_flash(color.rgb);
	COLOR = color;
}