extends Node

var poses = {
	normal = {
		texture = preload("normal.png")
	},
	flushed = {
		texture = preload("flushed.png")
	},
	hand = {
		texture = preload("hand.png")
	},
	pan = {
		texture = preload("pan.webp")
	}
}

var pose = poses.normal
const objection = preload("sounds/objection.ogg")

func get_pose():
	return pose
