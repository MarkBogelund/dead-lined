@tool
extends Texture2D
class_name TurretIconTexture

## Composites atlas regions and sprite textures into one shop icon, in bottom-to-top order.

@export var size := Vector2i(24, 24):
	set(value):
		size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		emit_changed()

@export var layers: Array[Texture2D] = []:
	set(value):
		layers = value
		emit_changed()

## Pixel offsets from the top-left of the icon canvas; missing entries default to zero.
@export var offsets: Array[Vector2i] = []:
	set(value):
		offsets = value
		emit_changed()

func bake_image() -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for index in layers.size():
		var layer := layers[index]
		if not layer:
			continue
		var source := _get_layer_image(layer)
		if source.is_empty():
			push_error("TurretIconTexture could not read layer %d" % index)
			return null
		if source.is_compressed() and source.decompress() != OK:
			push_error("TurretIconTexture could not decompress layer %d" % index)
			return null
		var offset := offsets[index] if index < offsets.size() else Vector2i.ZERO
		image.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), offset)
	return image

func _get_layer_image(layer: Texture2D) -> Image:
	if layer is AtlasTexture:
		var atlas := layer as AtlasTexture
		if not atlas.atlas:
			return Image.new()
		var image := atlas.atlas.get_image()
		if image.is_empty():
			return image
		return image.get_region(Rect2i(atlas.region))
	return layer.get_image()

func _get_width() -> int:
	return size.x

func _get_height() -> int:
	return size.y

func _has_alpha() -> bool:
	return true

func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return true

func _draw(to_canvas_item: RID, position: Vector2, modulate: Color, transpose: bool) -> void:
	_draw_rect(to_canvas_item, Rect2(position, Vector2(size)), false, modulate, transpose)

func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color, transpose: bool) -> void:
	var scale := rect.size / Vector2(size)
	for index in layers.size():
		var layer := layers[index]
		if not layer:
			continue
		var offset := Vector2(offsets[index]) if index < offsets.size() else Vector2.ZERO
		var layer_rect := Rect2(rect.position + offset * scale, Vector2(layer.get_size()) * scale)
		layer.draw_rect(to_canvas_item, layer_rect, false, modulate, transpose)

func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, _clip_uv: bool) -> void:
	var scale := rect.size / src_rect.size
	for index in layers.size():
		var layer := layers[index]
		if not layer:
			continue
		var offset := Vector2(offsets[index]) if index < offsets.size() else Vector2.ZERO
		var layer_origin := rect.position + (offset - src_rect.position) * scale
		var layer_size := Vector2(layer.get_size()) * scale
		layer.draw_rect(to_canvas_item, Rect2(layer_origin, layer_size), false, modulate, transpose)
