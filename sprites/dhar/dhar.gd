extends Character

var poses = {
	normal = {
		texture = "normal.png",
		eyes = ["eyes.png", 0, 0],
		mouth = ["mouth.png", 0, 0],
		scale = 1.5
	},
	sad = {
		texture = "sad.png",
		eyes = ["eyes.png", 0, 0],
		mouth = ["mouth.png", 0, 0],
		scale = 1.5
	}
}

var pose = poses.normal

func get_pose():
	return pose
