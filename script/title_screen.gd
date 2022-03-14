extends Control

var version = Parser.load_text_file("res://version.txt").strip_edges()

# future proofing just in case
const server_links = [
	"https://raw.githubusercontent.com/malucard/quercosim/main/server/version.json",
	"https://raw.githubusercontent.com/quercosim/quercosim/main/server/version.json",
	"https://raw.githubusercontent.com/quercosim/quercosim_server/main/server/version.json"
]

func _ready():
	if globals.controller:
		$Buttons/NewGame.grab_focus()
	$ImportDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	$ExportDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
#	assert(cmp_semver("1.0.0", "1.0.0-pre2") == 1)
#	assert(cmp_semver("1.0.0-pre2", "1.0.0-pre1") == 1)
#	assert(cmp_semver("1.3.0-pre4", "1.4.0-alpha") == -1)
#	assert(cmp_semver("1.3.0-pre4", "1.3.0-alpha5") == 1)
#	assert(cmp_semver("1.0.0-pre1", "1.0.0-pre") == 0)
#	assert(cmp_semver("0.7.1-pre1", "0.7.1") == -1)
#	assert(cmp_semver("0.7.1-pre1", "0.7.1-rc4") == -1)
#	assert(cmp_semver("0.7.1-rc1", "0.7.1-pre4") == 1)
	print(OS.get_name())
	var req = HTTPRequest.new()
	add_child(req)
	link_node = null
	trying_server = 0
	req.connect("request_completed", self, "_req_done", [req])
	next_server(req)
	#_req_done(0,0,0, """""".to_utf8())
	$Version/Label.bbcode_text = "[right]v" + version

const order = ["alpha", "beta", "pre", "rc", ""]
func find_num(s: String):
	for i in range(0, len(s)):
		if s[i].is_valid_integer():
			return [s.substr(0, i), int(s.substr(i))]
	return [s, 1]

# 1: v1 > v2
# 0: v1 = v2
# -1: v1 < v2
func cmp_semver(v1: String, v2: String):
	var hi1 = v1.find("-")
	var h1 = ""
	var hv1 = 1
	if hi1 != -1:
		h1 = v1.substr(hi1 + 1)
		v1 = v1.substr(0, hi1)
		hv1 = find_num(h1)
		h1 = hv1[0]
		hv1 = hv1[1]
	var hi2 = v2.find("-")
	var h2 = ""
	var hv2 = 1
	if hi2 != -1:
		h2 = v2.substr(hi2 + 1)
		v2 = v2.substr(0, hi2)
		hv2 = find_num(h2)
		h2 = hv2[0]
		hv2 = hv2[1]
	var a1 = v1.split(".")
	var a2 = v2.split(".")
	for i in range(0, min(len(a1), len(a2))):
		var a = int(a1[i])
		var b = int(a2[i])
		if a > b:
			return 1
		if b > a:
			return -1
	if len(a1) > len(a2):
		for i in range(len(a2), len(a1)):
			if int(a1[i]) > 0:
				return 1
	elif len(a2) > len(a1):
		for i in range(len(a1), len(a2)):
			if int(a2[i]) > 0:
				return -1
	if h1 == h2:
		return 1 if hv1 > hv2 else (-1 if hv2 > hv1 else 0)
	if h2 != "" and (h1 == "" or h1.ord_at(0) > h2.ord_at(0)):
		return 1
	if h2 == "" or h2.ord_at(0) > h1.ord_at(0):
		return -1
	return 0

var link_node = null
var trying_server = 0
func next_server(req: HTTPRequest, err = null):
	while err != OK:
		if trying_server >= len(server_links) - 1:
			push_error("error checking version online")
			return
		err = req.request(server_links[trying_server])
		if err == OK:
			print(server_links[trying_server])
		trying_server += 1

func _req_done(res, res_code, headers, body, req):
	var response = parse_json(body.get_string_from_utf8())
#	var f = File.new()
#	f.open("res://server/version.json", File.READ)
#	response = parse_json(f.get_as_text())
#	f.close()
	if typeof(response) != TYPE_DICTIONARY:
		print("failed")
		next_server(req)
		return
	var os = OS.get_name().to_lower()
	if "redirect" in response:
		next_server(req.request(response.redirect))
	else:
		var newver = response.latest[os] if os in response.latest else response.latest.all
		var links = newver.links if "links" in newver else []
		# "cond_suffix": [["<0.3", " - Chapter 3 & 4 released"], ["0.3&<0.4", " - Chapter 4 released"]]
		var desc = newver.suffix if "suffix" in newver else ""
		if "cond_suffix" in newver:
			for cs in newver.cond_suffix:
				var conds = cs[0].split("&")
				var passed = true
				for c in conds:
					if c[0] == "<":
						if cmp_semver(version, c.substr(1)) != -1:
							passed = false
							break
					elif c[0] == "=":
						if cmp_semver(version, c.substr(1)) != 0:
							passed = false
							break
					elif c[0].is_valid_integer():
						if cmp_semver(version, c) == -1:
							passed = false
							break
				if passed:
					desc += cs[1]
		newver = newver.name
		if cmp_semver(newver, version) != 1:
			return
		$Version/Update/Bg/VBoxContainer/Label.bbcode_text = "Latest: v" + newver + desc
		if !links.empty():
			for title in links:
				var link = response.links[title]
				if os in link:
					link = link[os]
				elif "all" in link:
					link = link.all
				else:
					continue
				var l = LinkButton.new()
				l.connect("mouse_entered", l, "grab_focus")
				l.mouse_default_cursor_shape = CURSOR_POINTING_HAND
				if link_node:
					var comma = Label.new()
					comma.text = ", "
					$Version/Update/Bg/VBoxContainer/HBoxContainer.add_child(comma)
				else:
					link_node = l
				var i = title.find("#")
				if i != -1:
					l.text = title.substr(0, i)
				else:
					l.text = title
				l.focus_mode = FOCUS_ALL
				l.connect("pressed", OS, "shell_open", [link])
				$Version/Update/Bg/VBoxContainer/HBoxContainer.add_child(l)

func _process(delta):
	if globals.mobile:
		$ImportDialog.rect_scale = Vector2(1.5, 1.5)
		$ImportDialog.anchor_right = 2.0 / 3.0
		$ImportDialog.anchor_bottom = 2.0 / 3.0
		$ExportDialog.rect_scale = Vector2(1.5, 1.5)
		$ExportDialog.anchor_right = 2.0 / 3.0
		$ExportDialog.anchor_bottom = 2.0 / 3.0
	else:
		$ImportDialog.rect_scale = Vector2(1, 1)
		$ImportDialog.anchor_right = 1.0
		$ImportDialog.anchor_bottom = 1.0
		$ExportDialog.rect_scale = Vector2(1, 1)
		$ExportDialog.anchor_right = 1.0
		$ExportDialog.anchor_bottom = 1.0
	if link_node:
		var min_size = $Version/Update/Bg/VBoxContainer.get_minimum_size() + Vector2(128, 64)
		$Version/Update.rect_min_size = min_size
		$Version/Update/Bg.rect_min_size = min_size
		$Version/Update.visible = true
	$Version/Update/Bg/VBoxContainer/HBoxContainer/Xbox.visible = globals.controller and $Version/Update/Bg/VBoxContainer/HBoxContainer.get_child_count() > 1
	if $LoadMenu.visible:
		if !$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon.has_focus() \
			and !$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon2.has_focus() \
			and !$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon3.has_focus() \
			and !$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon4.has_focus():
			if Input.is_action_just_pressed("ui_down"):
				$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon.grab_focus()
			elif Input.is_action_just_pressed("ui_up"):
				$LoadMenu/VBoxContainer/TextureRect/VBoxContainer/SaveIcon4.grab_focus()
		else:
			if Input.is_action_just_pressed("ui_left"):
				$LoadMenu._prev_page()
			elif Input.is_action_just_pressed("ui_right"):
				$LoadMenu._next_page()
	elif !$Buttons/NewGame.has_focus() \
		and !$Buttons/Continue.has_focus() \
		and !$Buttons/Shortcut.has_focus() \
		and !$Buttons/Extras.has_focus() \
		and (!is_instance_valid(get_focus_owner()) or !$Version.is_a_parent_of(get_focus_owner())) \
		and (globals.controller or Input.is_action_just_pressed("ui_down")):
		$Buttons/NewGame.grab_focus()
	if $LoadMenu.visible or $Extras.visible or $Shortcut.visible:
		$Buttons/NewGame.release_focus()
		$Buttons/Continue.release_focus()
		$Buttons/Shortcut.release_focus()
		$Buttons/Extras.release_focus()
		if Input.is_action_just_pressed("ui_cancel"):
			if $LoadMenu.visible:
				$LoadMenu._back()
			if $Extras.visible:
				_close_extras()
			if $Shortcut.visible:
				_close_shortcut()
	else:
		if link_node and Input.is_action_just_pressed("download_update"):
			if $Version/Update.is_a_parent_of(get_focus_owner()):
				$Buttons/NewGame.grab_focus()
			else:
				link_node.grab_focus()
	$ImportDialog.margin_left = 0
	$ImportDialog.margin_top = 0
	$ImportDialog.margin_right = 0
	$ImportDialog.margin_bottom = 0
	$ExportDialog.margin_left = 0
	$ExportDialog.margin_top = 0
	$ExportDialog.margin_right = 0
	$ExportDialog.margin_bottom = 0

func _new_game():
	globals.play_sfx("save_load")
	get_tree().change_scene("res://main.tscn")

func _shortcut():
	globals.play_sfx("organizer")
	$AnimationPlayer.play("show_shortcut")

func _close_shortcut():
	globals.play_sfx("back")
	$AnimationPlayer.play("hide_shortcut")

var main_scn = load("res://main.tscn")
func _play_shortcut(which: int):
	globals.play_sfx("save_load")
	if which == -1:
		var new_main = main_scn.instance()
		var parser = new_main.get_node("TextureRect/RunScript")
		parser.load_script("debug")
		get_tree().current_scene.queue_free()
		get_tree().get_root().add_child(new_main)
		get_tree().current_scene = new_main
	elif which == 1:
		get_tree().change_scene("res://main.tscn")
	else:
		var new_main = main_scn.instance()
		var parser = new_main.get_node("TextureRect/RunScript")
		parser.load_script("script_ch" + str(which))
		get_tree().current_scene.queue_free()
		get_tree().get_root().add_child(new_main)
		get_tree().current_scene = new_main

func _editor():
	globals.play_sfx("save_load")
	get_tree().change_scene("res://editor.tscn")

func _inv_editor():
	globals.play_sfx("save_load")
	get_tree().change_scene("res://investigation_bg_checker.tscn")

func _extras():
	globals.play_sfx("organizer")
	$AnimationPlayer.play("show_extras")

func _close_extras():
	globals.play_sfx("back")
	$AnimationPlayer.play("hide_extras")

func _import():
	globals.play_sfx("click")
	$ImportDialog.popup_centered()

func _export():
	globals.play_sfx("click")
	$ExportDialog.popup_centered()

func import_file(f: File, path):
	if f.eof_reached():
		return false
	while !f.eof_reached():
		match f.get_8():
			1:
				var fn = f.get_pascal_string()
				var s = f.get_32()
				var of = File.new()
				of.open(path + fn, File.WRITE)
				of.store_buffer(f.get_buffer(s))
				of.close()
			2:
				var fn = f.get_pascal_string()
				var od = Directory.new()
				od.make_dir(path + fn)
				import_file(f, path + fn + "/")
			3:
				return false
	return true

var albasig = PoolByteArray(['A'.ord_at(0), 'L'.ord_at(0), 'B'.ord_at(0), 'A'.ord_at(0), 0, 0, 0, 0])

func _import_ok(path):
	$BlackScreen.visible = true
	$BlackScreen/Label.text = "Importing"
	var d = Directory.new()
	if d.open(globals.user_dir + "content") != OK:
		d.make_dir(globals.user_dir + "content")
	var f = File.new()
	if f.open_compressed(path, File.READ, File.COMPRESSION_ZSTD) != OK:
		$BlackScreen/Label.text = "failed to open file\n" + path
		printerr("failed to open file " + path)
	else:
		var sig = f.get_buffer(8)
		if sig != albasig:
			$BlackScreen/Label.text = "unsupported file\n" + path + "\nsignature: " + sig.hex_encode()
			printerr("unsupported file " + path + " sig " + sig.hex_encode())
			f.close()
		else:
			yield(get_tree(), "idle_frame")
			while import_file(f, globals.user_dir + "content/"):
				pass
			f.close()
			$BlackScreen/Label.text = "Imported\nPlease restart the game to load changes."
	yield(get_tree().create_timer(2.0), "timeout")
	$BlackScreen.visible = false

func get_all_files_in(dir):
	var d = Directory.new()
	d.open(dir)
	d.list_dir_begin(true)
	var arr = []
	var fn = d.get_next()
	while fn != "":
		if d.current_is_dir() and fn != "." and fn != "..":
			arr.push_back([fn, get_all_files_in(dir + "/" + fn)])
		else:
			arr.push_back(fn)
		fn = d.get_next()
	return arr

func get_all_content_files():
	var files = []
	var d = Directory.new()
	d.open(globals.user_dir + "content")
	d.list_dir_begin(true)
	var fn = d.get_next()
	while fn != "":
		if d.current_is_dir():
			if fn == "evidence" or fn == "profiles" or fn == "bg" or fn == "embed" or fn == "sfx" or fn == "music" or fn == "videos":
				files.push_back([fn, get_all_files_in(globals.user_dir + "content/" + fn)])
			elif fn == "char":
				var arr = []
				var d2 = Directory.new()
				d2.open(globals.user_dir + "content/char")
				d2.list_dir_begin(true)
				var fn2 = d2.get_next()
				while fn2 != "":
					if d2.current_is_dir():
						arr.push_back([fn2, get_all_files_in(globals.user_dir + "content/char/" + fn2)])
					fn2 = d2.get_next()
				d2.list_dir_end()
				if !arr.empty():
					files.push_back(["char", arr])
			elif fn == "script":
				var arr = []
				var d2 = Directory.new()
				d2.open(globals.user_dir + "content/script")
				d2.list_dir_begin(true)
				var fn2 = d2.get_next()
				while fn2 != "":
					if !d2.current_is_dir() and fn2.ends_with(".txt"):
						arr.push_back(fn2)
					fn2 = d2.get_next()
				d2.list_dir_end()
				if !arr.empty():
					files.push_back(["script", arr])
		fn = d.get_next()
	d.list_dir_end()
	return files

var exported_bytes = 0
func add_to_file(outf, files, path):
	for fn in files:
		if typeof(fn) == TYPE_ARRAY:
			outf.store_8(2)
			outf.store_pascal_string(fn[0])
			add_to_file(outf, fn[1], path + fn[0] + "/")
			outf.store_8(3)
		else:
			var f = File.new()
			f.open(path + fn, File.READ)
			outf.store_8(1)
			outf.store_pascal_string(fn)
			var buf = f.get_buffer(f.get_len())
			outf.store_32(buf.size())
			exported_bytes += buf.size()
			outf.store_buffer(buf)
			f.close()
			#print("written " + path + fn + " of " + str(buf.size()))
			$BlackScreen/Label.text = "Exporting\n" + str(exported_bytes / 1000) + " KiB"

func _export_ok(path):
	#var files = {}
	#var inf = File.new()
	var d = Directory.new()
	if d.open(globals.user_dir + "content") == OK:
		exported_bytes = 0
		$BlackScreen.visible = true
		$BlackScreen/Label.text = "Exporting"
		var outf = File.new()
		var files = get_all_content_files()
		outf.open_compressed(path, File.WRITE, File.COMPRESSION_ZSTD)
		outf.store_string("ALBA")
		outf.store_32(0)
		add_to_file(outf, files, globals.user_dir + "content/")
		outf.close()
		$BlackScreen/Label.text = "Exported"
		yield(get_tree().create_timer(1.0), "timeout")
		$BlackScreen.visible = false
	else:
		$BlackScreen.visible = true
		$BlackScreen/Label.text = "no content directory"
		yield(get_tree().create_timer(1.0), "timeout")
		$BlackScreen.visible = false
	#outf.store_string("")
	#outf.close()
	#f.store_string(to_json())

func _open_folder():
	var d = Directory.new()
	if d.open(globals.user_dir + "content") != OK:
		d.make_dir(globals.user_dir + "content")
	OS.shell_open(ProjectSettings.globalize_path(globals.user_dir + "content"))

func _delete_content():
	globals.play_sfx("click")
	$DeleteDialog.popup_centered()

func delete_dir(path: String):
	var h = Directory.new()
	print(path)
	if h.open(path) != OK:
		return
	h.list_dir_begin(true)
	var fn = h.get_next()
	while fn != "":
		if h.current_is_dir() and fn != "." and fn != "..":
			delete_dir(path + "/" + fn)
		else:
			h.remove(fn)
		fn = h.get_next()
	Directory.new().remove(path)

func _delete_content_ok():
	delete_dir(globals.user_dir + "content")
	globals.play_sfx("smash")

func _import_url():
	$URLDialog.popup_centered()
	if OS.clipboard != "":
		$URLDialog/LineEdit.text = OS.clipboard

var done = false
func _import_url_ok():
	var req = HTTPRequest.new()
	add_child(req)
	req.connect("request_completed", self, "_downloaded", [req])
	req.download_file = globals.user_dir + "tmp.querco"
	$BlackScreen.visible = true
	$BlackScreen/Label.text = "Connecting"
	done = false
	var err = req.request($URLDialog/LineEdit.text)
	if err != OK:
		$BlackScreen.visible = true
		$BlackScreen/Label.text = "Error connecting"
		yield(get_tree().create_timer(2.0), "timeout")
		$BlackScreen.visible = false
	else:
		while !done and is_instance_valid(req):
			var bs = req.get_body_size()
			if bs != -1:
				var fmt = "B"
				var div = 1
				if bs > 1024 * 1024:
					fmt = "MiB"
					div = 1024 * 1024
				elif bs > 1024:
					fmt = "KiB"
					div = 1024
				$BlackScreen/Label.text = "Downloaded\n%.3f %s\n/\n%.3f %s" % [float(req.get_downloaded_bytes()) / div, fmt, float(bs) / div, fmt]
			yield(get_tree(), "idle_frame")

func _downloaded(res, res_code, headers, body, req):
	done = true
	if res_code == 200:
		_import_ok(globals.user_dir + "tmp.querco")
		Directory.new().remove(globals.user_dir + "tmp.querco")
		req.queue_free()
	else:
		$BlackScreen/Label.text = "Error downloading"
		if File.new().file_exists(globals.user_dir + "tmp.querco"):
			Directory.new().remove(globals.user_dir + "tmp.querco")
		yield(get_tree().create_timer(2.0), "timeout")
		$BlackScreen.visible = false
		req.queue_free()

var cur_cover = 1
const chapter_count = 3

func _shortcut_left():
	if cur_cover > 1:
		cur_cover -= 1
		globals.play_sfx("click")
	$Shortcut/HBoxContainer/Left.modulate.a = 1.0 if cur_cover > 1 else 0.0
	$Shortcut/HBoxContainer/Right.modulate.a = 1.0 if cur_cover < chapter_count else 0.0
	$Shortcut/HBoxContainer/Cover.texture_normal = load("res://covers/card" + str(cur_cover) + ".png")

func _shortcut_right():
	if cur_cover < chapter_count:
		cur_cover += 1
		globals.play_sfx("click")
	$Shortcut/HBoxContainer/Left.modulate.a = 1.0 if cur_cover > 1 else 0.0
	$Shortcut/HBoxContainer/Right.modulate.a = 1.0 if cur_cover < chapter_count else 0.0
	$Shortcut/HBoxContainer/Cover.texture_normal = load("res://covers/card" + str(cur_cover) + ".png")

func _shortcut_start():
	globals.play_sfx("save_load")
	_play_shortcut(cur_cover)
