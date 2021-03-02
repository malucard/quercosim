extends Control

var page = 0
onready var icons = [
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon2,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon3,
	$VBoxContainer/TextureRect/VBoxContainer/SaveIcon4
]
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
	update_icons()
	$AnimationPlayer.play("show")
	state.play_sfx("organizer")

func _back():
	$AnimationPlayer.play("hide")
	state.play_sfx("back")

func _prev_page():
	if page > 0:
		page -= 1
		update_icons()

func _next_page():
	page += 1
	update_icons()

var to_overwrite

func do_save(n: int):
	var f = File.new()
	f.open("user://save" + str(n) + ".json", File.WRITE)
	var bg
	var lchar
	var rchar
	var bgm
	# find the ids of the textures
	if state.bg.texture:
		for id in state.bg.bgs:
			if state.bg.bgs[id] == state.bg.texture:
				bg = id
				break
	if state.lchar:
		for ch in state.chars:
			if state.chars[ch] == state.lchar:
				var found = false
				for pose in state.lchar.poses:
					if state.lchar.poses[pose] == state.lchar.pose:
						lchar = {id = ch, pose = pose}
						found = true
						break
				if found:
					break
	if state.rchar:
		for ch in state.chars:
			if state.chars[ch] == state.rchar:
				var found = false
				for pose in state.rchar.poses:
					if state.rchar.poses[pose] == state.rchar.pose:
						rchar = {id = ch, pose = pose}
						found = true
						break
				if found:
					break
	if state.bgm.stream:
		for id in state.music:
			if state.music[id] == state.bgm.stream:
				bgm = id
				break
	f.store_string(to_json({
		loc = state.parser.get_save_pos(),
		vars = state.vars,
		line = state.parser.cur_text,
		green_text = state.green_text,
		in_confrontation = state.in_confrontation,
		first_statement = state.first_statement,
		last_statement = state.last_statement,
		call_stack = state.call_stack,
		speaker_name = state.speaker_name,
		evidence = state.evidence,
		profiles = state.profiles,
		health = state.health,
		side = state.bg.side,
		bg = bg,
		lchar = lchar,
		rchar = rchar,
		bgm = bgm,
		modulate = $"../Control".modulate,
		time = OS.get_unix_time()
	}))
	f.close()
	update_icons()

func _save_to(n: int):
	var save = get_save(n + page * 4)
	if save:
		state.play_sfx("click")
		$VBoxContainer/TextureRect/Overwrite.visible = true
		$VBoxContainer/TextureRect/Overwrite/OldSave/Line.text = save.line
		var time = OS.get_datetime_from_unix_time(save.time)
		$VBoxContainer/TextureRect/Overwrite/OldSave/Time.text = "%04d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
		$VBoxContainer/TextureRect/Overwrite/NewSave/Line.text = state.parser.cur_text
		time = OS.get_datetime()
		$VBoxContainer/TextureRect/Overwrite/NewSave/Time.text = "%04d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
		to_overwrite = n + page * 4
	else:
		state.play_sfx("save_load")
		do_save(n + page * 4)

func _overwrite_yes():
	state.play_sfx("save_load")
	do_save(to_overwrite)
	$VBoxContainer/TextureRect/Overwrite.visible = false

func _overwrite_no():
	state.play_sfx("click")
	$VBoxContainer/TextureRect/Overwrite.visible = false

func _to_title():
	state.play_sfx("click")
	state.reset()
	get_tree().change_scene("res://title_screen.tscn")
