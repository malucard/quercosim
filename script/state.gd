extends Control
class_name State

var evidence = []
var profiles = []
var health = 10

const STATE_DIALOGUE = "dialogue"
const STATE_CHOICE = "choice"
const STATE_CONFRONTATION = "confrontation"
const STATE_CONFRONTATION_FIRST = "confrontation_first"
const STATE_CONFRONTATION_LAST = "confrontation_last"
const STATE_CONFRONTATION_ONLY = "confrontation_only"
const STATE_SEDUCTION_CONFRONTATION = "seduction_confrontation"
const STATE_SEDUCTION_CONFRONTATION_FIRST = "seduction_confrontation_first"
const STATE_SEDUCTION_CONFRONTATION_LAST = "seduction_confrontation_last"
const STATE_SEDUCTION_CONFRONTATION_ONLY = "seduction_confrontation_only"
const STATE_INVESTIGATION = "investigation"
const STATE_INVESTIGATION_EXAMINE = "investigation_examine"
const STATE_INVESTIGATION_MOVE = "investigation_move"
const STATE_INVESTIGATION_TALK = "investigation_talk"
const STATE_BAD_END = "bad_end"
const STATE_SEDUCTION_DIALOGUE = "seduction_dialogue"
const STATE_SEDUCTION_CHOICE = "seduction_choice"
const STATE_PENALTY_CHOICE = "penalty_choice"
const STATE_SEDUCTION_PRESENT = "seduction_present"
const STATE_PENALTY_PRESENT = "penalty_present"
const state_tags = {
	dialogue = ["show_dialogue"],
	choice = ["show_choice"],
	confrontation = ["show_dialogue", "show_gauge", "confrontation"],
	confrontation_first = ["show_dialogue", "show_gauge", "confrontation", "first_statement"],
	confrontation_last = ["show_dialogue", "show_gauge", "confrontation", "last_statement"],
	confrontation_only = ["show_dialogue", "show_gauge", "confrontation", "first_statement", "last_statement"],
	penalty = ["show_dialogue", "show_gauge"],
	investigation = ["investigation", "investigation_idle", "stop_script"],
	investigation_examine = ["investigation", "hide_char", "investigation_back", "investigation_examine", "stop_script"],
	investigation_move = ["investigation", "investigation_back", "investigation_move", "stop_script"],
	investigation_talk = ["investigation", "investigation_back", "investigation_talk", "stop_script"],
	seduction_dialogue = ["show_seduction", "show_dialogue"],
	seduction_penalty = ["show_dialogue", "show_seduction"],
	seduction_confrontation = ["show_dialogue", "show_seduction", "seduction_timer", "confrontation"],
	seduction_confrontation_first = ["show_dialogue", "show_seduction", "seduction_timer", "confrontation", "first_statement"],
	seduction_confrontation_last = ["show_dialogue", "show_seduction", "seduction_timer", "confrontation", "last_statement"],
	seduction_confrontation_only = ["show_dialogue", "show_seduction", "seduction_timer", "confrontation", "first_statement", "last_statement"],
	seduction_choice = ["show_seduction", "show_dialogue", "seduction_timer", "choice"],
	penalty_choice = ["show_dialogue", "show_gauge", "choice"],
	seduction_present = ["show_seduction", "show_dialogue", "seduction_timer", "choice", "present"],
	penalty_present = ["show_dialogue", "show_gauge", "choice", "present"],
	#seduction_menu = ["show_seduction", "show_seduction_choices", "seduction_timer", "stop_script"],
	#seduction_press = ["show_seduction", "show_seduction_press", "seduction_timer", "stop_script"],
	#seduction_point_out = ["show_seduction", "show_seduction_point_out", "seduction_timer", "stop_script"],
	bad_end = []
}

var seductiometer = 500

var state_stack = []
var state = STATE_DIALOGUE
var inv = {}

func has_tag(t):
	return state_tags[state].has(t)

func push(s = null):
	state_stack.push_back(state)
	if s:
		state = s

func pop():
	state = state_stack[state_stack.size() - 1]
	state_stack.pop_back()

onready var rsprite = $Control/RSprite
onready var lsprite = $Control/LSprite
onready var esprites = [$Control/ESprite0, $Control/ESprite1, $Control/ESprite2, $Control/ESprite3, $Control/ESprite4]
var anim: AnimationPlayer
var objec_player: AudioStreamPlayer
var bg: TextureRect
var bgm: AudioStreamPlayer
var parser
var rchar
var lchar
var echar = [null, null, null, null, null]
var speaker_name = ""
var call_stack = []
var vars = {}
var speaker_aliases = {}

func _ready():
	speaker_aliases["?"] = "???"

func reset():
	call_stack = []
	speaker_name = ""
	evidence = []
	profiles = []
	health = 10
	vars = {}
	lchar = null
	rchar = null
	echar = [null, null, null, null, null]
	if bg:
		bg.cur = null
	if bgm and is_instance_valid(bgm):
		bgm.stream = null
		bgm.stop()

func get_speaker():
	if globals.speaker_map.get(speaker_name.to_lower()) == null:
		print(speaker_name.to_lower())
		print(str(speaker_name.to_lower() == "protagonist"))
		print(str(globals.speaker_map.get("protagonist") == null))
		print(str(globals.speaker_map.protagonist == null))
	return globals.speaker_map.get(speaker_name.to_lower())

func object(char_name, type):
	shaking_start = OS.get_ticks_usec()
	if char_name and char_name in globals.chars and type in globals.chars[char_name]:
		var c = globals.chars[char_name]
		objec_player.stream = c.load_(c.objection)
	else:
		objec_player.stream = preload("res://sounds/objection.wav")
	objec_player.volume_db = linear2db(0.75)
	anim.get_node("../Objection").texture = globals.bubbles[type]
	anim.play("objection")
	parser.stop_talking()

var music_start = 0
var shaking_start = 0
var last_shake = 0
func _process(_delta):
	if has_tag("present") and !$Organizer/Present.visible:
		$Organizer._open_present()
	$Investigation/Hand.visible = globals.mobile and has_tag("investigation_examine")
	if has_tag("investigation_idle"):
		$Control/RSprite.visible = false
	$Investigation/Buttons.visible = has_tag("investigation_idle")
	$Investigation/Back.visible = has_tag("investigation_back")
	if has_tag("investigation"):
		$Investigation.visible = true
		$Investigation/Buttons/Examine.visible = !inv.areas[inv.area].examinables.empty()
		var vis = false
		for i in range(inv.open_move.size()):
			if inv.open_move[i].begins_with(str(inv.area) + ":"):
				vis = true
				break
		if vis != $Investigation/Buttons/Move.visible:
			$Investigation/Buttons/Move.visible = vis
		vis = false
		for i in range(inv.open_talk.size()):
			if inv.open_talk[i].begins_with(str(inv.area) + ":"):
				vis = true
				break
		if vis != $Investigation/Buttons/Talk.visible:
			$Investigation/Buttons/Talk.visible = vis
	else:
		$Investigation.visible = false
	if has_tag("investigation_move"):
		var places = $Investigation/Places
		places.visible = true
		var upd = false
		var children = places.get_children()
		var open_areas = []
		for a in range(inv.areas.size()):
			if inv.open_move.has(str(inv.area) + ":" + str(a)):
				open_areas.push_back(a)
		if children.size() != open_areas.size():
			for i in range(children.size()):
				children[i].queue_free()
			for i in range(open_areas.size()):
				var ins = preload("res://gui/choice_button.tscn").instance()
				ins.get_node("Label").text = inv.areas[open_areas[i]].name
				ins.connect("pressed", self, "_move_to", [open_areas[i]])
				places.add_child(ins)
		else:
			for i in range(children.size()):
				var c = children[i]
				c.get_node("Label").text = inv.areas[open_areas[i]].name
				c.disconnect("pressed", self, "_move_to")
				c.connect("pressed", self, "_move_to", [open_areas[i]])
	else:
		$Investigation/Places.visible = false
	if has_tag("investigation_talk"):
		var talks = $Investigation/Talks
		talks.visible = true
		var upd = false
		var children = talks.get_children()
		var keys = inv.areas[inv.area].talks.keys()
		var open_talks = []
		for i in range(keys.size()):
			if inv.open_talk.has(str(inv.area) + ":" + keys[i]):
				open_talks.push_back(i)
		if children.size() != open_talks.size():
			for i in range(children.size()):
				children[i].queue_free()
			for i in range(open_talks.size()):
				var ins = preload("res://gui/choice_button.tscn").instance()
				ins.get_node("Label").text = keys[open_talks[i]]
				ins.connect("pressed", self, "_talk_about", [keys[open_talks[i]]])
				talks.add_child(ins)
				if inv.talked.has(str(inv.area) + ":" + keys[open_talks[i]]):
					ins.get_node("Label").margin_left = 0
					ins.get_node("Label").margin_right = 0
					ins.get_node("Check").rect_position.x = ins.rect_size.x / 2 + ins.get_node("Label").rect_size.x / 2 + 2
					ins.get_node("Check").rect_position.y = 10
					ins.get_node("Check").visible = true
				else:
					ins.get_node("Check").visible = false
		else:
			for i in range(children.size()):
				var c = children[i]
				c.get_node("Label").text = keys[open_talks[i]]
				c.disconnect("pressed", self, "_talk_about")
				c.connect("pressed", self, "_talk_about", [keys[open_talks[i]]])
				if inv.talked.has(str(inv.area) + ":" + keys[open_talks[i]]):
					c.get_node("Label").margin_left = 0
					c.get_node("Label").margin_right = 0
					c.get_node("Check").rect_position.x = c.rect_size.x / 2 + c.get_node("Label").rect_size.x / 2 + 2
					c.get_node("Check").rect_position.y = 10
					c.get_node("Check").visible = true
				else:
					c.get_node("Check").visible = false
	else:
		$Investigation/Talks.visible = false
	if has_tag("investigation_idle"):
		$Control/RSprite.visible = false
	if has_tag("show_seduction"):
		var mat: SpatialMaterial = $Control/Seduction/ViewportContainer/Viewport/MeshInstance.mesh.surface_get_material(0)
		if mat.albedo_texture != bg.texture:
			mat = mat.duplicate()
			mat.albedo_texture = bg.texture
		$Control/Seduction/ViewportContainer/Viewport/MeshInstance.mesh.surface_set_material(0, mat)
		$Control/Seduction.visible = true
		$Control/Seduction/VBoxContainer/Gauge/Bar.value = seductiometer
		$Control/Seduction/VBoxContainer/Gauge/Bar2.value = 1000 - seductiometer
	else:
		$Control/Seduction.visible = false
	if has_tag("seduction_timer"):
		if $Control/Seduction/Timer.is_stopped():
			$Control/Seduction/Timer.start()
	else:
		$Control/Seduction/Timer.stop()
	$TextureRect.visible = has_tag("show_dialogue")
	var now = OS.get_ticks_usec()
	if now <= shaking_start + 500000 and parser and now >= last_shake + 100000:
		parser.get_parent().get_parent().rect_position = Vector2(rand_range(-2, 2), rand_range(-2, 2))
	else:
		parser.get_parent().get_parent().rect_position = Vector2()
	if bgm:
		var vol = 1.0
		for m in globals.music.keys():
			if bgm.stream == globals.music[m]:
				if globals.music_volume.has(m):
					vol = globals.music_volume[m]
					break
		if now < music_start:
			vol = 0.0
		bgm.volume_db = linear2db(vol * min((now - music_start) / 500000.0, 1))
	$Gauge.visible = has_tag("show_gauge")

func push_call_stack():
	var sp = parser.get_save_pos()
	call_stack.push_back([parser.script_id, sp[0], sp[1], state])

func command_at(pos: int) -> PoolStringArray:
	var j = parser.gscript.find("\n", pos + 1)
	if j == -1:
		j = parser.gscript.length()
	var parts_ = parser.gscript.substr(pos, j - pos).strip_edges().split(" ", false)
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
	return parts

func find_command_behind(text: String, where: int = parser.pos) -> int:
	var i = parser.gscript.rfind("\n", where - 1)
	if i >= where:
		return -1
	while i > 0:
		var j = parser.gscript.rfind("\n", i - 1)
		if j == -1:
			j = 0
		var cmd = parser.gscript.substr(j, i - j).strip_edges()
		if cmd.begins_with(text):
			return j if j < where else -1
		i = j
	return -1

func find_command_ahead(text: String, where: int = parser.pos) -> int:
	var i = parser.gscript.find("\n", where + 1)
	while i < parser.gscript.length():
		var j = parser.gscript.find("\n", i + 1)
		if j == -1:
			j = parser.gscript.length()
		var cmd = parser.gscript.substr(i, j - i).strip_edges()
		if text == "" or cmd.begins_with(text + " ") or cmd == text:
			return i
		i = j
	return -1

func run_command(text: String):
	print("got " + text)
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
		parts[0] = parts[0].to_lower()
		match parts[0]:
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
				if $Control.modulate.r != 0:
					anim.get_animation("fadeout").track_set_key_value(0, 0, $Control.modulate)
					parser.stop_talking()
					while anim.is_playing():
						yield(anim, "animation_finished")
					anim.play("fadeout")
			"fadein":
				if $Control.modulate.r != 1:
					anim.get_animation("fadein").track_set_key_value(0, 0, $Control.modulate)
					parser.stop_talking()
					while anim.is_playing():
						yield(anim, "animation_finished")
					anim.play("fadein")
			"char":
				if parts[1] == "none":
					if rchar:
						yield(rsprite.disappear(), "completed")
					if lchar:
						yield(lsprite.disappear(), "completed")
					for i in range(echar.size()):
						if echar[i]:
							yield(esprites[i].disappear(), "completed")
				else:
					var dc = globals.chars.get(parts[1])
					if lchar and lchar != dc:
						yield(lsprite.disappear(), "completed")
					if rchar and rchar != dc:
						yield(rsprite.disappear(), "completed")
					for i in range(echar.size()):
						if echar[i] and echar[i] != dc:
							yield(esprites[i].disappear(), "completed")
					rchar = dc
					if lchar == dc:
						lchar = null
						lsprite.visible = false
						rsprite.position.x = lsprite.position.x
						rsprite.appear_sudden()
					else:
						var found = false
						for j in range(echar.size()):
							if echar[j] == dc:
								esprites[j].remove()
								rsprite.position.x = esprites[j].position.x
								rsprite.appear_sudden()
								found = true
								break
						if !found:
							rsprite.appear()
				if parts.size() > 2:
					run_command("pose " + parts[1] + " " + parts[2])
			"rchar", "char_right":
				if parts[1] == "none":
					if rchar:
						yield(rsprite.disappear(), "completed")
				else:
					var dc = globals.chars.get(parts[1])
					rchar = dc
					if lchar == dc:
						lchar = null
						lsprite.visible = false
						rsprite.position.x = lsprite.position.x
						rsprite.appear_sudden()
					else:
						var found = false
						for i in range(echar.size()):
							if echar[i] == dc:
								echar[i] = null
								esprites[i].visible = false
								rsprite.position.x = esprites[i].position.x
								rsprite.appear_sudden()
								found = true
								break
						if !found:
							rsprite.appear()
				if parts.size() > 2:
					run_command("pose " + parts[1] + " " + parts[2])
			"lchar", "char_left":
				if parts[1] == "none":
					if lchar:
						yield(lsprite.disappear(), "completed")
				else:
					var dc = globals.chars.get(parts[1])
					lchar = dc
					if rchar == dc:
						rchar = null
						rsprite.visible = false
						lsprite.position.x = rsprite.position.x
						lsprite.appear_sudden()
					else:
						var found = false
						for i in range(echar.size()):
							if echar[i] == dc:
								echar[i] = null
								esprites[i].visible = false
								lsprite.position.x = esprites[i].position.x
								lsprite.appear_sudden()
								found = true
								break
						if !found:
							lsprite.appear()
				if parts.size() > 2:
					run_command("pose " + parts[1] + " " + parts[2])
			"echar":
				var i = int(parts[1])
				if parts[2] == "none":
					if echar[i]:
						yield(esprites[i].disappear(), "completed")
				else:
					var dc = globals.chars.get(parts[2])
					echar[i] = dc
					if rchar == dc:
						rchar = null
						rsprite.visible = false
						esprites[i].position.x = rsprite.position.x
						esprites[i].appear_sudden()
					elif lchar == dc:
						lchar = null
						lsprite.visible = false
						esprites[i].position.x = lsprite.position.x
						esprites[i].appear_sudden()
					else:
						var found = false
						for j in range(echar.size()):
							if j != i and echar[j] == dc:
								echar[j] = null
								esprites[j].visible = false
								esprites[i].position.x = esprites[j].position.x
								esprites[i].appear_sudden()
								found = true
								break
						if !found:
							esprites[i].appear()
				if parts.size() > 3:
					run_command("pose " + parts[2] + " " + parts[3])
			"bgvideo":
				parser.stop_talking()
				$BGVideoPlayer.visible = true
				var f = File.new()
				var stream
				if f.file_exists("user://content/videos/" + parts[1] + ".ogv"):
					stream = VideoStreamTheora.new()
					stream.set_file("user://content/videos/" + parts[1] + ".ogv")
				elif f.file_exists("user://content/videos/" + parts[1] + ".webm"):
					stream = VideoStreamWebm.new()
					stream.set_file("user://content/videos/" + parts[1] + ".webm")
				elif f.file_exists("res://videos/" + parts[1] + ".ogv"):
					stream = load("res://videos/" + parts[1] + ".ogv")
				elif f.file_exists("res://videos/" + parts[1] + ".webm"):
					stream = load("res://videos/" + parts[1] + ".webm")
				else:
					parser.resume_talking(true)
					return
				$BGVideoPlayer.stream = stream
				$BGVideoPlayer.play()
				yield($BGVideoPlayer, "finished")
				$BGVideoPlayer.stream = null
				$BGVideoPlayer.visible = false
				parser.resume_talking(true)
			"video":
				parser.stop_talking()
				$FGVideoPlayer.visible = true
				var f = File.new()
				var stream
				if f.file_exists("user://content/videos/" + parts[1] + ".ogv"):
					stream = VideoStreamTheora.new()
					stream.set_file("user://content/videos/" + parts[1] + ".ogv")
				elif f.file_exists("user://content/videos/" + parts[1] + ".webm"):
					stream = VideoStreamWebm.new()
					stream.set_file("user://content/videos/" + parts[1] + ".webm")
				elif f.file_exists("res://videos/" + parts[1] + ".ogv"):
					stream = load("res://videos/" + parts[1] + ".ogv")
				elif f.file_exists("res://videos/" + parts[1] + ".webm"):
					stream = load("res://videos/" + parts[1] + ".webm")
				else:
					parser.resume_talking(true)
					return
				$FGVideoPlayer.stream = stream
				$FGVideoPlayer.play()
				yield($FGVideoPlayer, "finished")
				$FGVideoPlayer.stream = null
				$FGVideoPlayer.visible = false
				parser.resume_talking(true)
			"objection", "objeckshun", "hubjection", "hubjeckshun", "igiari":
				object(null if parts.size() == 1 else parts[1], "objection")
			"holdit", "matta":
				object(null if parts.size() == 1 else parts[1], "holdit")
			"takethat", "kurae":
				object(null if parts.size() == 1 else parts[1], "takethat")
			"pose":
				var c = globals.chars[parts[1]]
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
			"bg", "bgkeep":
				if parts[0] != "bgkeep":
					lchar = null
					rchar = null
					echar = [null, null, null, null, null]
				if parts[1] == "none":
					if bg.cur:
						parser.stop_talking()
						bg.cur = null
						yield(bg, "transition_done")
						parser.resume_talking(true)
				else:
					var b = globals.bgs[parts[1]]
					if bg.cur != b:
						bg.cur = b
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
						parser.stop_talking()
						yield(bg, "transition_done")
						parser.resume_talking(true)
			"music", "bgm":
				var m = globals.music.get(parts[1])
				if m != bgm.stream:
					bgm.stop()
					bgm.stream = m
					bgm.volume_db = linear2db(0)
					bgm.play()
					music_start = OS.get_ticks_usec()
			"stmt":
				var start = find_command_behind("vs")
				var end = find_command_ahead("endvs")
				var prev_stmt = find_command_behind("stmt")
				while true:
					if prev_stmt == -1 or prev_stmt < start:
						prev_stmt = null
						break
					var cmd = command_at(prev_stmt)
					if cmd.size() > 2 and cmd[1] == "if":
						var cnd = !vars.get(cmd[2].substr(1)) if cmd[2].begins_with("!") else (true if vars.get(cmd[2]) else false)
						if cnd:
							break
						else:
							prev_stmt = find_command_behind("stmt", prev_stmt)
					else:
						break
				var next_stmt = find_command_ahead("stmt")
				while true:
					if next_stmt == -1 or next_stmt > end:
						next_stmt = null
						break
					var cmd = command_at(next_stmt)
					if cmd.size() > 2 and cmd[1] == "if":
						var cnd = !vars.get(cmd[2].substr(1)) if cmd[2].begins_with("!") else (true if vars.get(cmd[2]) else false)
						if cnd:
							break
						else:
							next_stmt = find_command_ahead("stmt", next_stmt)
					else:
						break
				var cnd = true
				if parts.size() > 2 and parts[1] == "if":
					cnd = !vars.get(parts[2].substr(1)) if parts[2].begins_with("!") else vars.get(parts[2])
				if cnd:
					if prev_stmt != null:
						if next_stmt != null:
							if has_tag("show_seduction"):
								state = STATE_SEDUCTION_CONFRONTATION
							else:
								state = STATE_CONFRONTATION
						else:
							if has_tag("show_seduction"):
								state = STATE_SEDUCTION_CONFRONTATION_LAST
							else:
								state = STATE_CONFRONTATION_LAST
					elif next_stmt != null:
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_CONFRONTATION_FIRST
						else:
							state = STATE_CONFRONTATION_FIRST
					else:
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_CONFRONTATION_ONLY
						else:
							state = STATE_CONFRONTATION_ONLY
				elif next_stmt != null:
					parser.go_to(next_stmt)
				else:
					parser.go_to(find_command_ahead("stmt", start))
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
			"exit_vs":
				if has_tag("show_seduction"):
					state = STATE_SEDUCTION_DIALOGUE
				else:
					state = STATE_DIALOGUE
				parser.go_to(find_command_ahead("endvs"))
			"sfx":
				globals.play_sfx(parts[1])
			"endvs":
				run_command("destroy c_*")
				run_command("music none")
			"vs":
				var c = globals.chars.get(parts[1])
				anim.get_node("../Control/Battleface/Sprite").texture = c.load_(c.get("battleface")) if parts.size() > 1 else null
				parser.stop_talking()
				anim.play("vs")
				globals.play_sfx("rebuttal")
			"goto":
				if parts[1][0] == "<":
					parser.go_to(find_command_behind("label " + parts[1].substr(1)))
				else:
					parser.go_to(find_command_ahead("label " + parts[1]))
			"call":
				push_call_stack()
				if parts[1][0] == "<":
					parser.go_to(find_command_behind("label " + parts[1].substr(1)))
				else:
					parser.go_to(find_command_ahead("label " + parts[1]))
			"file":
				parser.script_path = parts[1]
				parser.load_script(parts[1])
				parser.pos = 0
			"chapter_end":
				parser.stop_talking()
				globals.play_sfx("chapter_end")
				while anim.is_playing():
					yield(anim, "animation_finished")
				$ChapterEnd/Label.text = "Chapter " + parts[1] + "\n" + parts[2] + "\n\nEND"
				anim.play("chapter_transition_show")
				yield(anim, "animation_finished")
				anim.play("chapter_transition")
				yield(anim, "animation_finished")
				parser.resume_talking(true)
			"chapter":
				run_command("music none")
				run_command("bg none")
				run_command("restore_health")
				while anim.is_playing():
					yield(anim, "animation_finished")
				$ChapterEnd/Label.text = "Chapter " + parts[1] + "\n" + parts[2]
				anim.play("chapter_transition")
				yield(anim, "animation_finished")
				anim.play("chapter_transition_hide")
				yield(anim, "animation_finished")
				parser.resume_talking(true)
				health = 10
				$Gauge/Bar.value = health
			"seduction_card":
				run_command("music none")
				run_command("sfx seduction")
				anim.play("seduction_show")
				yield(anim, "animation_finished")
				run_command("music logic_chess")
			"seduction_complete_card":
				run_command("sfx seduction")
				anim.play("seduction_complete_show")
				yield(anim, "animation_finished")
				run_command("music none")
			"enter_seduction":
				if parts.size() > 1 and parts[1] == "snap":
					run_command("music none")
					run_command("char protagonist snap")
					parser.stop_talking()
					var t = get_tree().create_timer(0.8)
					yield(t, "timeout")
					parser.resume_talking(true)
					run_command("sfx seduction")
					anim.play("seduction_show")
					yield(anim, "animation_finished")
					rchar = null
					lchar = null
					echar = [null, null, null, null, null]
				state = STATE_SEDUCTION_DIALOGUE
				seductiometer = 500
			"exit_seduction":
				if parts.size() > 1 and parts[1] == "zvarri":
					run_command("sfx seduction")
					anim.play("seduction_complete_show")
					yield(anim, "animation_finished")
				state = STATE_DIALOGUE
			"present":
				if has_tag("confrontation"):
					object("protagonist", "objection")
					var i = find_command_behind("correct_present", parser.pos)
					var cur_stmt = find_command_behind("stmt")
					if i > cur_stmt and command_at(i)[1] == parts[1]:
						parser.go_to(find_command_ahead("endvs"))
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_DIALOGUE
						else:
							state = STATE_DIALOGUE
					else:
						parser.go_to(find_command_ahead("", cur_stmt))
						push_call_stack()
						parser.go_to(find_command_ahead("", find_command_ahead("wrong_present")))
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_DIALOGUE
						else:
							state = STATE_DIALOGUE
				else:
					object("protagonist", "takethat")
					var j = parser.gscript.find("\n", parser.pos + 1)
					var i = find_command_behind("request_present", parser.pos + 1)
					if command_at(i)[1] == parts[1]:
						parser.go_to(find_command_ahead("endrq"))
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_DIALOGUE
						else:
							state = STATE_DIALOGUE
					else:
						parser.go_to(parser.gscript.rfind("\n", i))
						push_call_stack()
						parser.go_to(find_command_ahead("", i + 1))
						if has_tag("show_seduction"):
							state = STATE_SEDUCTION_DIALOGUE
						else:
							state = STATE_DIALOGUE
			"request_present":
				if has_tag("show_seduction"):
					state = STATE_SEDUCTION_PRESENT
				else:
					state = STATE_PENALTY_PRESENT
				$Organizer._open_present()
			"gotoif":
				if !vars.get(parts[1].substr(1)) if parts[1][0] == "!" else vars.get(parts[1]):
					if parts[2][0] == "<":
						parser.go_to(find_command_behind("label " + parts[2].substr(1)))
					else:
						parser.go_to(find_command_ahead("label " + parts[2]))
			"callif":
				if !vars.get(parts[1].substr(1)) if parts[1][0] == "!" else vars.get(parts[1]):
					push_call_stack()
					if parts[2][0] == "<":
						parser.go_to(find_command_behind("label " + parts[2].substr(1)))
					else:
						parser.go_to(find_command_ahead("label " + parts[2]))
			"returnif":
				if !vars.get(parts[1].substr(1)) if parts[1][0] == "!" else vars.get(parts[1]):
					var ret = call_stack.pop_back()
					parser.load_script(ret[0])
					parser.go_to_save_pos(ret[1], ret[2])
					state = ret[3]
			"return":
				var ret = call_stack.pop_back()
				parser.load_script(ret[0])
				parser.go_to_save_pos(ret[1], ret[2])
				state = ret[3]
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
				var evi = globals.all_evidence[parts[1]]
				parts[3] = parts[3].replace("\\n", "\n")
				for e in evidence:
					if e.id == parts[1]:
						e.name = parts[2]
						e.desc = parts[3]
						return
				evidence.append({
					id = parts[1],
					name = parts[2],
					desc = parts[3]
				})
			"eviclone":
				globals.all_evidence[parts[1]] = globals.all_evidence[parts[2]]
			"rmevi":
				for i in range(evidence.size()):
					if evidence[i].id == parts[1]:
						evidence.remove(i)
						break
			"has_evidence", "has_evi":
				var evi = globals.all_evidence[parts[1]]
				var found = 0
				for e in evidence:
					if globals.all_evidence[e.id] == evi:
						found = 1
						break
				vars[parts[2] if parts.size() > 2 else "_"] = found
			"profile", "prof":
				var prof = globals.all_profiles[parts[1]]
				for p in profiles:
					if globals.all_profiles[p.id] == prof:
						p.name = parts[2]
						p.desc = parts[3]
						return
				profiles.append({
					id = parts[1],
					name = parts[2],
					desc = parts[3]
				})
			"has_profile", "has_prof":
				var prof = globals.all_profiles[parts[1]]
				var found = 0
				for p in profiles:
					if globals.all_profiles[p.id] == prof:
						found = 1
						break
				vars[parts[2] if parts.size() > 2 else "_"] = found
			"penalty":
				anim.get_node("../Gauge/Boom").rect_position.x = 5 + 23 * health - 32
				health = max(health - (int(parts[1]) if parts.size() > 1 else 2), 0)
				if health == 0:
					parser.go_to(find_command_ahead("game_over"))
				anim.get_node("../Gauge/Bar").value = health
				anim.play("penalty")
				parser.stop_talking()
			"penalty_seduction":
				if seductiometer > 0:
					anim.get_node("../Control/Seduction/VBoxContainer/Gauge/Boom").rect_position.x = 5 + seductiometer * 470 / 1000 - 32
					seductiometer = max(seductiometer - (int(parts[1]) if parts.size() > 1 else 200), 0)
					if seductiometer == 0:
						state = STATE_DIALOGUE
						parser.go_to(find_command_ahead("game_over"))
					anim.get_node("../Control/Seduction/VBoxContainer/Gauge/Bar").value = health
					anim.get_node("../Control/Seduction/VBoxContainer/Gauge/Bar2").value = 1000 - health
					anim.play("penalty_seduction")
					parser.stop_talking()
			"bad_end":
				rchar = null
				lchar = null
				echar = [null, null, null, null, null]
				parser.stop_talking()
				if anim.is_playing():
					yield(anim, "animation_finished")
				$TextureRect.visible = false
				$HBoxContainer.visible = false
				state = STATE_BAD_END
				bg.get_parent().modulate = Color.transparent
				bg.cur = globals.bgs["bad_end"]
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
				get_tree().change_scene("res://title_screen.tscn")
			"title_screen":
				get_tree().change_scene("res://title_screen.tscn")
			"restore_health":
				health = min(health + (int(parts[1]) if parts.size() > 1 else 10), 10)
				$Gauge/Bar.value = health
			"reset_seduction":
				seductiometer = 500
			"restore_seduction":
				if seductiometer < 1000:
					seductiometer = min(seductiometer + (int(parts[1]) if parts.size() > 1 else 250), 1000)
					if seductiometer == 1000:
						parser.go_to(find_command_ahead(""))
						push_call_stack()
						parser.go_to(find_command_ahead("seduction_success"))
			"wrong_present":
				parser.go_to(find_command_behind("stmt"))
			"choice":
				if has_tag("show_seduction"):
					state = STATE_SEDUCTION_CHOICE
				else:
					state = STATE_CHOICE
				$Choices.show_choices(parts)
			"penalty_choice":
				if has_tag("show_seduction"):
					state = STATE_SEDUCTION_CHOICE
				else:
					state = STATE_PENALTY_CHOICE
				$Choices.show_choices(parts)
			"speaker":
				speaker_aliases[parts[1]] = parts[2]
			"bgmvol":
				globals.music_volume[parts[1]] = float(parts[2]) / 100.0
			"sfxvol":
				globals.sfx_volumes[parts[1]] = float(parts[2]) / 400.0
			"amogus":
				var amogus = load("res://amogus/amogus.tscn").instance()
				$"/root".add_child(amogus)
				get_tree().paused = true
			"investigation":
				#push_call_stack()
				#state = STATE_INVESTIGATION
				#load_inv(parts[1])
				load_inv_new(parts[1])
				#push_call_stack()
				#parser.gscript = inv.areas[inv.area].script + "\nreturn"
				#parser.pos = 0
				#parser.script_id = "inv:" + inv.id + ":" + str(inv.area)
				#state = "dialogue"
			"area", "examinable", "talk", "endinv":
				run_command("return")
			"open_move":
				if !inv.open_move.has(str(inv.area) + ":" + parts[1]):
					inv.open_move.push_back(str(inv.area) + ":" + parts[1])
			"close_move":
				var idx = inv.open_move.find(str(inv.area) + ":" + parts[1])
				if idx != -1:
					inv.open_move.remove(idx)
			"reset_move":
				var i = 0
				while i < inv.open_move.size():
					if inv.open_move[i].begins_with(str(inv.area) + ":"):
						inv.open_move.remove(i)
					else:
						i += 1
			"open_talk":
				if !inv.open_talk.has(str(inv.area) + ":" + parts[1]):
					inv.open_talk.push_back(str(inv.area) + ":" + parts[1])
			"close_talk":
				var idx = inv.open_talk.find(str(inv.area) + ":" + parts[1])
				if idx != -1:
					inv.open_talk.remove(idx)
			"reset_talk":
				var i = 0
				while i < inv.open_talk.size():
					if inv.open_talk[i].begins_with(str(inv.area) + ":"):
						inv.open_talk.remove(i)
					else:
						i += 1
			"end_investigation", "exit_investigation":
				run_command("destroy i_*")
				run_command("return")
				run_command("return")
				state = STATE_DIALOGUE
				inv = {}
			"wait_sfx":
				parser.stop_talking()
				yield(globals, "sfx_done")
				parser.resume_talking(true)
			"wait":
				parser.stop_talking()
				var t = get_tree().create_timer(float(parts[1]))
				yield(t, "timeout")
				parser.resume_talking(true)
			"flashback":
				globals.play_sfx("flashback")
				run_command("fadeout")
				parser.stop_talking()
				yield(globals, "sfx_done")
				parser.resume_talking(true)

func conv_inv(id: String):
	var f = File.new()
	var p = id + ".json"
	if f.file_exists("user://content/inv/" + p):
		p = "user://content/inv/" + p
	else:
		p = "res://content/inv/" + p
	f.open(p, File.READ)
	inv = parse_json(f.get_as_text())
	var out = "investigation " + id
	for area in inv.areas:
		out += "\n\tarea \"" + area.name + "\" bg " + area.bg
		out += "\n\t\t\t" + area.script.replace("\n", "\n\t\t\t")
		for ex in area.examinables:
			out += "\n\t\texaminable x " + str(ex.x) + " y " + str(ex.y) + " w " + str(ex.w) + " h " + str(ex.h)
			out += "\n\t\t\t" + ex.script.replace("\n", "\n\t\t\t")
		for talk in area.talks:
			out += "\n\t\ttalk \"" + talk + "\""
			out += "\n\t\t\t" + area.talks[talk].replace("\n", "\n\t\t\t")
	out += "\nendinv"
	var fo = File.new()
	fo.open(p + ".txt", File.WRITE)
	fo.store_string(out)

func load_inv(id: String):
	var f = File.new()
	var p = id + ".json"
	if f.file_exists("user://content/inv/" + p):
		p = "user://content/inv/" + p
	else:
		p = "res://content/inv/" + p
	f.open(p, File.READ)
	inv = parse_json(f.get_as_text())
	f.close()
	inv.area = 0
	inv.id = id
	inv.examined = []
	inv.talked = []
	inv.open_move = []
	inv.open_talk = []
	bg.cur = globals.bgs[inv.areas[0].bg]

func load_inv_new(id: String):
	var area = find_command_ahead("area", parser.pos - 1)
	var end = find_command_ahead("endinv")
	inv = {areas = []}
	while area != -1 and area < end:
		var area_cmd = command_at(area)
		assert(len(area_cmd) >= 4 and area_cmd[2] == "bg")
		var until = find_command_ahead("area", area)
		if until == -1 or until > end:
			until = end
		var examinables = []
		var examp = find_command_ahead("examinable", area)
		while examp != -1 and examp < until:
			var ex_until = find_command_ahead("examinable", examp)
			if ex_until == -1 or ex_until > until:
				ex_until = find_command_ahead("talk", examp)
				if ex_until == -1 or ex_until > until:
					ex_until = until
			var ex = command_at(examp)
			assert(len(ex) >= 9 and ex[1] == "x" and ex[3] == "y" and ex[5] == "w" and ex[7] == "h")
			ex = {
				script = find_command_ahead("", examp),
				x = float(ex[2]), y = float(ex[4]), w = float(ex[6]), h = float(ex[8])
			}
			examinables.push_back(ex)
			examp = find_command_ahead("examinable", examp)
		var talks = {}
		var talkp = find_command_ahead("talk", area)
		while talkp != -1 and talkp < until:
			var talk_until = find_command_ahead("talk", talkp)
			if talk_until == -1 or talk_until > until:
				talk_until = until
			var talk = command_at(talkp)
			talks[talk[1]] = find_command_ahead("", talkp)
			talkp = find_command_ahead("talk", talkp)
		inv.areas.push_back({
			name = area_cmd[1],
			bg = area_cmd[3],
			script = find_command_ahead("", area),
			examinables = examinables,
			talks = talks
		})
		area = until
	inv.area = 0
	inv.id = id
	inv.examined = []
	inv.talked = []
	inv.open_move = []
	inv.open_talk = []
	bg.cur = globals.bgs[inv.areas[0].bg]
	state = STATE_DIALOGUE
	parser.go_to(find_command_ahead("", find_command_ahead("", find_command_ahead("endinv"))))
	push_call_stack()
	state = STATE_INVESTIGATION
	push_call_stack()
	parser.go_to(inv.areas[0].script)
	state = STATE_DIALOGUE

func _examine():
	state = STATE_INVESTIGATION_EXAMINE
	push_call_stack()
	globals.play_sfx("click")

func _move():
	state = STATE_INVESTIGATION_MOVE
	push_call_stack()
	globals.play_sfx("click")

func _inv_back():
	run_command("return")
	state = STATE_INVESTIGATION
	globals.play_sfx("back")

func _move_to(i):
	inv.area = i
	globals.play_sfx("click")
	bg.cur = globals.bgs[inv.areas[i].bg]
	state = STATE_INVESTIGATION
	push_call_stack()
	parser.go_to(inv.areas[i].script)
	state = STATE_DIALOGUE
	parser.next()

func _talk():
	state = STATE_INVESTIGATION_TALK
	globals.play_sfx("click")

func _talk_about(topic: String):
	globals.play_sfx("click")
	state = STATE_INVESTIGATION
	push_call_stack()
	parser.go_to(inv.areas[inv.area].talks[topic])
	var id = str(inv.area) + ":" + topic
	if !inv.talked.has(id):
		inv.talked.push_back(id)
	state = STATE_DIALOGUE
	parser.next()

func _seduction_deplete():
	if seductiometer == 1000:
		pass
	elif seductiometer > 2:
		seductiometer -= 2
	else:
		seductiometer = 0
		$Organizer._back()
		parser.go_to(find_command_ahead("game_over"))
		state = STATE_DIALOGUE
		parser.next()
		$Choices.visible = false
