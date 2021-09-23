extends Character

var poses = {
	normal = {
		texture = "normal.png",
		scale = 1.8
	},
	serious = {
		texture = "serious.png",
		scale = 1.8
	}
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
