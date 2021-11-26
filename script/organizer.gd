extends Control

onready var state = $".."
onready var parser = $"../TextureRect/RunScript"

var detail = false
var selected
var selected_i
var page = 0
var mode = 0 # evidence or profiles

func _ready():
	visible = false
	for c in $VBoxContainer/NinePatchRect/GridContainer.get_children():
		c.connect("mouse_entered", self, "_hover_item", [c])
		c.mouse_default_cursor_shape = CURSOR_POINTING_HAND

func _hover_item(c):
	if page * 10 + int(c.name.substr(13)) - 1 < len(state.evidence if mode == 0 else state.profiles):
		c.grab_focus()
		selected_i = page * 10 + int(c.name.substr(13)) - 1
		update_selected()

func _open():
	if !parser.stopped_talking or state.has_tag("choice"):
		$Present.visible = false
		parser.stop_talking()
		globals.play_sfx("organizer")
		$AnimationPlayer.play("show")
		$Back.visible = true
		$VBoxContainer/NinePatchRect/GridContainer/TextureButton1.grab_focus()
		var prev_detail = detail
		_select(0)
		detail = prev_detail

func _open_present():
	if !parser.stopped_talking or state.has_tag("choice"):
		$Present.visible = true
		parser.stop_talking()
		globals.play_sfx("organizer")
		$AnimationPlayer.play("show")
		$Back.visible = state.has_tag("confrontation") or !$Present.visible
		$VBoxContainer/NinePatchRect/GridContainer/TextureButton1.grab_focus()
		var prev_detail = detail
		_select(0)
		detail = prev_detail

func _present_pressed():
	if selected:
		visible = false
		detail = false
		state.run_command("present " + selected.id)
		parser.resume_talking()
		#$"../TextureRect/RunScript".next()

func _switch_mode():
	mode = 1 if mode == 0 else 0
	var count = len(state.evidence) if mode == 0 else len(state.profiles)
	if count == 0:
		selected = null
		selected_i = null
		page = 0
		detail = false
	elif !selected:
		selected_i = 0
		update_selected()
	elif selected and selected_i >= count:
		selected_i = count - 1
		page = selected_i / 10
		update_selected()
	else:
		update_selected()
	globals.play_sfx("organizer")

func update_selected():
	if mode == 0:
		if selected_i >= len(state.evidence):
			selected_i = null
			selected = null
		else:
			selected = state.evidence[selected_i]
	elif mode == 1:
		if selected_i >= len(state.profiles):
			selected_i = null
			selected = null
		else:
			selected = state.profiles[selected_i]
	#if selected and !$VBoxContainer/NinePatchRect/GridContainer.is_a_parent_of(get_focus_owner()):
		#$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(selected_i % 10 + 1)).grab_focus()

var org_empty = load("res://gui/organizer/empty.png")
func _process(_delta: float):
	if !visible:
		return
	if Input.is_action_just_pressed("present") and $Present.visible:
		_present_pressed()
	if mode == 0:
		$VBoxContainer/TextureRect.texture = load("res://gui/organizer/evidence.png")
		$VBoxContainer/TextureRect/Switch.texture_normal = load("res://gui/organizer/profiles.png")
	elif mode == 1:
		$VBoxContainer/TextureRect.texture = load("res://gui/organizer/profiles.png")
		$VBoxContainer/TextureRect/Switch.texture_normal = load("res://gui/organizer/evidence.png")
	if selected:
		if $VBoxContainer/NinePatchRect.is_a_parent_of(get_focus_owner()) or !$VBoxContainer.is_a_parent_of(get_focus_owner()):
			$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(selected_i % 10 + 1)).grab_focus()
		else:
			selected = null
			selected_i = null
	else:
		if $VBoxContainer/NinePatchRect/GridContainer.is_a_parent_of(get_focus_owner()):
			_hover_item(get_focus_owner())
	if selected:
		$VBoxContainer/NinePatchRect2/Label.text = selected.name if mode == 0 else globals.profile_data[selected.id].name
		$VBoxContainer/NinePatchRect/Selector.visible = true
		$VBoxContainer/NinePatchRect/Selector.margin_left = -424 + (selected_i % 5) * 168
		$VBoxContainer/NinePatchRect/Selector.margin_right = -248 + (selected_i % 5) * 168
		$VBoxContainer/NinePatchRect/Selector.margin_top = 4 if selected_i % 10 / 5 < 1 else 172
		$VBoxContainer/NinePatchRect/Selector.margin_bottom = 180 if selected_i % 10 / 5 < 1 else 348
	else:
		detail = false
		$VBoxContainer/NinePatchRect2/Label.text = ""
		$VBoxContainer/NinePatchRect/Selector.visible = false
	if detail:
		$VBoxContainer/NinePatchRect/Selector.visible = false
		if mode == 0:
			$VBoxContainer/NinePatchRect/Detail.texture = globals.all_evidence[selected.id]
			$VBoxContainer/NinePatchRect/DescBg/Desc.bbcode_text = selected.desc
		elif mode == 1:
			$VBoxContainer/NinePatchRect/Detail.texture = globals.all_profiles[globals.profile_data[selected.id].icon]
			var data = globals.profile_data[selected.id]
			$VBoxContainer/NinePatchRect/DescBg/Desc.bbcode_text = "Age: " + data.age + "\nGender: " + data.gender + "\n" + data.desc
		$VBoxContainer/NinePatchRect/GridContainer.visible = false
		$VBoxContainer/NinePatchRect/Detail.visible = true
		$VBoxContainer/NinePatchRect/DescBg.visible = true
		$VBoxContainer/NinePatchRect/Left.visible = selected_i != 0
		$VBoxContainer/NinePatchRect/Right.visible = selected_i < len(state.evidence if mode == 0 else state.profiles) - 1
	else:
		$VBoxContainer/NinePatchRect/Detail.visible = false
		$VBoxContainer/NinePatchRect/DescBg.visible = false
		$VBoxContainer/NinePatchRect/GridContainer.visible = true
		$VBoxContainer/NinePatchRect/Left.visible = page != 0
		$VBoxContainer/NinePatchRect/Right.visible = page * 10 + 10 < len(state.evidence if mode == 0 else state.profiles)
		var count
		if mode == 0:
			count = clamp(state.evidence.size() - page * 10, 0, 10)
		elif mode == 1:
			count = clamp(state.profiles.size() - page * 10, 0, 10)
		for i in range(count):
			if mode == 0:
				$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = globals.all_evidence[state.evidence[i + page * 10].id]
			elif mode == 1:
				$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = globals.all_profiles[globals.profile_data[state.profiles[i + page * 10].id].icon]
		for i in range(count, 10):
			$VBoxContainer/NinePatchRect/GridContainer.get_node("TextureButton" + str(i + 1)).texture_normal = org_empty
	if visible:
		var count = len(state.evidence) if mode == 0 else len(state.profiles)
		if Input.is_action_just_pressed("press"):
			_switch_mode()
		elif Input.is_action_just_pressed("organizer") or Input.is_action_just_pressed("ui_cancel"):
			_back()
		elif Input.is_action_just_pressed("ui_left") and selected:
			if detail:
				_left()
			elif selected_i > 0:
				if selected_i % 5 == 0:
					if page > 0:
						selected_i -= 6
						page -= 1
						update_selected()
						#globals.play_sfx("cursor_ffviii")
				else:
					selected_i -= 1
					update_selected()
					#globals.play_sfx("cursor_ffviii")
		elif Input.is_action_just_pressed("ui_right") and selected:
			if detail:
				_right()
			elif selected_i % 5 == 4:
				if selected_i + 5 < count:
					selected_i += 6
					page += 1
					update_selected()
					#globals.play_sfx("cursor_ffviii")
				elif selected_i % 10 == 9 and selected_i + 1 < count:
					selected_i += 1
					page += 1
					update_selected()
					#globals.play_sfx("cursor_ffviii")
			elif selected_i + 1 < count:
				selected_i += 1
				update_selected()
				#globals.play_sfx("cursor_ffviii")
		elif !detail and selected:
			if Input.is_action_just_pressed("ui_down"):
				if selected_i % 10 < 5 and selected_i + 5 < count:
					selected_i += 5
					update_selected()
					#globals.play_sfx("cursor_ffviii")
			elif Input.is_action_just_pressed("ui_up"):
				if selected_i % 10 > 4 and selected_i - 5 >= 0:
					selected_i -= 5
					update_selected()
					#globals.play_sfx("cursor_ffviii")
			elif Input.is_action_just_pressed("ui_accept"):
				detail = true
				$Back.visible = true
				globals.play_sfx("click")

func close():
	$AnimationPlayer.play("hide")
	parser.resume_talking()

func _back():
	if detail:
		detail = false
		$Back.visible = state.has_tag("confrontation") or !$Present.visible
		globals.play_sfx("back")
	elif !$Present.visible or state.has_tag("confrontation"):
		close()
		globals.play_sfx("back")

func _select(which: int):
	if len(state.evidence if mode == 0 else state.profiles) > which + page * 10:
		selected_i = which + page * 10
		update_selected()
		detail = true
		$Back.visible = true
		globals.play_sfx("click")

func _right():
	if detail:
		if selected_i + 1 < len(state.evidence if mode == 0 else state.profiles):
			selected_i += 1
			if selected_i == 0:
				page += 1
			if mode == 0:
				selected = state.evidence[selected_i]
			elif mode == 1:
				selected = state.profiles[selected_i]
			#globals.play_sfx("cursor_ffviii")
	elif page <= len(state.evidence if mode == 0 else state.profiles) / 10:
		page += 1
		globals.play_sfx("click")

func _left():
	if detail:
		if selected_i > 0:
			selected_i -= 1
			update_selected()
			#globals.play_sfx("cursor_ffviii")
	elif page > 0:
		page -= 1
		globals.play_sfx("click")
