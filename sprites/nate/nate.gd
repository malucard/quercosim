extends Character

var poses = {
	normal = {
		texture = "normal.png"
	},
	question = {
		texture = "question.png"
	},
	answer = {
		texture = "answer.png"
	},
	mag = {
		texture = "mag.png"
	},
}

const flip = true
var pose = poses.normal

func get_pose():
	return pose
