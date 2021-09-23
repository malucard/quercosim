extends Character

var poses = {
	normal = {
		texture = "normal.jpg"
	}
}

var gender = "f"
var pose = poses.normal

func get_pose():
	return pose
