extends TextureRect

const bgs = {
	theatrum = preload("theatrum.png"),
	querco_office = preload("alba_office.png"),
	garden = preload("garden.png")
}

var t = 1
var side = 0

func _ready():
	state.bg = self
	if state.to_load_bg:
		texture = bgs[state.to_load_bg]
		side = state.to_load_side

func _process(delta: float):
	if side:
		t = max(t - delta * 2, 0)
	else:
		t = min(t + delta * 2, 1)
	var s = get_viewport_rect().size.y / texture.get_height()
	rect_position.x = lerp(get_viewport_rect().size.x - texture.get_width() * s, 0, t)
