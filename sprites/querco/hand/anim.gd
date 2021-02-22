extends Sprite

func _ready():
	state.parser.stop_talking()

func end():
	state.parser.resume_talking()
