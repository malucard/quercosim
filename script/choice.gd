extends VBoxContainer

var jumps = [null, null, null, null]
func _ready():
	visible = false

func show_choices(parts):
	visible = true
	$TextureButton.visible = true
	$TextureButton/Label.text = parts[1]
	if parts.size() > 2:
		$TextureButton2.visible = true
		$TextureButton2/Label.text = parts[2]
		jumps[0] = parts[3]
		if parts.size() > 4:
			$TextureButton3.visible = true
			$TextureButton3/Label.text = parts[4]
			jumps[1] = parts[5]
			if parts.size() > 6:
				$TextureButton4.visible = true
				$TextureButton4/Label.text = parts[6]
				jumps[2] = parts[7]
			else:
				$TextureButton4.visible = false
		else:
			$TextureButton4.visible = false
			$TextureButton3.visible = false
	else:
		$TextureButton4.visible = false
		$TextureButton3.visible = false
		$TextureButton2.visible = false
	state.parser.stop_talking()

func _pressed(which: int):
	state.play_sfx("next")
	if which != -1:
		state.parser.go_to(state.parser.gscript.find("{label " + jumps[which], state.parser.pos))
	state.parser.resume_talking()
	visible = false
	$TextureButton.visible = false
	$TextureButton2.visible = false
	$TextureButton3.visible = false
	$TextureButton4.visible = false
