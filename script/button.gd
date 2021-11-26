extends Button

func _ready():
	connect("mouse_entered", self, "grab_focus")
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
