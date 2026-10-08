shader_type canvas_item;
render_mode unshaded;

uniform vec4 shockwave_color : source_color = vec4(0.3, 0.9, 1.0, 0.9);
uniform float current_radius = 0.0;
uniform float ring_thickness = 8.0;
uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 2.0;
uniform float center_line_thickness : hint_range(1.0, 8.0, 1.0) = 1.0;
uniform vec4 center_line_color : source_color = vec4(1.0);
uniform vec2 canvas_size = vec2(240.0, 240.0);
// Partial rings (e.g. Bulwark's shield wave); PI half-angle draws the full ring.
uniform float arc_direction = 0.0;
uniform float arc_half_angle = 3.14159265;

void fragment() {
	vec2 center = canvas_size * 0.5;
	vec2 pixel_position = floor(UV * canvas_size / pixel_size + 0.5) * pixel_size;
	vec2 offset = pixel_position - center;
	// Capsule ends like LaserGraphics: distance to the nearest point on the arc's center line.
	float signed_angle = mod(atan(offset.y, offset.x) - arc_direction + PI, TAU) - PI;
	float closest_angle = arc_direction + clamp(signed_angle, -arc_half_angle, arc_half_angle);
	vec2 closest_point = vec2(cos(closest_angle), sin(closest_angle)) * current_radius;
	float distance_from_ring = length(offset - closest_point);
	float half_thickness = max(ring_thickness * 0.5, pixel_size * 0.5);
	float ring_alpha = 1.0 - step(half_thickness, distance_from_ring);
	float center_line_half_thickness = max(center_line_thickness * pixel_size * 0.5, pixel_size * 0.5);
	float center_line_alpha = 1.0 - step(center_line_half_thickness, distance_from_ring);
	vec3 ring_color = mix(shockwave_color.rgb, center_line_color.rgb, center_line_alpha);
	COLOR = vec4(ring_color, shockwave_color.a * ring_alpha);
}
