shader_type canvas_item;

uniform vec4 start_color : source_color = vec4(0.28, 0.70, 0.67, 1.0);
uniform vec4 end_color : source_color = vec4(0.61, 0.85, 0.72, 1.0);
uniform float pulse_speed : hint_range(0.0, 128.0, 1.0) = 24.0;
uniform float pulse_width : hint_range(8.0, 512.0, 1.0) = 128.0;
uniform float gradient_steps : hint_range(2.0, 32.0, 1.0) = 8.0;

varying float local_x;

void vertex() {
	local_x = VERTEX.x;
}

void fragment() {
	float wave = 1.0 - abs(fract((local_x - TIME * pulse_speed) / pulse_width) * 2.0 - 1.0);
	float step_count = gradient_steps - 1.0;
	float gradient_position = floor(wave * step_count + 0.5) / step_count;
	vec4 color = mix(start_color, end_color, gradient_position);
	COLOR = vec4(color.rgb, color.a * COLOR.a);
}