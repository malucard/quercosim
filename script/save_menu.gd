class_name SaveMenu
extends Control

var page = 0
onready var icons = [
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon2,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon3,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon4
]
onready var state = $".."
onready var parser = $"../TextureRect/RunScript"
const empty_tex = preload("res://gui/empty_save_icon.tres")
const tex = preload("res://gui/save_icon.tres")

func get_save(n: int):
	var f = File.new()
	if f.file_exists("user://save" + str(n) + ".json"):
		f.open("user://save" + str(n) + ".json", File.READ)
		var data = parse_json(f.get_as_text())
		f.close()
		return data
	return null

func update_icons():
	for i in range(4):
		var save = get_save(i + page * 4)
		if save:
			icons[i].texture_normal = tex
			icons[i].get_node("Line").text = save.line
			var time = OS.get_datetime_from_unix_time(save.time)
			icons[i].get_node("Time").text = "%04d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
		else:
			icons[i].texture_normal = empty_tex
			icons[i].texture_hover = tex
			icons[i].get_node("Line").text = ""
			icons[i].get_node("Time").text = ""
	$VBoxContainer/TextureRect/PageLabel.text = "Page " + str(page + 1)
	$VBoxContainer/TextureRect/Prev.visible = page > 0

func _ready():
	visible = false
	$VBoxContainer/TextureRect/Overwrite.visible = false

func _open():
	if (!parser.stopped_talking or state.has_tag("choice")) and !parser.running:
		update_icons()
		globals.play_sfx("organizer")
		$AnimationPlayer.play("show")
		parser.stop_talking()

func _back():
	globals.play_sfx("back")
	$AnimationPlayer.play("hide")
	parser.resume_talking()

func _prev_page():
	if page > 0:
		page -= 1
		update_icons()

func _next_page():
	page += 1
	update_icons()

var to_overwrite

func save_char(c):
	if c:
		for k in globals.chars:
			if globals.chars[k] == c:
				for pose in c.poses:
					if c.poses[pose] == c.pose:
						return {id = k, pose = pose}
	return null

func create_save():
	var bg
	var lchar = save_char(state.lchar)
	var rchar = save_char(state.rchar)
	var echar = [save_char(state.echar[0]), save_char(state.echar[1]), save_char(state.echar[2]), save_char(state.echar[3]), save_char(state.echar[4])]
	var bgm
	# find the ids of the textures
	if state.bg.cur:
		for id in state.bg.bgs:
			if state.bg.bgs[id] == state.bg.cur:
				bg = id
				break
	if state.bgm.stream:
		for id in globals.music:
			if globals.music[id] == state.bgm.stream:
				bgm = id
				break
	var m = $"../Control".modulate
	var sp = parser.get_save_pos()
	print("line: " + str(sp[0]) + " marker: " + sp[1])
	var r = {
		file = parser.script_id,
		loc = sp[0],
		loc_marker = sp[1],
		vars = state.vars.duplicate(false),
		line = state.parser.cur_text,
		state = state.state,
		call_stack = state.call_stack.duplicate(false),
		speaker_name = state.speaker_name,
		evidence = state.evidence.duplicate(false),
		profiles = state.profiles.duplicate(false),
		health = state.health,
		seductiometer = state.seductiometer,
		side = state.bg.side,
		bg = bg,
		lchar = lchar,
		rchar = rchar,
		echar = echar,
		bgm = bgm,
		modulate = str(m.r) + "," + str(m.g) + "," + str(m.b) + "," + str(m.a),
		time = OS.get_unix_time()
	}
	if $"../Choices".visible:
		r.choices = $"../Choices".choices
		r.choice_jumps = $"../Choices".jumps
	if !state.inv.empty():
		r.inv = state.inv
		r.inv_id = state.inv.id
		r.inv_area = state.inv.area
		r.inv_examined = state.inv.examined
		r.inv_talked = state.inv.talked
		r.inv_open_talk = state.inv.open_talk
		r.inv_open_move = state.inv.open_move
	return r

func do_save(n: int):
	var f = File.new()
	f.open("user://save" + str(n) + ".json", File.WRITE)
	f.store_string(to_json(create_save()))
	f.close()
	update_icons()

func _save_to(n: int):
	var save = get_save(n + page * 4)
	if save:
		globals.play_sfx("click")
		$VBoxContainer/TextureRect/Overwrite.visible = true
		$VBoxContainer/TextureRect/Overwrite/OldSave/Line.text = save.line
		var time = OS.get_datetime_from_unix_time(save.time)
		$VBoxContainer/TextureRect/Overwrite/OldSave/Time.text = "%04d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
		$VBoxContainer/TextureRect/Overwrite/NewSave/Line.text = state.parser.cur_text
		time = OS.get_datetime()
		$VBoxContainer/TextureRect/Overwrite/NewSave/Time.text = "%04d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
		to_overwrite = n + page * 4
	else:
		globals.play_sfx("save_load")
		do_save(n + page * 4)

func _overwrite_yes():
	globals.play_sfx("save_load")
	do_save(to_overwrite)
	$VBoxContainer/TextureRect/Overwrite.visible = false

func _overwrite_no():
	globals.play_sfx("click")
	$VBoxContainer/TextureRect/Overwrite.visible = false

func _to_title():
	globals.play_sfx("click")
	get_tree().change_scene("res://title_screen.tscn")

func _process(_delta):
	if visible and (Input.is_action_just_pressed("save") or Input.is_action_just_pressed("ui_cancel")):
		_back()
