extends Panel

onready var state = $".."
onready var parser = $"../TextureRect/RunScript"

func push_message(speaker: String, text: String):
	var d = $ScrollContainer/VBoxContainer/Message.duplicate()
	d.get_node("Speaker").bbcode_text = speaker
	d.get_node("Text").bbcode_text = text
	d.visible = true
	var c = $ScrollContainer/VBoxContainer.get_children()
	if c.size() >= 257:
		$ScrollContainer/VBoxContainer.remove_child(c[1])
	$ScrollContainer/VBoxContainer.add_child(d)

func _ready():
	if OS.has_feature("mobile"):
		$"../TextureRect/TextureRect".texture = load("res://gui/textbox_mobile.png")
		$"../TextureRect/Backlog".visible = false
		$"../TextureRect/Organizer".visible = false
		$"../TextureRect/Save".visible = false
		$"../TextureRect/BacklogMobile".visible = true
		$"../HBoxContainer".visible = true
	else:
		$"../TextureRect/Backlog".visible = true
		$"../TextureRect/Organizer".visible = true
		$"../TextureRect/Save".visible = true
		$"../TextureRect/BacklogMobile".visible = false
		$"../HBoxContainer".visible = false
	#var vbox = $ScrollContainer/VBoxContainer
	#var msg = $ScrollContainer/VBoxContainer/Message
	#for i in range(99):
		#var d = $ScrollContainer/VBoxContainer/Message.duplicate()
		#d.get_node("Text").bbcode_text = ""
		#vbox.add_child(d)

func _open_backlog():
	if !parser.stopped_talking or state.has_tag("choice"):
		parser.stop_talking()
		globals.play_sfx("organizer")
		modulate = Color.transparent
		yield(get_tree(), "idle_frame")
		var anim = $"../AnimationPlayer"
		while anim.is_playing():
			yield(anim, "animation_finished")
		anim.play("show_backlog")
		yield(anim, "animation_finished")
		$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scrollbar().max_value
		$ScrollContainer/VBoxContainer.grab_focus()

func _close_backlog():
	globals.play_sfx("back")
	var anim = $"../AnimationPlayer"
	while anim.is_playing():
		yield(anim, "animation_finished")
	anim.play("hide_backlog")
	yield(anim, "animation_finished")
	visible = false
	parser.resume_talking()

func _process(_delta):
	var btn = $"../TextureRect/BacklogMobile"
	if OS.has_feature("mobile"):
		btn.visible = true
		btn.self_modulate.a = 0.9 if btn.is_hovered() else 0.75
	else:
		btn.visible = false
		btn = $"../TextureRect/Backlog"
	if visible and (Input.is_action_just_pressed("backlog") or Input.is_action_just_pressed("ui_cancel")):
		_close_backlog()
