extends VBoxContainer

func _ready():
	var scn = load("song.tscn")
	for key in ExtrasSong.infos:
		var s = scn.instance()
		s.song = key
		add_child(s)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
