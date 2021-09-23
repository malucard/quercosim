extends Character

var poses = {
	normal = {
		texture = "normal/normal.png",
		eyes = ["normal/eyes.png", 167, 86],
		mouth = ["normal/mouth.png", 183, 150],
		scale = 0.9
	},
	sad = {
		texture = "sad/sad.png",
		eyes = ["sad/eyes.png", 167, 86],
		mouth = ["normal/mouth.png", 183, 150],
		scale = 0.9
	},
	confused = {
		texture = "confused.png",
		eyes = ["normal/eyes.png", 167, 86],
		mouth = ["normal/mouth.png", 183, 150],
		scale = 0.9
	}
}

var gender = "f"
var pose = poses.normal

func get_pose():
	return pose
