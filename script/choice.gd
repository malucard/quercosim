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
	$Button.visible = true
	$Button.text = parts[1]
	choices.push_back(parts[1])
	if parts.size() > 2:
		$Button2.visible = true
		$Button2.text = parts[2]
		jumps[0] = parts[3]
		choices.push_back(parts[2])
		if parts.size() > 4:
			$Button3.visible = true
			$Button3.text = parts[4]
			jumps[1] = parts[5]
			choices.push_back(parts[4])
			if parts.size() > 6:
				$Button4.visible = true
				$Button4.text = parts[6]
				jumps[2] = parts[7]
				choices.push_back(parts[6])
				if parts.size() > 8:
					$Button5.visible = true
					$Button5.text = parts[8]
					jumps[3] = parts[9]
					choices.push_back(parts[8])
				else:
					$Button5.visible = false
			else:
				$Button5.visible = false
				$Button4.visible = false
		else:
			$Button5.visible = false
			$Button4.visible = false
			$Button3.visible = false
	else:
		$Button5.visible = false
		$Button4.visible = false
		$Button3.visible = false
		$Button2.visible = false
	parser.stop_talking()

func _process(_delta):
	$"../ChoicesBG".visible = visible
	var s = get_minimum_size()
	$"../ChoicesBG".rect_position = rect_position + rect_size / 2 - s / 2 - Vector2(32, 8)
	$"../ChoicesBG".rect_size = s + Vector2(64, 16)
	if visible and !$"../Backlog".visible and !$"../Organizer".visible and !$"../SaveMenu".visible:
		if !$Button.has_focus() and !$Button2.has_focus() and !$Button3.has_focus() and !$Button4.has_focus() and !$Button5.has_focus():
			if Input.is_action_just_pressed("ui_down"):
				$Button.grab_focus()
			elif Input.is_action_just_pressed("ui_up"):
				if $Button5.visible:
					$Button5.grab_focus()
				elif $Button4.visible:
					$Button4.grab_focus()
				elif $Button3.visible:
					$Button3.grab_focus()
				elif $Button2.visible:
					$Button2.grab_focus()
				elif $Button.visible:
					$Button.grab_focus()

func _pressed(which: int):
	globals.play_sfx("next")
	if which != -1:
		if jumps[which] == "title_screen":
			state.run_command("title_screen")
		elif jumps[which][0] == "<":
			parser.go_to(state.find_command_behind("label " + jumps[which].substr(1)))
		else:
			parser.go_to(state.find_command_ahead("label " + jumps[which]))
	parser.resume_talking(true)
	visible = false
	$Button.visible = false
	$Button2.visible = false
	$Button3.visible = false
	$Button4.visible = false
	$Button5.visible = false
	if state.has_tag("show_seduction"):
		state.state = State.STATE_SEDUCTION_DIALOGUE
	else:
		state.state = State.STATE_DIALOGUE
