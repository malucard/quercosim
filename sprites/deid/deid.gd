extends Node

var poses = {
	normal = {
		texture = preload("normal.png")
	}
}

var pose = poses.normal

func get_pose():
	return pose
