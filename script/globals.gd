extends Node

onready var chars = {
	querco = char_querco,
	quercos = char_querco,
	quercus = char_querco,
	alba = char_querco,
	obama = char_obama,
	barack = char_obama,
	deid = char_deid,
	mann = char_deid,
	colias = char_colias,
	palaeno = char_colias,
	lbelle = char_lbelle,
	"l'belle": char_lbelle,
	florent = char_lbelle,
	sherlock = char_sherlock,
	holmes = char_sherlock,
	mila = char_mila,
	nate = char_nate,
	protagonist = char_protagonist,
	manny = char_manny,
	coachen = char_manny,
	thalassa = char_thalassa,
	shelock = char_shelock,
	sydney = char_sydney,
	pichuis = char_pichuis,
	blaise = char_blaise,
	dhar = char_dhar,
	mack = char_mack,
}

const music_querco = preload("res://sounds/music/querco.ogg")
const music_embassy = preload("res://sounds/music/colias.ogg")
const music_reminiscence_torn = preload("res://sounds/music/reminiscence_torn.ogg")
const music_reminiscence_academy = preload("res://sounds/music/reminiscence_academy.ogg")
const music_solution = preload("res://sounds/music/solution.ogg")
const music_phoenix = preload("res://sounds/music/phoenix.ogg")
var music = {
	querco = music_querco,
	quercos = music_querco,
	quercus = music_querco,
	alba = music_querco,
	surpass = music_querco,
	reminiscence_torn = music_reminiscence_torn,
	reminiscence_academy = music_reminiscence_academy,
	bad_end = music_reminiscence_academy, #preload("res://sounds/music/bad_end.ogg"),
	crazy_colias = preload("res://sounds/music/crazycolias.ogg"),
	manny = preload("res://sounds/music/manny.ogg"),
	crisis = preload("res://sounds/music/crisis.mp3"),
	deid = music_reminiscence_torn,
	embassy = music_embassy,
	colias = music_embassy,
	obama = music_phoenix,
	phoenix = music_phoenix,
	moderato = preload("res://sounds/music/moderato.ogg"),
	allegro = preload("res://sounds/music/allegro.ogg"),
	presto = preload("res://sounds/music/presto.ogg"),
	solution = music_solution,
	lbelle = preload("res://sounds/music/lbelle.ogg"),
	heaven = preload("res://sounds/music/heaven.ogg"),
	suspense = preload("res://sounds/music/suspense.mp3"),
	inv = preload("res://sounds/music/investigation_start.ogg"),
	invmid = preload("res://sounds/music/invmid.ogg"),
	invepic = preload("res://sounds/music/investigation_epic.ogg"),
	dgsinv = preload("res://sounds/music/dgsinv.mp3"),
	panic = preload("res://sounds/music/panic_of_fate.ogg"),
	walk = preload("res://sounds/music/walk.ogg"),
	guilty_love = preload("res://sounds/music/guilty_love.ogg"),
	protagonist = preload("res://sounds/music/protagonist.ogg"),
	thalassa = preload("res://sounds/music/thalassa.mp3"),
	shelock = preload("res://sounds/music/shelock.ogg"),
	rain = preload("res://sounds/music/rain.ogg"),
	rubble = preload("res://sounds/music/moving_rubble.ogg"),
	vent = preload("res://sounds/music/vent.ogg"),
	blaise = preload("res://sounds/music/blaise.mp3"),
	nate = preload("res://sounds/music/nate.mp3"),
	gimmick = preload("res://sounds/music/gimmick.ogg"),
	baroque = preload("res://sounds/music/baroque.ogg"),
	core = preload("res://sounds/music/core.ogg"),
	logic_chess = preload("res://sounds/music/logic_chess.mp3"),
	logic_chess_endgame = preload("res://sounds/music/logic_chess_endgame.mp3"),
	factory = preload("res://sounds/music/factory.ogg"),
	truth = preload("res://sounds/music/truth.ogg"),
	pursuit = preload("res://sounds/music/pursuit.ogg")
}

var music_volume = {
	guilty_love = 0.375,
	protagonist = 0.25,
	colias = 0.75,
	#shelock = 0.75,
	manny = 0.75,
	gimmick = 0.75,
	baroque = 0.75,
	core = 0.75
}

onready var speaker_map = {
	"quercus alba": char_querco,
	"quercus": char_querco,
	"querco": char_querco,
	"alba": char_querco,
	"obama": char_obama,
	"barack": char_obama,
	"barack obama": char_obama,
	"deid": char_deid,
	"mann": char_deid,
	"deid mann": char_deid,
	"colias": char_colias,
	"palaeno": char_colias,
	"colias palaeno": char_colias,
	"l'belle": char_lbelle,
	"florent": char_lbelle,
	"florent l'belle": char_lbelle,
	"sherlock": char_sherlock,
	"sherlock holmes": char_sherlock,
	"shelock holmes": char_shelock,
	"holmes": char_shelock,
	"mila": char_mila,
	"malucart": char_mila,
	"nate": char_nate,
	"nateyobb": char_nate,
	"protagonist": char_protagonist,
	"thalassa": char_thalassa,
	"manny": char_manny,
	"blaise": char_blaise,
	"blaise debeste": char_blaise,
	"pichuis": char_pichuis,
	"dhar mann": char_dhar,
	"mack rell": char_mack,
}

const bubbles = {
	objection = preload("res://gui/bubbles/objection.png"),
	holdit = preload("res://gui/bubbles/holdit.png"),
	takethat = preload("res://gui/bubbles/takethat.png")
}

func load_all(path, res = {}):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true)
		while true:
			var file = dir.get_next()
			if file == "":
				return res
			if file.ends_with(".import"):
				res[file.get_basename().get_basename()] = load(path + "/" + file.trim_suffix(".import"))
	else:
		return res

var mobile = OS.has_feature("mobile")
var sfx = load_all("res://sounds/sfx", {})
var all_evidence = load_all("user://content/evidence", load_all("res://evidence"))
var all_profiles = load_all("user://content/profiles", load_all("res://profiles"))

const sfx_volumes = {
	seduction = 2.0,
	flashback = 5.0
}

var preferences = {
	window_mode = "maximized"
}

func update_prefs():
	if OS.window_fullscreen:
		preferences.window_mode = "fullscreen"
	else:
		preferences.window_mode = "maximized"
	#elif OS.window_maximized:
	#	preferences.window_mode = "maximized"
	#else:
	#	preferences.window_mode = "windowed"
	var pref = File.new()
	pref.open("user://preferences.json", File.WRITE)
	pref.store_string(to_json(preferences))
	pref.close()

func _ready():
	var pref = File.new()
	if pref.file_exists("user://preferences.json"):
		pref.open("user://preferences.json", File.READ)
		preferences = parse_json(pref.get_as_text())
		pref.close()
		match preferences.window_mode:
			"fullscreen":
				OS.window_fullscreen = true
			"maximized":
				OS.window_fullscreen = false
				OS.window_maximized = true
	else:
		OS.window_fullscreen = false
		OS.window_maximized = true
	var dir = Directory.new()
	if dir.open("user://content/bg") == OK:
		dir.list_dir_begin(true)
		var file = dir.get_next()
		while file != "":
			Bg.bgs[file.get_basename()] = load("user://content/bg/" + file)
			file = dir.get_next()
	for s in sfx:
		if sfx[s] is AudioStreamMP3 or sfx[s] is AudioStreamOGGVorbis:
			sfx[s].loop = false
	if dir.open("user://content/sfx") == OK:
		dir.list_dir_begin(true)
		var file = dir.get_next()
		while file != "":
			var s = load("user://content/sfx/" + file)
			if s is AudioStreamMP3 or s is AudioStreamOGGVorbis:
				s.loop = false
			sfx[file.get_basename()] = s
			file = dir.get_next()
	if dir.open("user://content/music") == OK:
		dir.list_dir_begin(true)
		var file = dir.get_next()
		while file != "":
			music[file.get_basename()] = load("user://content/music/" + file)
			file = dir.get_next()
	if dir.open("user://content/char") == OK:
		dir.list_dir_begin(true)
		var file = dir.get_next()
		while file != "":
			var sc = "user://content/char/" + file + "/" + file + ".gd"
			if File.new().file_exists(sc):
				var c = load(sc).new()
				if "speaker_name" in c:
					if typeof(c.speaker_name) == TYPE_ARRAY:
						for n in c.speaker_name:
							speaker_map[n.to_lower()] = c
					elif typeof(c.speaker_name) == TYPE_STRING:
						speaker_map[c.speaker_name] = c
						print(c.speaker_name)
				chars[file] = c
				print("loaded character " + file)
			file = dir.get_next()

func _exit_tree():
	update_prefs()

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		update_prefs()
	var mp = get_viewport().get_mouse_position()
	var mm = Vector2(Input.get_action_strength("virtual_cursor_right") - Input.get_action_strength("virtual_cursor_left"), Input.get_action_strength("virtual_cursor_down") - Input.get_action_strength("virtual_cursor_up"))
	mm = mm.normalized()
	if mm != Vector2.ZERO:
		Input.warp_mouse_position(mp + mm * (get_viewport().size.y * 1.5) * delta)
	if Input.is_action_just_pressed("virtual_cursor_click"):
		var ev = InputEventMouseButton.new()
		ev.button_index = BUTTON_LEFT
		ev.pressed = true
		ev.position = get_viewport().get_mouse_position()
		get_tree().input_event(ev)
		yield(get_tree(), "idle_frame")
		ev.pressed = false
		get_tree().input_event(ev)

func load_more():
	for c in chars.values():
		for p in c.poses.values():
			if "texture" in p and typeof(p.texture) == TYPE_STRING:
				p.texture = c.load_(p.texture)
				break
			if "mouth" in p and typeof(p.mouth[0]) == TYPE_STRING:
				p.mouth[0] = c.load_(p.mouth[0])
				break
			if "eyes" in p and typeof(p.eyes[0]) == TYPE_STRING:
				p.eyes[0] = c.load_(p.eyes[0])
				break

signal sfx_done
var sfx_playing = 0
func play_sfx(sfx_name: String):
	var player = AudioStreamPlayer.new()
	player.stream = globals.sfx[sfx_name]
	$"/root".add_child(player)
	sfx_playing += 1
	player.volume_db = linear2db(sfx_volumes[sfx_name] if sfx_name in sfx_volumes else 0.25)
	player.connect("finished", self, "_sfx_done", [player])
	player.play()

func _sfx_done(player: AudioStreamPlayer):
	player.queue_free()
	sfx_playing -= 1
	if sfx_playing == 0:
		emit_signal("sfx_done")