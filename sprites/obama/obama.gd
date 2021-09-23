extends Character

var poses = {
	normal = {
		texture = "normal.png"
	},
	flushed = {
		texture = "flushed.png"
	},
	cry = {
		texture = "cry.png"
	},
	hand = {
		texture = "hand.png"
	},
	pan = {
		texture = "pan.webp",
		scale = 2
	}
}

var pose = poses.normal
const objection = "sounds/objection.ogg"

func get_pose():
	return pose
