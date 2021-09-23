extends Character

var poses = {
	normal = {
		texture = "normal/tex.png",
		eyes = ["normal/eyes.png", 118, 47],
		mouth = ["normal/mouth.png", 142, 169],
		scale = 1.2,
		flip = true
	},
	serious = {
		texture = "normal/serious.png",
		eyes = ["normal/eyes.png", 118, 47],
		mouth = ["normal/mouth.png", 142, 169],
		scale = 1.2,
		flip = true
	},
	blush = {
		texture = "normal/blush.png",
		scale = 1.2,
		flip = true
	},
	point = {
		texture = "point/tex.png",
		hframes = 4,
		setup_anim_frames = 3,
		frame_period = 0.20,
		eyes = ["point/eyes.png", 623, 64],
		mouth = ["point/mouth.png", 633, 128, "speak_colias_grin", 3],
		center_from_right = 128,
		flip = true
	},
	point_frustrated = {
		texture = "point_frustrated/tex.png",
		hframes = 4,
		setup_anim_frames = 3,
		frame_period = 0.20,
		eyes = ["point/eyes.png", 623, 64],
		mouth = ["point/mouth.png", 633, 128, "speak_colias_grin", 3],
		center_from_right = 128,
		flip = true
	},
	snap = {
		texture = "snap/tex.png",
		hframes = 3,
		frame_period = 0.2,
		loop_delay = 1.0,
		eyes = ["snap/eyes.png", 400, 93],
		mouth = ["snap/mouth.png", 430, 157],
		flip = true
	},
	normal_old = {
		texture = "old/normal.png",
		scale = 0.75
	},
	lean_old = {
		texture = "old/lean.png",
		scale = 0.75
	},
	point_old = {
		texture = "old/point.png",
		hframes = 4,
		setup_anim_frames = 3,
		frame_period = 0.20,
		center_from_right = 128,
		flip = true
	}
}

var pose = poses.normal
var objection = "res://sounds/protag_objection.wav"

func get_pose():
	return pose
