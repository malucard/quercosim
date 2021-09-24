class_name Character
extends Node

func load_(path: String):
	if path.begins_with("res://"):
		return load(path)
	elif path.begins_with("user://"):
		return globals.load_img_ext(path)
	else:
		return load_(self.get_script().get_path().get_base_dir() + "/" + path)
