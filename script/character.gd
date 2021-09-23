class_name Character
extends Node

func load_(path: String):
	if path.begins_with("res://") or path.begins_with("user://"):
		return load(path)
	else:
		return load(self.get_script().get_path().get_base_dir() + "/" + path)
