extends Control

onready var state = $".."
onready var parser = $"../TextureRect/RunScript"

var detail = false
var selected
var selected_i
var page = 0

func _ready():
	visible = false

func _open():
	if !parser.stopped_talking or state.has_tag("choice"):
		$Present.visible = false
		parser.stop_talking()
		globals.play_sfx("organizer")
		$AnimationPlayer.play("show")
		$Back.visible = true
		$VBoxContainer/NinePatchRect/GridContainer/TextureButton1.grab_focus()

func _open_present():
	if !parser.stopped_talking or state.has_tag("choice"):
		$Present.visible = true
		parser.stop_talking()
		globals.play_sfx("organizer")
		$AnimationPlayer.play("show")
		$Back.visible = state.has_tag("confrontation")
		$VBoxContainer/NinePatchRect/GridContainer/TextureButton1.grab_focus()

func _present_pressed():
	if selected:
		visible = false
		detail = false
		state.run_command("present " + selected.id)
		parser.resume_talking()
		#$"../TextureRect/RunScript".next()

func _process(_delta: float):
	if detail:
		$VBoxContainer/NinePatchRect2/Label.text = selected.name
		$VBoxContainer/NinePatchRect/DescBg/Desc.bbcode_text = selected.desc
		$VBoxContainer/NinePatchRect/Detail.texture = globals.all_evidence[selected.id]
		$VBoxContainer/NinePatchRect/GridContainer.visible = false
		$VBoxContainer/NinePatchRect/Detail.visible = true
		$VBoxContainer/NinePatchRect/DescBg.visible = true
		$VBoxContainer/NinePatchRect/Left.visible = selected_i != 0
		$VBoxContainer/NinePatchRect/Right.visible = selected_i < state.evidence.size() - 1
	else:
		$VBoxContainer/NinePatchRect/Detail.visible = false
		$VBoxContainer/NinePatchRect/DescBg.visible = false
		$VBoxContainer/NinePatchRect/GridContainer.visible = true
		$VBoxContainer/NinePatchRect/Left.visible = page != 0
		$VBoxContainer/NinePatchRect/Right.visible = page * 8 + 8 < state.evidence.size()
		var count = min(state.evidence.size() - page * 8, 8)
		for i in range(count):
			$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = globals.all_evidence[state.evidence[i + page * 8].id]
		for i in range(count, 8):
			$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = preload("res://gui/organizer/empty.png")
	if visible and (Input.is_action_just_pressed("organizer") or Input.is_action_just_pressed("ui_cancel")):
		_back()

func _back():
	if detail:
		detail = false
		globals.play_sfx("back")
	elif !$Present.visible or ($Present.visible and state.has_tag("confrontation")):
		$AnimationPlayer.play("hide")
		parser.resume_talking()
		globals.play_sfx("back")

func _select(which: int):
	if state.evidence.size() > which + page * 8:
		selected_i = which + page * 8
		selected = state.evidence[selected_i]
		detail = true
		globals.play_sfx("click")

func _right():
	if detail:
		selected_i += 1
		selected = state.evidence[selected_i]
	else:
		page += 1
	globals.play_sfx("click")

func _left():
	if detail:
		selected_i -= 1
		selected = state.evidence[selected_i]
	else:
		page -= 1
	globals.play_sfx("click")
