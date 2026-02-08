shader_type canvas_item;

uniform float elapsed = 0.0;      // time since slash ended
uniform float shrink_speed = 2.0; // how fast the tail retracts

void fragment() {
    // Preserve the original Line2D color/gradient
    float alpha = COLOR.a * clamp(1.0 - (elapsed * shrink_speed + (1.0 - UV.x)), 0.0, 1.0);
    COLOR.a = alpha;
}
