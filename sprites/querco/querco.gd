extends Character

var poses = {
	normal = {
		texture = "normal/tex.png",
		eyes = ["normal/eyes.png", 160, 96],
		mouth = ["normal/mouth.png", 128, 192],
	},
	hand = {
		scene = preload("hand/anim.tscn"),
		mouth = ["hand/mouth.png", 320, 192],
		size = Vector2(740, 768)
	},
	smug = {
		texture = "smug/canvas.png",
		eyes = ["smug/eyes.png", 185, 96],
		mouth = ["smug/mouth.png", 153, 160, "speak_colias_grin", 3],
	},
	flushed = {
		texture = "flushed.png"
	},
	sweat = {
		texture = "flushed.png"
	},
	buff = {
		texture = "buff.png"
	},
	think = {
		texture = "think/canvas.png",
		mouth = ["think/mouth.png", 292, 160, "speak_colias_grin", 3]
	},
	mobile = {
		texture = "mobile/mobile.png"
	},
	mobile_manny = {
		texture = "mobile/mobile_manny.png"
	}
}

const flip = true
const objection = "sounds/objeckshun.wav"
const battleface = "battleface.png"

var pose = poses.normal

func get_pose():
	return pose
