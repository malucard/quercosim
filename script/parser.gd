extends RichTextLabel
class_name Parser

onready var state = $"../.."

static func load_text_file(path):
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
		return ""
	var text = f.get_as_text()
	f.close()
	return text

var script_path
var script_id
var gscript = null

func load_conf():
	var s
	var p2 = globals.user_dir + "content/script/conf.txt"
	var f = File.new()
	if f.file_exists(p2):
		s = load_text_file(p2)
	else:
		s = load_text_file("res://content/script/conf.txt")
	s = s.replace('“', '"').replace('”', '"').replace('‘', '\'').replace('’', '\'').replace("…", "...")
	var lines = s.split("\n")
	for l in lines:
		state.run_command(l.strip_edges())

func load_script(which: String = "script"):
	script_id = which
	var p2 = globals.user_dir + "content/script/" + which + ".txt"
	var f = File.new()
	if f.file_exists(p2):
		script_path = p2
	else:
		script_path = "res://content/script/" + which + ".txt"
	var s = load_text_file(script_path)
	gscript = s.replace('\r', '').replace('“', '"').replace('”', '"').replace('‘', '\'').replace('’', '\'').replace("…", "...")

var cmd_start_pos = 0
var pos = 0
var char_progress = 0
var paused = 0
var all_text = ""
var cur_text = ""
var next_text = ""
var currently_in_line = false
var start_advancing = true

func _ready():
	state.parser = self
	state.anim = $"../../AnimationPlayer"
	state.objec_player = $"../../ObjectionPlayer"
	state.bgm = $"../../BGM"
	$"../../Gauge".visible = false
	load_conf()
	if gscript == null:
		load_script()
	globals.play_sfx("next")
	if start_advancing:
		next()

var running = false
func next():
	if running:
		return
	running = true
	while pos < gscript.length():
		if state.has_tag("stop_script"):
			running = false
			return
		currently_in_line = false
		if (pos > 0 and gscript[pos - 1] == '\n') or pos == 0:
			while pos < gscript.length() and (gscript[pos] == ' ' or gscript[pos] == '\t' or gscript[pos] == '\n'):
				pos += 1
			if pos >= gscript.length():
				break
			if gscript[pos] == '"':
				currently_in_line = true
				cmd_start_pos = pos
				emit_signal("reach_cmd")
				var speech = gscript.substr(pos + 1, gscript.find('"', pos + 1) - pos - 1)
				var idx = speech.find(":")
				var speaker = speech.substr(0, idx if idx != -1 else 0).trim_prefix(" ")
				state.speaker_name = speaker
				$"../Label".text = speaker if !speaker.begins_with("#") else ""
				bbcode_text = ""
				cur_text = ""
				all_text = speech.substr(speech.find(":") + 1).trim_prefix(" ")
				if all_text[0] == "(" and all_text.ends_with(")"):
					self_modulate = Color(0.5, 0.5, 1)
				elif state.has_tag("confrontation") or state.speaker_name == "#green":
					self_modulate = Color(0.5, 1, 0.5)
				else:
					self_modulate = Color(1, 1, 1)
				next_text = all_text
				char_progress = 0
				pos += speech.length() + 2
				break
			elif gscript[pos] != "#":
				var eol = gscript.find('\n', pos + 1)
				if eol == -1:
					eol = gscript.length()
				var cmd = gscript.substr(pos, eol - pos).strip_edges()
				var speaker = null
				for s in state.speaker_aliases.keys():
					if cmd.begins_with(s + " "):
						speaker = state.speaker_aliases[s]
						break
				if speaker != null:
					print("line " + cmd)
					currently_in_line = true
					cmd_start_pos = pos
					emit_signal("reach_cmd")
					var speech = speaker + ": " + cmd.substr(cmd.find(" "))
					state.speaker_name = speaker
					$"../Label".text = speaker if !speaker.begins_with("#") else ""
					bbcode_text = ""
					cur_text = ""
					all_text = speech.substr(speech.find(":") + 1).strip_edges()
					if all_text[0] == "(" and all_text.ends_with(")"):
						self_modulate = Color(0.5, 0.5, 1)
					elif state.has_tag("confrontation") or state.speaker_name == "#green":
						self_modulate = Color(0.5, 1, 0.5)
					else:
						self_modulate = Color(1, 1, 1)
					next_text = all_text
					char_progress = 0
					pos += cmd.length()
					break
				else:
					cmd_start_pos = pos
					emit_signal("reach_cmd")
					pos += cmd.length()
					var s = state.run_command(cmd)
					if s:
						yield(s, "completed")
					if stopped_talking:
						break
			else:
				pos += 1
		else:
			pos += 1
	running = false

func _exit_tree():
	if state.parser == self:
		state.parser = null

func get_save_pos():
	var spos = 0
	var marker = "_"
	var i = 0
	var cur = ""
	var cur_ty = ""
	var cur_area = 0
	var cur_examinable = 0
	var cur_talk = 0
	var cur_stmt = 0
	while spos < pos:
		var npos = gscript.find("\n", spos)
		if npos >= pos:
			break
		var line_end = gscript.find("\n", npos + 1)
		var trimmed = gscript.substr(npos + 1, line_end - (npos + 1)).strip_edges()
		if !trimmed.empty():
			if trimmed.begins_with("#marker "):
				marker = trimmed.substr(8)
				i = 0
			elif trimmed.begins_with("investigation "):
				cur = trimmed.substr(14)
				cur_ty = "inv"
				cur_area = -1
				marker = "inv " + cur
				i = 0
			elif trimmed.begins_with("area "):
				cur_area += 1
				cur_examinable = -1
				cur_talk = -1
				marker = "inv " + cur + " area " + str(cur_area)
				i = 0
			elif trimmed.begins_with("examinable "):
				cur_examinable += 1
				marker = "inv " + cur + " area " + str(cur_area) + " examinable " + str(cur_examinable)
				i = 0
			elif trimmed.begins_with("talk "):
				cur_talk += 1
				marker = "inv " + cur + " area " + str(cur_area) + " talk " + str(cur_talk)
				i = 0
			elif trimmed.begins_with("endinv"):
				marker = "endinv " + cur
				i = 0
			elif trimmed.begins_with("request_present "):
				cur = trimmed.substr(trimmed.find(" ", 17) + 1)
				cur_ty = "rqpresent"
				marker = "rqpresent " + cur
				i = 0
			elif trimmed.begins_with("endrq"):
				marker = "endrq " + cur
				i = 0
			elif trimmed.begins_with("vs "):
				cur = trimmed.substr(trimmed.find(" ", 4) + 1)
				cur_ty = "vs"
				cur_stmt = -1
				marker = "vs " + cur
				i = 0
			elif trimmed.begins_with("endvs"):
				marker = "endvs " + cur
				i = 0
			elif trimmed.begins_with("game_over"):
				marker = "game_over_" + cur_ty + " " + cur
				i = 0
			elif trimmed.begins_with("stmt"):
				cur_stmt += 1
				marker = "vs " + cur + " stmt " + str(cur_stmt)
				i = 0
			elif trimmed.begins_with("wrong_present"):
				marker = "vs " + cur + " wrong_present"
				i = 0
			elif trimmed[0] != '#':
				i += 1
		spos = npos + 1
	print(str(i))
	print(marker)
	return [i, marker]

func go_to_save_pos(to: int, target_marker: String):
	pos = 0
	var marker = "_"
	var i = 0
	var cur = ""
	var cur_ty = ""
	var cur_area = 0
	var cur_examinable = 0
	var cur_talk = 0
	var cur_stmt = 0
	while !(marker == target_marker and i >= to):
		var npos = gscript.find("\n", pos)
		var line_end = gscript.find("\n", npos + 1)
		var trimmed = gscript.substr(npos + 1, line_end - (npos + 1)).strip_edges()
		if !trimmed.empty():
			if marker != target_marker:
				if trimmed.begins_with("#marker "):
					marker = trimmed.substr(8)
					i = 0
				elif trimmed.begins_with("investigation "):
					cur = trimmed.substr(14)
					cur_ty = "inv"
					cur_area = -1
					marker = "inv " + cur
					i = 0
				elif trimmed.begins_with("area "):
					cur_area += 1
					cur_examinable = -1
					cur_talk = -1
					marker = "inv " + cur + " area " + str(cur_area)
					i = 0
				elif trimmed.begins_with("examinable "):
					cur_examinable += 1
					marker = "inv " + cur + " area " + str(cur_area) + " examinable " + str(cur_examinable)
					i = 0
				elif trimmed.begins_with("talk "):
					cur_talk += 1
					marker = "inv " + cur + " area " + str(cur_area) + " talk " + str(cur_talk)
					i = 0
				elif trimmed.begins_with("endinv"):
					marker = "endinv " + cur
					i = 0
				elif trimmed.begins_with("request_present "):
					cur = trimmed.substr(trimmed.find(" ", 17) + 1)
					cur_ty = "rqpresent"
					marker = "rqpresent " + cur
					i = 0
				elif trimmed.begins_with("endrq"):
					marker = "endrq " + cur
					i = 0
				elif trimmed.begins_with("vs "):
					cur = trimmed.substr(trimmed.find(" ", 4) + 1)
					cur_ty = "vs"
					cur_stmt = -1
					marker = "vs " + cur
					i = 0
				elif trimmed.begins_with("endvs"):
					marker = "endvs " + cur
					i = 0
				elif trimmed.begins_with("game_over"):
					marker = "game_over_" + cur_ty + " " + cur
					i = 0
				elif trimmed.begins_with("stmt"):
					cur_stmt += 1
					marker = "vs " + cur + " stmt " + str(cur_stmt)
					i = 0
				elif trimmed.begins_with("wrong_present"):
					marker = "vs " + cur + " wrong_present"
					i = 0
				elif trimmed[0] != '#':
					i += 1
			elif trimmed[0] != '#':
				i += 1
		pos = npos + 1

func go_to(to: int):
	pos = to

func lint_char(c, t: float):
	if paused or c == "[" or c == "{":
		return " "
	return "[color=#%02xffffff]" % min(t * 255, 255) + c + "[/color]"

const bbchar_len = 26

func progress_text(amount: float):
	char_progress += amount
	var done = next_text.empty()
	update_text()
	while char_progress > 1 and !paused:
		update_text()
	if !done and next_text.empty():
		$"../../Backlog".push_message($"../Label".text, cur_text)

func is_long_pause(s):
	return s.length() > 1 and s[1] != ")" and (s[0] == "." or s[0] == "!" or s[0] == "?" or (s[0] == "-" and s[1] == " "))

var blipped = false
var last_blip = 0
func blip():
	var now = OS.get_ticks_usec()
	var st = preload("res://sounds/blipm.wav")
	if state.speaker_name == "#green":
		st = preload("res://sounds/blipt.wav")
	elif state.speaker_name in globals.speaker_map:
		var c = globals.speaker_map[state.speaker_name]
		if "gender" in c and c.gender == "f":
			st = preload("res://sounds/blipf.wav")
	if st != $"../../AudioStreamPlayer".stream:
		$"../../AudioStreamPlayer".stream = st
	if now >= last_blip + 3000000 / (speed / 3 * 2):
		last_blip = now
		$"../../AudioStreamPlayer".volume_db = linear2db(0.25)
		$"../../AudioStreamPlayer".play(0)
	blipped = true

func is_blip(c):
	return c.is_valid_identifier() or c.is_valid_integer()

func blip_if(c):
	if is_blip(c):
		blip()

func update_text():
	if next_text.length() != 0:
		if next_text[0] == '[':
			var cmd = next_text.substr(0, next_text.find(']') + 1)
			cur_text += cmd
			next_text = next_text.substr(cmd.length())
			if next_text.empty():
				return
		if bbcode_text.length() != 0:
			if char_progress > 1:
				if next_text[0] == ",":
					paused = 0.05
				elif is_long_pause(next_text) and (next_text.length() == 1 or !is_long_pause(next_text.substr(1))):
					paused = 0.1
				elif next_text[0] == '{':
					var cmd = next_text.substr(1, next_text.find('}') - 1)
					next_text = next_text.substr(cmd.length() + 2)
					if cmd.begins_with("var "):
						next_text = str(state.vars[cmd.substr(4)]) + next_text
					else:
						var s = state.run_command(cmd)
						if s:
							yield(s, "completed")
#						if stopped_talking:
#							yield(self, "resume_talking")
					return
				cur_text += next_text[0]
				blip_if(next_text[0])
				next_text = next_text.substr(1)
				char_progress -= 1
				var n = cur_text + lint_char(next_text.substr(0, 1), char_progress)
				if bbcode_text != n:
					bbcode_text = n
			else:
				var n = cur_text + lint_char(next_text[0], char_progress)
				if bbcode_text != n:
					bbcode_text = n
		else:
			var n = cur_text + lint_char(next_text[0], char_progress)
			if bbcode_text != n:
				bbcode_text = n
			blip_if(next_text[0])
		var excl = next_text.find("!")
		var comma = next_text.find(",")
		var period = next_text.find(".")
		var quest = next_text.find("?")
		if excl != -1 and (comma == -1 or excl < comma) and (period == -1 or excl < period) and (quest == -1 or excl < quest):
			speed = TEXT_SPEED_FAST
		else:
			speed = TEXT_SPEED_NORMAL
	else:
		char_progress = 1
		if bbcode_text != cur_text:
			bbcode_text = cur_text

var stopped_talking = 0
func stop_talking():
	stopped_talking += 1

signal resume_talking()
func resume_talking(advance: bool = false):
	if stopped_talking:
		stopped_talking -= 1
		if !stopped_talking:
			emit_signal("resume_talking")
			if advance:
				next()

signal reach_cmd()

const TEXT_SPEED_FAST = 70 + 35
const TEXT_SPEED_NORMAL = 40 + 20
var speed = TEXT_SPEED_NORMAL
onready var next_button_player = $"../NextButtonPlayer"
onready var back_button_player = $"../BackButtonPlayer"

var last_skip = 0
func try_skip():
	var time = OS.get_ticks_msec()
	if time > last_skip + 100:
		last_skip = time
		return true
	return false

var prev_next_pressed = false
var next_just_pressed = false
var next_pressed_start = 0

func _process(delta: float):
	var button_anim = "speaking"
	$"../Back".visible = state.has_tag("confrontation")
	$"../../Press".visible = state.has_tag("confrontation")
	$"../../Present".visible = state.has_tag("confrontation")
	$"../../Control/Next".visible = state.has_tag("show_dialogue")
	var next_pressed = $"../../Control/Next".pressed
	next_just_pressed = !prev_next_pressed and next_pressed and state.has_tag("show_dialogue")
	if next_just_pressed:
		next_pressed_start = OS.get_ticks_msec()
	prev_next_pressed = next_pressed
	var mobile_skipping = OS.has_feature("mobile") and next_pressed and OS.get_ticks_msec() - next_pressed_start >= 1000
	if state.has_tag("show_gauge"):
		$"../../Gauge".visible = true
	if paused > 0:
		progress_text(0)
		paused = max(paused - delta, 0)
	else:
		progress_text(speed * delta)
	if next_text.length() == 0:
		button_anim = "next"
	if (!stopped_talking or state.has_tag("choice")) and !running:
		if Input.is_action_just_pressed("backlog") and !$"../../Backlog".visible:
			$"../../Backlog"._open_backlog()
		elif Input.is_action_just_pressed("organizer") and !$"../../Organizer".visible:
			if $"../../Present".visible:
				$"../../Organizer"._open_present()
			else:
				$"../../Organizer"._open()
		elif Input.is_action_just_pressed("save") and !$"../../SaveMenu".visible and (!$"../../Organizer".detail if $"../../Organizer".visible else true):
			$"../../SaveMenu"._open()
		elif !stopped_talking and !running:
			if (Input.is_action_just_pressed("back") or $"../Back/Button".pressed
				) and next_text.length() == 0 and state.has_tag("confrontation") and !state.has_tag("first_statement"):
				var start = state.find_command_behind("vs")
				var prev_stmt = state.find_command_behind("stmt", state.find_command_behind("stmt"))
				while true:
					if prev_stmt == -1 or prev_stmt < start:
						prev_stmt = null
						break
					var cmd = state.command_at(prev_stmt)
					if cmd.size() > 2 and cmd[1] == "if":
						var cnd = !state.vars.get(cmd[2].substr(1)) if cmd[2].begins_with("!") else (true if state.vars.get(cmd[2]) else false)
						if cnd:
							break
						else:
							prev_stmt = state.find_command_behind("stmt", prev_stmt)
					else:
						break
				if prev_stmt:
					go_to(prev_stmt)
					globals.play_sfx("next")
					next()
			elif state.has_tag("show_dialogue") and (Input.is_action_pressed("skip_fast") or ((Input.is_action_pressed("skip") or mobile_skipping) and try_skip())
				or Input.is_action_just_pressed("next") or next_just_pressed
				) and next_text.length() == 0 and !state.has_tag("last_statement"):
				if state.has_tag("confrontation"):
					go_to(state.find_command_ahead("stmt"))
				globals.play_sfx("next")
				next()
				next_just_pressed = false
			elif $"../../Press".visible and ($"../../Press".pressed or Input.is_action_just_pressed("press")) and next_text.length() == 0:
				var s = state.run_command("holdit")
				if s:
					yield(s, "completed")
				if state.has_tag("show_seduction"):
					state.state = State.STATE_SEDUCTION_DIALOGUE
				else:
					state.state = State.STATE_DIALOGUE
			if !running and next_text.length() != 0 and ((Input.is_action_pressed("skip_cur") or next_just_pressed) or mobile_skipping or Input.is_action_pressed("skip") or Input.is_action_pressed("skip_fast")):
				paused = 0
				bbcode_text = ""
				var txt = all_text
				var last = 0
				while true:
					var i = txt.find("{", last)
					if i == -1:
						bbcode_text += txt.substr(last)
						break
					var j = txt.find("}", i)
					bbcode_text += txt.substr(last, i - last)
					var cmd = txt.substr(i + 1, j - i - 1)
					if cmd.begins_with("var "):
						bbcode_text += str(state.vars[cmd.substr(4)])
					else:
						var s = state.run_command(cmd)
						if s:
							yield(s, "completed")
					last = j + 1
					if stopped_talking:
						cur_text = bbcode_text
						next_text = ""
						yield(self, "resume_talking")
				cur_text = bbcode_text
				next_text = ""
				$"../../Backlog".push_message($"../Label".text, cur_text)
	var next_button_anim = "speaking" if state.has_tag("last_statement") or stopped_talking or running else button_anim
	if next_button_player.current_animation != next_button_anim:
		next_button_player.play(next_button_anim)
	var back_button_anim = "speaking" if state.has_tag("first_statement") or stopped_talking or running else button_anim
	if back_button_player.current_animation != back_button_anim:
		back_button_player.play(back_button_anim)
	var fixed_bbcode_text = bbcode_text.replace("[h]", "[color=#FF4400]").replace("[/h]", "[/color]")
	if fixed_bbcode_text != bbcode_text:
		bbcode_text = fixed_bbcode_text

func _meta_clicked(meta):
	OS.shell_open(meta)
