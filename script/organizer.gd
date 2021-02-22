extends TextureRect

var detail = false
var selected

func _open():
	visible = true
	state.parser.stop_talking()
	state.play_sfx("organizer")

func _process(delta: float):
	if detail:
		$VBoxContainer/NinePatchRect2/Label.text = selected.name
		$VBoxContainer/NinePatchRect/DescBg/Desc.bbcode_text = selected.desc
		$VBoxContainer/NinePatchRect/Detail.texture = selected.texture
		$VBoxContainer/NinePatchRect/GridContainer.visible = false
		$VBoxContainer/NinePatchRect/Detail.visible = true
		$VBoxContainer/NinePatchRect/DescBg.visible = true
	else:
		$VBoxContainer/NinePatchRect/Detail.visible = false
		$VBoxContainer/NinePatchRect/DescBg.visible = false
		$VBoxContainer/NinePatchRect/GridContainer.visible = true
		for i in range(min(state.evidence.size(), 8)):
			$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = state.evidence[i].texture

func _back():
	if detail:
		detail = false
	else:
		visible = false
		state.parser.resume_talking()
	state.play_sfx("back")

func _select(which: int):
	if state.evidence.size() > which:
		selected = state.evidence[which]
		detail = true
		state.play_sfx("click")
