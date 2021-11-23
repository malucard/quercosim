extends TextureButton

func _ready():
	connect("mouse_entered", self, "grab_focus")
