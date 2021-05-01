extends TextureRect

const bgs = {
	theatrum = preload("theatrum.png"),
	querco_office = preload("alba_office.png"),
	garden = preload("garden.png"),
	bad_end = preload("bad_end.png"),
	heaven_gate = preload("heaven_gate.png"),
	sky = preload("sky.png"),
	heaven_castle = preload("heaven_castle.png"),
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
	if texture:
		var s = get_viewport_rect().size.y / texture.get_height()
		rect_position.x = lerp(get_viewport_rect().size.x - texture.get_width() * s, 0, t)
