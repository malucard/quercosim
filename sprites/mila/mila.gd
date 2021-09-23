extends Character

var poses = {
	normal = {
		texture = "normal.png",
		hframes = 9,
		setup_anim_frames = 6,
		frame_period = 0.120,
		scale = 896.0 / 1024.0
	},
	sad = {
		texture = "sad.png",
		hframes = 7,
		setup_anim_frames = 4,
		frame_period = 0.120,
		scale = 896.0 / 1024.0
	},
	look = {
		texture = "look.png",
		hframes = 9,
		setup_anim_frames = 6,
		frame_period = 0.120,
		scale = 896.0 / 1024.0
	}
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
