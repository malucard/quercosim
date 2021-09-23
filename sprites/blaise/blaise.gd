extends Character

var poses = {
	normal = {
		texture = "normal/tex.png",
		eyes = ["normal/eyes.png", 200, 128],
		mouth = ["normal/mouth.png", 200, 224]
	}
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
