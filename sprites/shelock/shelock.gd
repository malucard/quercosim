extends Character

var poses = {
	normal = {
		texture = "normal/tex.png",
		eyes = ["normal/eyes.png", 108, 44],
		mouth = ["normal/mouth.png", 108, 60],
		scale = 4
	},
	flushed = {
		texture = "flushed/tex.png",
		mouth = ["flushed/mouth.png", 108, 60],
		scale = 4
	},
	sweat = {
		texture = "sweat/tex.png",
		hframes = 4,
		frame_period = 0.18,
		eyes = ["sweat/eyes.png", 96, 48],
		#mouth = ["sweat/mouth.png", 92, 75, "speak3", 3],
		scale = 4
	},
	polish = {
		texture = "polish/tex.png",
		hframes = 2,
		frame_period = 0.5,
		scale = 4
	},
	side = {
		texture = "side/tex.png",
		scale = 4
	},
	shock = {
		texture = "shock.png",
		hframes = 5,
		setup_anim_frames = 4,
		frame_period = 0.1,
		scale = 4
	},
	crazy = {
		texture = "crazy.png",
		scale = 4
	}
}

var pose = poses.normal
const battleface = "battleface.png"

func get_pose():
	return pose
