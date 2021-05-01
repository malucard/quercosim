extends TextureRect

var anim = "normal"

func _process(_delta):
	rect_size.y = get_viewport_rect().size.y
	rect_size.x = rect_size.y * 0.8
	$Viewport.size = rect_size
	$Viewport/lbelle/AnimationPlayer.play(anim)
	name = "canvas"
