extends Control

onready var vpc = $HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer
onready var vp = $HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport
onready var main = $HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport/Main
onready var line_editor = $HBoxContainer/VBoxContainer/VBoxContainer/TextEdit

var state
var cur_script = "res://content/script/script.txt"
var cur_cmd_line = ""
var stepping = false
var last_pos = 0
var snapshots = []
var gscript = Parser.load_text_file(cur_script)

func create_snapshot():
	var bg
	var lchar
	var rchar
	var bgm
	# find the ids of the textures
	if state.bg.cur:
		for id in state.bg.bgs:
			if state.bg.bgs[id] == state.bg.cur:
				bg = id
				break
	if state.lchar:
		for ch in globals.chars:
			if globals.chars[ch] == state.lchar:
				var found = false
				for pose in state.lchar.poses:
					if state.lchar.poses[pose] == state.lchar.pose:
						lchar = {id = ch, pose = pose}
						found = true
						break
				if found:
					break
	if state.rchar:
		for ch in globals.chars:
			if globals.chars[ch] == state.rchar:
				var found = false
				for pose in state.rchar.poses:
					if state.rchar.poses[pose] == state.rchar.pose:
						rchar = {id = ch, pose = pose}
						found = true
						break
				if found:
					break
	if state.bgm.stream:
		for id in globals.music:
			if globals.music[id] == state.bgm.stream:
				bgm = id
				break
	return {
		pos = state.parser.pos,
		vars = state.vars.duplicate(false),
		evidence = state.evidence.duplicate(false),
		profiles = state.profiles.duplicate(false),
		call_stack = state.call_stack.duplicate(false),
		health = state.health,
		side = state.bg.side,
		bg = bg,
		lchar = lchar,
		rchar = rchar,
		bgm = bgm,
		state = state.state,
		modulate = state.parser.get_node("../../Control").modulate
	}

func load_snapshot(snap):
	state.parser.pos = snap.pos - 1
	state.health = snap.health
	state.vars = snap.vars
	state.evidence = snap.evidence
	state.profiles = snap.profiles
	state.call_stack = snap.call_stack
	state.state = snap.state
	state.parser.get_node("../../Control").modulate = snap.modulate
	state.bg.cur = state.bg.bgs[snap.bg] if snap.bg else null
	state.bg.side = snap.side
	state.bg.t = 0 if state.bg.side else 1
	if snap.lchar:
		state.lchar = globals.chars[snap.lchar.id]
		state.lchar.pose = state.lchar.poses[snap.lchar.pose]
	else:
		state.lchar = null
	if snap.rchar:
		state.rchar = globals.chars[snap.rchar.id]
		state.rchar.pose = state.rchar.poses[snap.rchar.pose]
	else:
		state.rchar = null
	if snap.bgm:
		var bgm
		if state.bgm.stream:
			for id in globals.music:
				if globals.music[id] == state.bgm.stream:
					bgm = id
					break
		if bgm != snap.bgm:
			$HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport/Main/BGM.stream = globals.music[snap.bgm]
			$HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport/Main/BGM.play()
			state.music_start = OS.get_ticks_usec()

func _reach_cmd():
	var pos = state.parser.cmd_start_pos
	if last_pos and pos > last_pos:
		snapshots.push_back(create_snapshot())
	last_pos = pos
	var gscript = state.parser.gscript
	if (pos > 0 and gscript[pos - 1] == '\n') or pos == 0:
		if gscript[pos] == '"':
			cur_cmd_line = gscript.substr(pos, gscript.find('"', pos + 1) - pos + 1)
		elif gscript[pos] == '{':
			cur_cmd_line = gscript.substr(pos, gscript.find('}', pos + 1) - pos + 1)

func _ready():
	$HBoxContainer/VBoxContainer/VBoxContainer/WholeScript.text = gscript

func scale_down(n: Control, pivot: Vector2):
	n.rect_scale = Vector2(0.75, 0.75)
	n.rect_pivot_offset = n.rect_size * pivot

func _process(delta: float):
#	var nx = vpc.rect_size.y * 16 / 9
#	if nx < vpc.rect_size.x:
#		vpc.rect_size.x = nx
#	else:
#		var ny = vpc.rect_size.x * 9 / 16
#		if ny < vpc.rect_size.y:
#			vpc.rect_size.y = ny
	#vpc.stretch_shrink = 0.5
	#vp.size = vpc.rect_size * 1.75
	#if vp.size.y < 320:
	#	vp.size = vp.size * 2
	line_editor.text = cur_cmd_line
	if state:
		$HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport.gui_disable_input = $FileDialog.visible
		$HBoxContainer/VBoxContainer2/Test.visible = false
		$HBoxContainer/VBoxContainer2/Stepping.visible = true
		scale_down($HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport/Main/TextureRect, Vector2(0.5, 1))
		scale_down($HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport/Main/HBoxContainer, Vector2(1, 0))
	else:
		$HBoxContainer/VBoxContainer2/Test.visible = true
		$HBoxContainer/VBoxContainer2/Stepping.visible = false
	if stepping:
		$HBoxContainer/VBoxContainer2/Stepping/Stepping.text = "Stepping"
		$HBoxContainer/VBoxContainer2/Stepping/Resume.text = "Resume"
	else:
		$HBoxContainer/VBoxContainer2/Stepping/Stepping.text = "Running"
		$HBoxContainer/VBoxContainer2/Stepping/Resume.text = "Pause"
	if state and state.parser.script_path != cur_script:
		_save_script()
		cur_script = state.parser.script_path
		gscript = state.parser.gscript
		$HBoxContainer/VBoxContainer/VBoxContainer/WholeScript.text = gscript
	else:
		gscript = $HBoxContainer/VBoxContainer/VBoxContainer/WholeScript.text
	if state:
		state.parser.gscript = gscript
		vpc.visible = true
	else:
		vpc.visible = false
	$HBoxContainer/VBoxContainer2/File.text = cur_script

func _step_back():
	if !stepping:
		state.parser.stop_talking()
		stepping = true
	if snapshots.size() > 1:
		load_snapshot(snapshots[snapshots.size() - 2])
		snapshots.pop_back()
		if state.parser.currently_in_line:
			state.parser.emit_signal("next")
		else:
			state.parser.emit_signal("resume_talking")

func _step_one():
	if !stepping:
		state.parser.stop_talking()
		stepping = true
	if state.parser.currently_in_line:
		state.parser.emit_signal("next")
	else:
		state.parser.emit_signal("resume_talking")

func _resume():
	if stepping:
		state.parser.resume_talking()
		stepping = false
	else:
		state.parser.stop_talking()
		stepping = true

func _add_command():
	#$AddCmdPopup.add_item("Message")
	#$AddCmdPopup.add_item("Character")
	#$AddCmdPopup.add_item("Pose")
	$AddCmdPopup.popup()

func _test():
	if !state:
		state = preload("res://main.tscn").instance()
		var parser = state.get_node("TextureRect/RunScript")
		parser.script_path = cur_script
		parser.script_id = cur_script.trim_suffix(".txt").trim_prefix("user://content/script/")
		parser.gscript = gscript
		$HBoxContainer/VBoxContainer/AspectRatioContainer/ViewportContainer/Viewport.add_child(state)
		parser.connect("reach_cmd", self, "_reach_cmd")

func _close():
	get_tree().change_scene("res://title_screen.tscn")

func _stop():
	if state:
		state.queue_free()
		state = null

func _switch_script():
	$FileDialog.popup_centered()

func _reload_script():
	var f = File.new()
	if f.file_exists(cur_script):
		f.open(cur_script, File.READ)
		gscript = f.get_as_text()
	else:
		gscript = ""
	$HBoxContainer/VBoxContainer/VBoxContainer/WholeScript.text = gscript

func _save_script():
	#var f = File.new()
	#f.open(cur_script, File.WRITE)
	#f.store_string(gscript)
	pass

func _select_script(path):
	var f = File.new()
	#f.open(cur_script, File.WRITE)
	#f.store_string(gscript)
	cur_script = path
	#f = File.new()
	if f.file_exists(cur_script):
		f.open(cur_script, File.READ)
		gscript = f.get_as_text()
	else:
		gscript = ""
	$HBoxContainer/VBoxContainer/VBoxContainer/WholeScript.text = gscript
