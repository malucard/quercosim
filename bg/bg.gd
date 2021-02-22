extends TextureRect

const bgs = {
	theatrum = preload("theatrum.png"),
	querco_office = preload("alba_office.png"),
	garden = preload("garden.png")
}

var t = 1
var side = 0

func lint(a, b, t):
	return a + (b - a) * t

func _ready():
	state.bg = self

func _process(delta: float):
	if side:
		t = max(t - delta * 2, 0)
	else:
		t = min(t + delta * 2, 1)
	var s = get_viewport_rect().size.y / texture.get_height()
	rect_position.x = lint(get_viewport_rect().size.x - texture.get_width() * s, 0, t)
