extends Control

#func _ready():
	#$VBoxContainer/HBoxContainer/NewGame.grab_focus()

func _new_game():
	globals.play_sfx("save_load")
	get_tree().change_scene("res://main.tscn")

func _shortcut():
	globals.play_sfx("organizer")
	$AnimationPlayer.play("show_shortcut")

func _close_shortcut():
	globals.play_sfx("back")
	$AnimationPlayer.play("hide_shortcut")

func _play_shortcut(which: int):
	globals.play_sfx("save_load")
	if which == -1:
		var new_main = preload("res://main.tscn").instance()
		var parser = new_main.get_node("TextureRect/RunScript")
		parser.load_script("debug")
		get_tree().current_scene.queue_free()
		get_tree().get_root().add_child(new_main)
		get_tree().current_scene = new_main
	elif which == 1:
		get_tree().change_scene("res://main.tscn")
	else:
		var new_main = preload("res://main.tscn").instance()
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

func _import_ok(path):
	$BlackScreen.visible = true
	$BlackScreen/Label.text = "Importing"
	var d = Directory.new()
	if d.open("user://content") != OK:
		d.make_dir("user://content")
	var f = File.new()
	if f.open_compressed(path, File.READ, File.COMPRESSION_ZSTD) != OK:
		printerr("failed to open file")
		$BlackScreen.visible = false
		return
	if f.get_buffer(8) != "ALBA\u0000\u0000\u0000\u0000".to_ascii():
		printerr("unsupported file")
		f.close()
		$BlackScreen.visible = false
		return
	yield(get_tree(), "idle_frame")
	while import_file(f, "user://content/"):
		pass
	$BlackScreen/Label.text = "Imported\nPlease restart the game to load changes."
	yield(get_tree().create_timer(2.0), "timeout")
	$BlackScreen.visible = false
	f.close()

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
	d.open("user://content")
	d.list_dir_begin(true)
	var fn = d.get_next()
	while fn != "":
		if d.current_is_dir():
			if fn == "evidence" or fn == "profiles" or fn == "bg" or fn == "embed" or fn == "sfx" or fn == "music":
				files.push_back([fn, get_all_files_in("user://content/" + fn)])
			elif fn == "char":
				var arr = []
				var d2 = Directory.new()
				d2.open("user://content/char")
				d2.list_dir_begin(true)
				var fn2 = d2.get_next()
				while fn2 != "":
					if d2.current_is_dir():
						arr.push_back([fn2, get_all_files_in("user://content/char/" + fn2)])
					fn2 = d2.get_next()
				d2.list_dir_end()
				if !arr.empty():
					files.push_back(["char", arr])
			elif fn == "script":
				var arr = []
				var d2 = Directory.new()
				d2.open("user://content/script")
				d2.list_dir_begin(true)
				var fn2 = d2.get_next()
				while fn2 != "":
					if !d2.current_is_dir() and fn2.ends_with(".txt"):
						arr.push_back(fn2)
					fn2 = d2.get_next()
				d2.list_dir_end()
				if !arr.empty():
					files.push_back(["script", arr])
			elif fn == "inv":
				var arr = []
				var d2 = Directory.new()
				d2.open("user://content/inv")
				d2.list_dir_begin(true)
				var fn2 = d2.get_next()
				while fn2 != "":
					if !d2.current_is_dir() and fn2.ends_with(".json"):
						arr.push_back(fn2)
					fn2 = d2.get_next()
				d2.list_dir_end()
				if !arr.empty():
					files.push_back(["inv", arr])
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
	if d.open("user://content") == OK:
		exported_bytes = 0
		$BlackScreen.visible = true
		$BlackScreen/Label.text = "Exporting"
		var outf = File.new()
		var files = get_all_content_files()
		outf.open_compressed(path, File.WRITE, File.COMPRESSION_ZSTD)
		outf.store_string("ALBA")
		outf.store_32(0)
		add_to_file(outf, files, "user://content/")
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
	if d.open("user://content") != OK:
		d.make_dir("user://content")
	OS.shell_open(ProjectSettings.globalize_path("user://content"))
