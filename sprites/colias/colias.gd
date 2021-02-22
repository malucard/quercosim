extends Node

var poses = {
	normal = {
		texture = preload("normal/canvas.png"),
		mouth = [preload("normal/mouth.png"), 161, 192, "speak3", 3],
	},
	grin = {
		texture = preload("grin/tex.png"),
		mouth = [preload("grin/mouth.png"), 163, 153, "speak_colias_grin", 3],
	},
	happy = {
		texture = preload("happy/tex.png"),
		mouth = [preload("happy/mouth.png"), 256, 160, "speak_colias"],
	},
	serious = {
		texture = preload("serious/tex.png"),
		eyes = [preload("serious/eyes.png"), 138, 127],
		mouth = [preload("serious/mouth.png"), 138, 191],
	},
	unused = {
		texture = preload("happy/tex.png")
	},
}

var pose = poses.normal

func get_pose():
	return pose
