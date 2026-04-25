shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(0.4, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Vignette weight — peaks at screen edges, zero at centre
	float dist     = length(UV * 2.0 - 1.0);
	float vignette = smoothstep(0.2, 1.3, dist);

	COLOR = vec4(overlay_color.rgb, overlay_color.a * vignette * intensity);
}
