shader_type canvas_item;

// Fills the texture left-to-right, tinting only its opaque pixels so bevels/transparent corners stay intact.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);
uniform vec2 rect_size = vec2(12.0, 12.0);

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV) * COLOR;
	float filled_columns = floor(progress * rect_size.x + 0.0001);
	float filled = step(floor(local_position.x) + 1.0, filled_columns);
	texture_color.rgb = mix(texture_color.rgb, fill_color.rgb, fill_color.a * filled);
	COLOR = texture_color;
}
