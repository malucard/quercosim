extends VBoxContainer

onready var state = $".."
onready var parser = $"../TextureRect/RunScript"

var choices = []
var jumps = [null, null, null, null]
func _ready():
	visible = false

func show_choices(parts):
	visible = true
	choices.clear()
	$TextureButton.visible = true
	$TextureButton/Label.text = parts[1]
	choices.push_back(parts[1])
	if parts.size() > 2:
		$TextureButton2.visible = true
		$TextureButton2/Label.text = parts[2]
		jumps[0] = parts[3]
		choices.push_back(parts[2])
		if parts.size() > 4:
			$TextureButton3.visible = true
			$TextureButton3/Label.text = parts[4]
			jumps[1] = parts[5]
			choices.push_back(parts[4])
			if parts.size() > 6:
				$TextureButton4.visible = true
				$TextureButton4/Label.text = parts[6]
				jumps[2] = parts[7]
				choices.push_back(parts[6])
				if parts.size() > 8:
					$TextureButton5.visible = true
					$TextureButton5/Label.text = parts[8]
					jumps[3] = parts[9]
					choices.push_back(parts[8])
				else:
					$TextureButton5.visible = false
			else:
				$TextureButton5.visible = false
				$TextureButton4.visible = false
		else:
			$TextureButton5.visible = false
			$TextureButton4.visible = false
			$TextureButton3.visible = false
	else:
		$TextureButton5.visible = false
		$TextureButton4.visible = false
		$TextureButton3.visible = false
		$TextureButton2.visible = false
	parser.stop_talking()

func _pressed(which: int):
	globals.play_sfx("next")
	if which != -1:
		if jumps[which][0] == "<":
			parser.go_to(state.find_command_behind("label " + jumps[which].substr(1)))
		else:
			parser.go_to(state.find_command_ahead("label " + jumps[which]))
	parser.resume_talking(true)
	visible = false
	$TextureButton.visible = false
	$TextureButton2.visible = false
	$TextureButton3.visible = false
	$TextureButton4.visible = false
	if state.has_tag("show_seduction"):
		state.state = State.STATE_SEDUCTION_DIALOGUE
	else:
		state.state = State.STATE_DIALOGUE
