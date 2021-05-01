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

func _load_from(n: int):
	var save = get_save(n + page * 4)
	if save:
		state.play_sfx("save_load")
		state.reset()
		state.to_load = save.loc
		state.vars = save.vars
		state.green_text = save.green_text
		state.in_confrontation = save.in_confrontation
		state.first_statement = save.first_statement
		state.last_statement = save.last_statement
		state.call_stack = save.call_stack
		state.speaker_name = save.speaker_name
		state.evidence = save.evidence
		state.profiles = save.profiles
		state.health = save.health
		if save.bg:
			state.to_load_bg = save.bg
		else:
			state.to_load_bg = null
		state.to_load_side = save.side
		if save.lchar:
			state.lchar = state.chars[save.lchar.id]
			state.lchar.pose = state.lchar.poses[save.lchar.pose]
		else:
			state.lchar = null
		if save.rchar:
			state.rchar = state.chars[save.rchar.id]
			state.rchar.pose = state.rchar.poses[save.rchar.pose]
		else:
			state.rchar = null
		if save.bgm:
			state.to_load_bgm = save.bgm
		else:
			state.to_load_bgm = null
		if save.modulate:
			var parts = save.modulate.split(",")
			state.to_load_modulate = Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))
		get_tree().change_scene("res://main.tscn")
