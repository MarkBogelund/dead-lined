@tool
extends Texture2D
class_name CompositeTexture2D

## Draws several textures stacked into one (first layer at the bottom), e.g. a turret body plus its cannon as a
## single shop icon. Offsets are in pixels from the top-left of `size`; everything scales together when stretched.

@export var size := Vector2i(24, 24):
	set(value):
		size = value
		emit_changed()
@export var layers: Array[Texture2D] = []:
	set(value):
		layers = value
		emit_changed()
@export var offsets: Array[Vector2] = []:
	set(value):
		offsets = value
		emit_changed()

func _get_width() -> int:
	return size.x

func _get_height() -> int:
	return size.y

func _has_alpha() -> bool:
	return true

func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return true

func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	_draw_rect(to_canvas_item, Rect2(pos, Vector2(size)), false, modulate, transpose)

func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color, transpose: bool) -> void:
	var scale := rect.size / Vector2(size)
	for i in layers.size():
		var layer := layers[i]
		if not layer:
			continue
		var offset := offsets[i] if i < offsets.size() else Vector2.ZERO
		layer.draw_rect(to_canvas_item, Rect2(rect.position + offset * scale, Vector2(layer.get_size()) * scale), false, modulate, transpose)

func _draw_rect_region(to_canvas_item: RID, rect: Rect2, _src_rect: Rect2, modulate: Color, transpose: bool, _clip_uv: bool) -> void:
	_draw_rect(to_canvas_item, rect, false, modulate, transpose)
