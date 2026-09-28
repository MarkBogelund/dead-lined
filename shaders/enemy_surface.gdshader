shader_type canvas_item;

// Enemy sprite surface, set on the enemy's Visuals node; sprites opt in with use_parent_material.
#include "res://shaders/include/hit_flash.gdshaderinc"

void fragment() {
	COLOR.rgb = apply_hit_flash(COLOR.rgb);
}
