shader_type canvas_item;
render_mode unshaded;

// Rotates TEXTURE by nearest-sampling it on the canvas's own pixel grid, so the sprite can point any direction
// without smeared, stretched, or sub-pixel pixels. The canvas is a square centred on the pivot.

uniform float angle = 0.0;
uniform vec2 canvas_size = vec2(64.0);
uniform vec2 sprite_size = vec2(24.0, 5.0);
// Distance from the pivot to the sprite's left edge along the pointing direction.
uniform float start_offset = 8.0;
// Size of one art pixel in screen-space pixels of the canvas.
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 1.0;

varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	vec2 pixel = (floor(UV * canvas_size / pixel_size) + 0.5) * pixel_size - canvas_size * 0.5;
	float c = cos(-angle);
	float s = sin(-angle);
	vec2 local = vec2(pixel.x * c - pixel.y * s, pixel.x * s + pixel.y * c) / pixel_size;
	vec2 sprite_pixel = floor(local - vec2(start_offset / pixel_size, -sprite_size.y * 0.5));
	if (any(lessThan(sprite_pixel, vec2(0.0))) || any(greaterThanEqual(sprite_pixel, sprite_size))) {
		discard;
	}
	COLOR = texture(TEXTURE, (sprite_pixel + 0.5) / sprite_size) * modulate_color;
}
