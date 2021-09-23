extends Character

var poses = {
	normal = {
		texture = "normal.webp",
		scale = 1.4
	},
	gasp = {
		texture = "gasp.webp",
		scale = 1.4
	},
	hand = {
		texture = "hand.webp",
		scale = 1.4
	},
	hand_serious = {
		texture = "hand_serious.webp",
		scale = 1.4
	},
	point = {
		texture = "point.webp",
		scale = 1.4
	},
	serious = {
		texture = "serious.webp",
		scale = 1.4
	},
	shout = {
		texture = "shout.webp",
		scale = 1.4
	},
	side = {
		texture = "side.webp",
		scale = 1.4
	},
	side_down = {
		texture = "side_down.webp",
		scale = 1.4
	},
	side_lfg = {
		texture = "side_lfg.webp",
		scale = 1.4
	},
	side_mad = {
		texture = "side_mad.webp",
		scale = 1.4
	},
	side_serious = {
		texture = "side_serious.webp",
		scale = 1.4
	},
	side_ugh = {
		texture = "side_ugh.webp",
		scale = 1.4
	},
	sweat = {
		texture = "sweat.webp",
		scale = 1.4
	},
	think = {
		texture = "think.webp",
		scale = 1.4
	}
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
