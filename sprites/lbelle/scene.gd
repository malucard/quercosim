extends TextureRect

func _process(delta):
	#rect_min_size = get_viewport_rect().size
	rect_size.y = get_viewport_rect().size.y
	rect_size.x = rect_size.y * 0.8
	$Viewport.size = rect_size
