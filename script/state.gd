extends Node
class_name State

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
	nate = char_nate
}

const music_querco = preload("res://sounds/music/querco.ogg")
const music_embassy = preload("res://sounds/music/embassy.ogg")
const music_reminiscence_torn = preload("res://sounds/music/reminiscence_torn.ogg")
const music_reminiscence_academy = preload("res://sounds/music/reminiscence_academy.ogg")
const music_solution = preload("res://sounds/music/solution.ogg")
const music_phoenix = preload("res://sounds/music/phoenix.ogg")
const music = {
	querco = music_querco,
	quercos = music_querco,
	quercus = music_querco,
	alba = music_querco,
	surpass = music_querco,
	reminiscence_torn = music_reminiscence_torn,
	reminiscence_academy = music_reminiscence_academy,
	bad_end = preload("res://sounds/music/bad_end.ogg"),
	manny = preload("res://sounds/music/manny.ogg"),
	deid = music_reminiscence_torn,
	embassy = music_embassy,
	obama = music_phoenix,
	phoenix = music_phoenix,
	moderato = preload("res://sounds/music/moderato.ogg"),
	allegro = preload("res://sounds/music/allegro.ogg"),
	presto = preload("res://sounds/music/presto.ogg"),
	solution = music_solution,
	lbelle = preload("res://sounds/music/lbelle.ogg")
}

const speaker_map = {
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
	"holmes": char_sherlock,
	"sherlock holmes": char_sherlock,
	"mila": char_mila,
	"malucart": char_mila,
	"nate": char_nate,
	"nateyobb": char_nate
}

const bubbles = {
	objection = preload("res://gui/bubbles/objection.png"),
	holdit = preload("res://gui/bubbles/holdit.png"),
	takethat = preload("res://gui/bubbles/takethat.png")
}

func load_all(path):
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)
	var res = {}
	while true:
		var file = dir.get_next()
		if file == "":
			return res
		if file.ends_with(".import"):
			res[file.get_basename().get_basename()] = load(path + "/" + file.trim_suffix(".import"))

var sfx = load_all("res://sounds/sfx")
var all_evidence = load_all("res://evidence")
var all_profiles = load_all("res://profiles")
var evidence = []
var profiles = []
var health = 10

var do_animate = false
var to_load = 0
var to_load_side = 0
var to_load_bg
var to_load_bgm
var to_load_modulate
var rsprite: Sprite
var lsprite: Sprite
var anim: AnimationPlayer
var objec_player: AudioStreamPlayer
var bg: TextureRect
var bgm: AudioStreamPlayer
var parser: Parser
var rchar
var lchar
var speaker_name = ""
var in_confrontation = false
var first_statement = false
var last_statement = false
var green_text = false
var call_stack = []
var vars = {}

func reset():
	green_text = false
	in_confrontation = false
	first_statement = false
	last_statement = false
	call_stack = []
	speaker_name = ""
	evidence = []
	profiles = []
	health = 10
	vars = {}
	lchar = null
	rchar = null
	if bg:
		bg.texture = null
	if bgm:
		bgm.stream = null
		bgm.stop()

func get_speaker():
	return speaker_map.get(speaker_name)

func object(char_name, type):
	shaking_start = OS.get_ticks_usec()
	if char_name and char_name in chars and type in chars[char_name]:
		objec_player.stream = chars[char_name].objection
	elif char_name == "protagonist":
		objec_player.stream = preload("res://sounds/protag_objection.wav")
	else:
		objec_player.stream = preload("res://sounds/objection.wav")
	anim.get_node("../Objection").texture = bubbles[type]
	anim.play("objection")
	parser.stop_talking()

func _sfx_done(player: AudioStreamPlayer):
	player.queue_free()

func play_sfx(sfx_name: String):
	var player = AudioStreamPlayer.new()
	player.stream = sfx[sfx_name]
	$"/root".add_child(player)
	player.volume_db = linear2db(0.25)
	player.connect("finished", self, "_sfx_done", [player])
	player.play()

var music_start = 0
var shaking_start = 0
var last_shake = 0
func _process(_delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if !get_tree().current_scene or get_tree().current_scene.name != "Main":
		return
	var now = OS.get_ticks_usec()
	if now <= shaking_start + 500000 and parser and now >= last_shake + 100000:
		parser.get_parent().get_parent().rect_position = Vector2(rand_range(-2, 2), rand_range(-2, 2))
	else:
		parser.get_parent().get_parent().rect_position = Vector2()
	if bgm:
		bgm.volume_db = linear2db(min((now - music_start) / 500000.0, 1))

func push_call_stack():
	call_stack.push_back([parser.pos, in_confrontation])

func run_command(text: String):
	vars._msecs = OS.get_ticks_msec()
	var parts_ = text.split(" ", false)
	var parts = []
	var quote = null
	for p in parts_:
		if quote:
			if p.ends_with('"'):
				quote += " " + p.substr(0, p.length() - 1)
				parts.append(quote)
				quote = null
			else:
				quote += " " + p
		elif p.begins_with('"'):
			if p.ends_with('"'):
				parts.append(p.substr(1, p.length() - 2))
			else:
				quote = p.substr(1)
		else:
			parts.append(p)
	if parts.size() != 0:
		match parts[0].to_lower():
			"lcharfadeout":
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.play("lcharfadeout")
			"rcharfadeout":
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.play("rcharfadeout")
			"fadeout":
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.play("fadeout")
			"fadein":
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.play("fadein")
			"char":
				lchar = null
				if parts[1] == "none":
					if rchar:
						parser.stop_talking()
						if anim.is_playing():
							yield(anim, "animation_finished")
						anim.play("rcharfadeout")
				else:
					rchar = chars.get(parts[1])
			"rchar", "char_right":
				if parts[1] == "none":
					if rchar:
						parser.stop_talking()
						if anim.is_playing():
							yield(anim, "animation_finished")
						anim.play("rcharfadeout")
				else:
					rchar = chars.get(parts[1])
			"lchar", "char_left":
				if parts[1] == "none":
					if lchar:
						parser.stop_talking()
						if anim.is_playing():
							yield(anim, "animation_finished")
						anim.play("lcharfadeout")
				else:
					lchar = chars.get(parts[1])
			"objection", "objeckshun", "hubjection", "hubjeckshun", "igiari":
				object(null if parts.size() == 1 else parts[1], "objection")
			"holdit", "matta":
				object(null if parts.size() == 1 else parts[1], "holdit")
			"takethat", "kurae":
				object(null if parts.size() == 1 else parts[1], "takethat")
			"pose":
				var c = chars[parts[1]]
				c.pose = c.poses[parts[2]]
			"shake", "s":
				shaking_start = OS.get_ticks_usec()
			"side":
				match parts[1]:
					"left":
						bg.side = 0
					"right":
						bg.side = 1
					null:
						bg.side = 0 if bg.side else 1
			"bg":
				if parts[1] == "none":
					bg.texture = null
				else:
					bg.texture = bg.bgs[parts[1]]
					if parts.size() > 2:
						match parts[2]:
							"left":
								bg.t = 1
								bg.side = 0
							"right":
								bg.t = 0
								bg.side = 1
					else:
						bg.t = 1
						bg.side = 0
			"music", "bgm":
				bgm.stop()
				bgm.stream = music.get(parts[1])
				bgm.play()
				music_start = OS.get_ticks_usec()
			"statement":
				in_confrontation = true
				if parts.size() > 1:
					if parts[1] == "start":
						first_statement = true
						last_statement = false
						parts.remove(1)
					elif parts[1] == "end":
						first_statement = false
						last_statement = true
						parts.remove(1)
					elif parts[1] == "endif":
						first_statement = false
						if parts[2].begins_with("!"):
							last_statement = !vars.get(parts[2].substr(1))
						else:
							last_statement = bool(vars.get(parts[2]))
						parts.remove(1)
						parts.remove(2)
				else:
					first_statement = false
					last_statement = false
				if parts.size() > 1:
					if parts[1] == "if":
						if !vars.get(parts[2]):
							if last_statement:
								parser.go_to(parser.gscript.rfind("{statement start", parser.pos))
							else:
								parser.go_to(parser.gscript.find("{statement", parser.pos))
			"set":
				vars[parts[1]] = (int(parts[2]) if parts[2].is_valid_integer() else int(vars.get(parts[2]))) if parts.size() > 2 else 1
			"destroy":
				if parts[1].ends_with("*"):
					var prefix = parts[1].trim_suffix("*")
					for k in vars.keys():
						if k.begins_with(prefix):
							vars.erase(k)
				else:
					vars.erase(parts[1])
			"rebuttal":
				in_confrontation = true
			"end_rebuttal":
				in_confrontation = false
				parser.go_to(parser.gscript.find("{end_of_rebuttal", parser.pos))
			"end_of_rebuttal":
				if in_confrontation:
					parser.go_to(parser.gscript.rfind("{statement start", parser.pos))
				else:
					anim.get_node("../Gauge").visible = false
			"sfx":
				play_sfx(parts[1])
			"vs":
				anim.get_node("../Control/Battleface/Sprite").texture = chars.get(parts[1]).get("battleface") if parts.size() > 1 else null
				parser.stop_talking()
				anim.play("vs")
				play_sfx("rebuttal")
				green_text = true
			"goto":
				if parts[1][0] == "<":
					parser.go_to(parser.gscript.rfind("{label " + parts[1].substr(1), parser.pos))
				else:
					parser.go_to(parser.gscript.find("{label " + parts[1], parser.pos))
			"call":
				push_call_stack()
				if parts[1][0] == "<":
					parser.go_to(parser.gscript.rfind("{label " + parts[1].substr(1), parser.pos))
				else:
					parser.go_to(parser.gscript.find("{label " + parts[1], parser.pos))
			"present":
				object("protagonist", "objection")
				in_confrontation = true
				var i = parser.gscript.find("{on_present " + parts[1], parser.pos)
				var next_stmt = parser.gscript.find("{statement", parser.pos + 1)
				if i == -1 or (next_stmt != -1 and i > next_stmt) or i > parser.gscript.find("{end_of_rebuttal}", parser.pos):
					parser.go_to(parser.gscript.rfind("{statement", parser.pos))
					push_call_stack()
					in_confrontation = false
					anim.get_node("../Gauge").visible = false
					parser.go_to(parser.gscript.find("\n", parser.gscript.find("{on_present}", parser.pos)))
				else:
					in_confrontation = false
					anim.get_node("../Gauge").visible = false
					parser.go_to(parser.gscript.find("\n", i))
			"gotoif":
				if !vars.get(parts[1].substr(1)) if parts[1][0] == "!" else vars.get(parts[1]):
					if parts[2][0] == "<":
						parser.go_to(parser.gscript.rfind("{label " + parts[2].substr(1), parser.pos))
					else:
						parser.go_to(parser.gscript.find("{label " + parts[2], parser.pos))
			"callif":
				if !vars.get(parts[1].substr(1)) if parts[1][0] == "!" else vars.get(parts[1]):
					push_call_stack()
					if parts[2][0] == "<":
						parser.go_to(parser.gscript.rfind("{label " + parts[2].substr(1), parser.pos))
					else:
						parser.go_to(parser.gscript.find("{label " + parts[2], parser.pos))
			"return":
				var ret = call_stack.pop_back()
				in_confrontation = ret[1]
				parser.pos = ret[0]
			"set":
				var v
				if parts[2][0] == "!":
					v = !vars.get(parts[2].substr(1))
				elif parts[2].is_valid_integer():
					v = int(parts[2])
				else:
					v = vars.get(parts[2])
				vars[parts[1]] = v
			"exp":
				var v1
				var v2
				if parts[1][0] == "!":
					v1 = !vars.get(parts[1].substr(1))
				elif parts[1].is_valid_integer():
					v1 = int(parts[1])
				else:
					v1 = vars.get(parts[1])
				if parts[3][0] == "!":
					v2 = !vars.get(parts[3].substr(1))
				elif parts[3].is_valid_integer():
					v2 = int(parts[3])
				else:
					v2 = vars.get(parts[3])
				var res = 0
				match parts[2]:
					"==":
						res = v1 == v2
					"!=":
						res = v1 != v2
					"<":
						res = v1 < v2
					">":
						res = v1 > v2
					"<=":
						res = v1 <= v2
					">=":
						res = v1 >= v2
					"+":
						res = v1 + v2
					"-":
						res = v1 - v2
					"*":
						res = v1 * v2
					"/":
						res = v1 / v2
					"%":
						res = v1 % v2
				vars[parts[4] if parts.size() > 4 else "_"] = int(res)
			"evidence", "evi":
				var evi = all_evidence[parts[1]]
				for e in evidence:
					if all_evidence[e.id] == evi:
						e.name = parts[2]
						e.desc = parts[3]
						return
				evidence.append({
					id = parts[1],
					name = parts[2],
					desc = parts[3]
				})
			"has_evidence", "has_evi":
				var evi = all_evidence[parts[1]]
				var found = 0
				for e in evidence:
					if all_evidence[e.id] == evi:
						found = 1
						break
				vars[parts[2] if parts.size() > 2 else "_"] = found
			"profile", "prof":
				var prof = all_profiles[parts[1]]
				for p in profiles:
					if all_profiles[p.id] == prof:
						p.name = parts[2]
						p.desc = parts[3]
						return
				profiles.append({
					id = parts[1],
					name = parts[2],
					desc = parts[3]
				})
			"has_profile", "has_prof":
				var prof = all_profiles[parts[1]]
				var found = 0
				for p in profiles:
					if all_profiles[p.id] == prof:
						found = 1
						break
				vars[parts[2] if parts.size() > 2 else "_"] = found
			"penalty":
				anim.get_node("../Gauge/Boom").rect_position.x = 5 + 23 * health - 32
				health = max(health - 2, 0)
				if health == 0:
					parser.go_to(parser.gscript.find("{on_bad_end}", parser.pos))
				anim.get_node("../Gauge/Bar").value = health
				anim.play("penalty")
				parser.stop_talking()
			"bad_end":
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.get_node("../TextureRect").visible = false
				anim.get_node("../HBoxContainer").visible = false
				bg.get_parent().modulate = Color.transparent
				bg.texture = bg.bgs["bad_end"]
				bg.t = 0
				bg.side = 1
				anim.play("fadein")
				yield(anim, "animation_finished")
				parser.stop_talking()
				var t = OS.get_ticks_msec()
				while OS.get_ticks_msec() < t + 4000:
					yield(anim.get_tree(), "idle_frame")
				if anim.is_playing():
					yield(anim, "animation_finished")
				anim.play("fadeout")
				yield(anim, "animation_finished")
				reset()
				anim.get_tree().change_scene("res://title_screen.tscn")
			"restore_health":
				health = 10
				anim.get_node("../Gauge/Bar").value = health
			"on_present":
				parser.go_to(parser.gscript.rfind("{statement", parser.pos))
			"choice":
				anim.get_node("../Choices").show_choices(parts)
			"amogus":
				var amogus = preload("res://amogus/amogus.tscn").instance()
				$"/root".add_child(amogus)
				get_tree().paused = true
