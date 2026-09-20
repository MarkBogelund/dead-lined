shader_type canvas_item;

uniform vec4 start_color : source_color = vec4(0.18, 0.75, 0.65, 1.0);
uniform vec4 end_color : source_color = vec4(0.95, 0.32, 0.24, 1.0);
uniform float gradient_steps : hint_range(2.0, 32.0, 1.0) = 12.0;
uniform float control_width : hint_range(1.0, 1024.0, 1.0) = 264.0;

varying float local_x;

void vertex() {
	local_x = VERTEX.x;
}

void fragment() {
	float step_count = max(gradient_steps - 1.0, 1.0);
	float horizontal_position = clamp(local_x / max(control_width, 1.0), 0.0, 1.0);
	float gradient_position = floor(horizontal_position * step_count + 0.5) / step_count;
	vec4 gradient_color = mix(start_color, end_color, gradient_position);

	COLOR = vec4(gradient_color.rgb, gradient_color.a * COLOR.a);
}