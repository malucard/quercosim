extends Character

var poses = {
	normal = {
		texture = "normal.png"
	},
	mad = {
		texture = "mad.png"
	},
	dead = {
		flip = true,
		texture = "dead.png"
	}
}

var pose = poses.normal
const objection = "sounds/objection.ogg"

func get_pose():
	return pose
