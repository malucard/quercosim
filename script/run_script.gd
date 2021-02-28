extends RichTextLabel

func load_text_file(path):
	var p2 = OS.get_executable_path().get_base_dir() + "/script.txt"
	var f = File.new()
	if f.file_exists(p2):
		path = p2
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
		return ""
	var text = f.get_as_text()
	f.close()
	return text

var gscript = load_text_file("res://script/script.txt").replace('“', '"').replace('”', '"').replace("…", "...")

var pos = 0
var char_progress = 0
var paused = 0
var all_text = ""
var cur_text = ""
var next_text = ""
func _ready():
	state.parser = self
	state.anim = $"../../AnimationPlayer"
	state.objec_player = $"../../ObjectionPlayer"
	state.bgm = $"../../BGM"
	$"../../Gauge".visible = false
	while pos < gscript.length():
		if pos > 0 and gscript[pos - 1] == '\n':
			if gscript[pos] == '"':
				var speech = gscript.substr(pos + 1, gscript.find('"', pos + 1) - pos - 1)
				var speaker = speech.substr(0, speech.find(":")).trim_prefix(" ")
				state.speaker_name = speaker.to_lower()
				$"../Label".text = speaker
				bbcode_text = ""
				cur_text = ""
				all_text = speech.substr(speech.find(":") + 1).trim_prefix(" ")
				if all_text[0] == "(" and all_text.ends_with(")"):
					self_modulate = Color(0.5, 0.5, 1)
				elif state.in_confrontation or state.green_text:
					self_modulate = Color(0.5, 1, 0.5)
				else:
					self_modulate = Color(1, 1, 1)
				next_text = all_text
				char_progress = 0
				pos += speech.length() + 2
				match yield(self, "next"):
					0:
						if state.in_confrontation:
							pos = gscript.find("{statement", pos)
							if gscript.substr(pos, 16) == "{statement start":
								state.first_statement = true
								state.last_statement = false
							else:
								state.first_statement = false
								state.last_statement = true
					1:
						pos = gscript.rfind("{statement", pos) - 1
						pos = gscript.rfind("{statement", pos)
						if gscript.substr(pos, 16) == "{statement start":
							state.first_statement = true
							state.last_statement = false
						else:
							state.first_statement = false
							state.last_statement = true
					2:
						state.run_command("holdit")
						state.in_confrontation = false
						state.last_statement = false
						$"../../Gauge".visible = false
					[3, var x]:
						state.run_command("present " + x)
						state.in_confrontation = false
						state.last_statement = false
						$"../../Gauge".visible = false
				state.play_sfx("next")
				state.green_text = false
			elif gscript[pos] == '{':
				var cmd = gscript.substr(pos + 1, gscript.find('}', pos + 1) - pos - 1)
				pos += cmd.length() + 2
				state.run_command(cmd)
				if stopped_talking:
					yield(self, "resume_talking")
			else:
				pos += 1
		else:
			pos += 1

func go_to(to: int):
	pos = to

func lint_char(c, t: float):
	return "[color=#%02xffffff]" % min(t * 255, 255) + c + "[/color]"

const bbchar_len = 26

func progress_text(amount: float):
	char_progress += amount
	update_text()
	while char_progress > 1 and !paused:
		update_text()

func is_long_pause(s):
	return s[0] == "." or s[0] == "!" or s[0] == "?" or (s.length() > 1 and s[0] == "-" and s[1] == " ")

var blipped = false
var last_blip = 0
func blip():
	var now = OS.get_ticks_usec()
	if now >= last_blip + 3000000 / speed:
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
					paused = 0.1
				elif is_long_pause(next_text) and (next_text.length() == 1 or !is_long_pause(next_text.substr(1))):
					paused = 0.2
				elif next_text[0] == '{':
					var cmd = next_text.substr(1, next_text.find('}') - 1)
					state.run_command(cmd)
					next_text = next_text.substr(cmd.length() + 2)
					if stopped_talking:
						yield(self, "resume_talking")
					return
				cur_text += next_text[0]
				blip_if(next_text[0])
				next_text = next_text.substr(1)
				char_progress -= 1
				bbcode_text = cur_text + lint_char(next_text.substr(0, 1), char_progress)
			else:
				bbcode_text = cur_text + lint_char(next_text[0], char_progress)
		else:
			bbcode_text = cur_text + lint_char(next_text[0], char_progress)
			blip_if(next_text[0])
		var excl = next_text.find("!")
		var comma = next_text.find(",")
		var period = next_text.find(".")
		var quest = next_text.find("?")
		if excl != -1 and (comma == -1 or excl < comma) and (period == -1 or excl < period) and (quest == -1 or excl < quest):
			speed = 70
		else:
			speed = 40
	else:
		char_progress = 1
		bbcode_text = cur_text

var stopped_talking = 0
func stop_talking():
	stopped_talking += 1

signal resume_talking()
func resume_talking():
	stopped_talking -= 1
	if !stopped_talking:
		emit_signal("resume_talking")

signal next(back)

var speed = 40
onready var next_button_player = $"../NextButtonPlayer"
onready var back_button_player = $"../BackButtonPlayer"

var last_skip = 0
func try_skip():
	var time = OS.get_ticks_msec()
	if time > last_skip + 100:
		last_skip = time
		return true
	return false

func _process(delta: float):
	blipped = false
	var button_anim = "speaking"
	$"../Back".visible = state.in_confrontation
	$"../../Press".visible = state.in_confrontation
	$"../../Present".visible = state.in_confrontation
	if state.in_confrontation:
		$"../../Gauge".visible = true
	if !stopped_talking:
		if paused > 0:
			paused = max(paused - delta, 0)
		else:
			progress_text(speed * delta)
			if next_text.length() == 0:
				button_anim = "next"
		if (Input.is_action_just_pressed("back") or $"../Back/Button".pressed) and next_text.length() == 0 and !state.first_statement:
			emit_signal("next", 1)
		elif Input.is_action_pressed("skip_fast") or (Input.is_action_pressed("skip") and try_skip()) or ((Input.is_action_just_pressed("next") or $"../../Control/Next".pressed) and next_text.length() == 0) and !state.last_statement:
			emit_signal("next", 0)
		elif $"../../Press".pressed:
			emit_signal("next", 2)
		if Input.is_action_just_pressed("skip_cur") or Input.is_action_pressed("skip") or Input.is_action_pressed("skip_fast"):
			paused = 0
			bbcode_text = all_text
			while true:
				var i = bbcode_text.find("{")
				if i == -1: break
				var j = bbcode_text.find("}")
				bbcode_text = bbcode_text.substr(0, i) + bbcode_text.substr(j + 1)
			cur_text = bbcode_text
			next_text = ""
	var next_button_anim = "speaking" if state.last_statement else button_anim
	if next_button_player.current_animation != next_button_anim:
		next_button_player.play(next_button_anim)
	var back_button_anim = "speaking" if state.first_statement else button_anim
	if back_button_player.current_animation != back_button_anim:
		back_button_player.play(back_button_anim)
