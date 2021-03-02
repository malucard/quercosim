extends Control

func _ready():
	pass

func _new_game():
	state.play_sfx("save_load")
	state.reset()
	state.to_load = 0
	state.to_load_bg = null
	state.to_load_side = 0
	state.to_load_bgm = null
	state.to_load_modulate = null
	get_tree().change_scene("res://main.tscn")
