class_name LoadMenu
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

func _open():
	update_icons()
	$AnimationPlayer.play("show")
	globals.play_sfx("organizer")

func _back():
	$AnimationPlayer.play("hide")
	globals.play_sfx("back")

func _prev_page():
	if page > 0:
		page -= 1
		update_icons()

func _next_page():
	page += 1
	update_icons()

func load_save(save):
	var new_main = preload("res://main.tscn").instance()
	var parser = new_main.get_node("TextureRect/RunScript")
	parser.load_script(save.file)
	parser.start_advancing = false
	get_tree().current_scene.queue_free()
	get_tree().get_root().add_child(new_main)
	get_tree().current_scene = new_main
	new_main.state = save.state
	new_main.vars = save.vars
	new_main.call_stack = save.call_stack
	new_main.speaker_name = save.speaker_name
	new_main.evidence = save.evidence
	new_main.profiles = save.profiles
	new_main.health = save.health
	new_main.seductiometer = save.seductiometer if "seductiometer" in save else 500
	if "choices" in save:
		var arr = ["", save.choices[0]]
		for i in range(1, len(save.choices)):
			arr.push_back(save.choices[i])
			arr.push_back(save.choice_jumps[i - 1])
		new_main.get_node("Choices").show_choices(arr)
	if save.has("inv_id"):
		#new_main.load_inv_new(save.inv_id)
		new_main.inv = save.inv
		new_main.inv.area = save.inv_area
		new_main.inv.examined = save.inv_examined
		new_main.inv.talked = save.inv_talked
		new_main.inv.open_talk = save.inv_open_talk
		new_main.inv.open_move = save.inv_open_move
	parser.cur_text = save.line
	if !save.speaker_name.begins_with("#"):
		parser.get_node("../Label").text = save.speaker_name
	if save.line[0] == "(" and save.line.ends_with(")"):
		parser.self_modulate = Color(0.5, 0.5, 1)
	elif new_main.has_tag("confrontation") or save.speaker_name == "#green":
		parser.self_modulate = Color(0.5, 1, 0.5)
	else:
		parser.self_modulate = Color(1, 1, 1)
	var marker = "_"
	if "loc_marker" in save:
		marker = save.loc_marker
	parser.go_to_save_pos(save.loc + 1, marker)
	if save.bg:
		new_main.bg.cur = new_main.bg.bgs[save.bg]
	new_main.bg.side = save.side
	new_main.bg.t = 0 if save.side else 1
	if save.lchar:
		new_main.lchar = globals.chars[save.lchar.id]
		new_main.lchar.pose = new_main.lchar.poses[save.lchar.pose]
	else:
		new_main.lchar = null
	if save.rchar:
		new_main.rchar = globals.chars[save.rchar.id]
		new_main.rchar.pose = new_main.rchar.poses[save.rchar.pose]
	else:
		new_main.rchar = null
	if "echar" in save:
		for e in range(save.echar.size()):
			if save.echar[e]:
				new_main.echar[e] = globals.chars[save.echar[e].id]
				new_main.echar[e].pose = new_main.echar[e].poses[save.echar[e].pose]
	if save.bgm:
		var bgm_node = new_main.get_node("BGM")
		bgm_node.stream = globals.music[save.bgm]
		bgm_node.play()
		new_main.music_start = OS.get_ticks_usec()
	if save.modulate:
		var parts = save.modulate.split(",")
		new_main.get_node("Control").modulate = Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))

func _load_from(n: int):
	var save = get_save(n + page * 4)
	globals.play_sfx("save_load")
	if save:
		load_save(save)
