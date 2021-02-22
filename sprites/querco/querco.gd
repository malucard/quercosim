extends Node

var poses = {
	normal = {
		texture = preload("normal/tex.png"),
		eyes = [preload("normal/eyes.png"), 160, 96],
		mouth = [preload("normal/mouth.png"), 128, 192],
	},
	hand = {
		scene = preload("hand/anim.tscn"),
		mouth = [preload("hand/mouth.png"), 320, 192],
		size = Vector2(740, 768)
	},
	smug = {
		texture = preload("smug/canvas.png"),
		eyes = [preload("smug/eyes.png"), 185, 96],
		mouth = [preload("smug/mouth.png"), 153, 160, "speak_colias_grin", 3],
	},
	flushed = {
		texture = preload("flushed.png")
	},
	sweat = {
		texture = preload("flushed.png")
	}
}

const objection = preload("sounds/objeckshun.wav")
const battleface = preload("battleface.png")

var pose = poses.normal

func get_pose():
	return pose
