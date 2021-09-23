extends Character

var poses = {
	normal = {
		texture = "normal/canvas.png",
		mouth = ["normal/mouth.png", 161, 192, "speak3", 3],
	},
	grin = {
		texture = "grin/tex.png",
		mouth = ["grin/mouth.png", 163, 153, "speak_colias_grin", 3],
	},
	happy = {
		texture = "happy/tex.png",
		mouth = ["happy/mouth.png", 256, 160, "speak_colias"],
	},
	serious = {
		texture = "serious/tex.png",
		eyes = ["serious/eyes.png", 138, 127],
		mouth = ["serious/mouth.png", 138, 191],
	},
	unused = {
		texture = "happy/tex.png"
	},
	nervous = {
		texture = "nervous.png"
	},
	dramatic = {
		texture = "dramatic/tex.png",
		mouth = ["dramatic/mouth.png", 232, 180]
	}
}

const flip = true
var pose = poses.normal
const battleface = "battleface.png"

func get_pose():
	return pose
