extends Node

var poses = {
	normal = {
		scene = preload("scene.tscn"),
		size = Vector2(700, 820),
		unscaled = true
	}
}

var pose = poses.normal

func get_pose():
	return pose

func _process(delta):
	pose.size.y = get_viewport().get_visible_rect().size.y
	pose.size.x = pose.size.y * 0.8
