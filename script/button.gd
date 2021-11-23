extends Button

func _ready():
	connect("mouse_entered", self, "grab_focus")
