extends Node

var poses = {
	normal = {
		texture = preload("normal.png")
	}
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
