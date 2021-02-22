extends Sprite

export(bool) var right = false

func _ready():
	if right:
		state.rsprite = self
	else:
		state.lsprite = self

func _process(delta):
	var c = state.rchar if right else state.lchar
	if c:
		visible = true
		draw(c.pose)
	else:
		visible = false

var last_pose
var custom = false
func draw(pose):
	if pose != last_pose:
		last_pose = pose
		if has_node("canvas"):
			get_node("canvas").queue_free()
		if "scene" in pose:
			var n = pose.scene.instance(PackedScene.GEN_EDIT_STATE_DISABLED)
			n.name = "canvas"
			add_child(n)
			move_child(n, 0)
			texture = null
			$Eyes.texture = null
			$Mouth.texture = null
			custom = true
		else:
			custom = false
	var s = get_viewport_rect().size.y / 820.0 if !pose.has("unscaled") else 1
	scale = Vector2(s, s)
	texture = pose.get("texture")
	if pose.has("eyes"):
		var eyes = pose.eyes
		$Eyes.texture = eyes[0]
		$Eyes.offset = Vector2(eyes[1], eyes[2])
	else:
		$Eyes.texture = null
	if pose.has("mouth") and state.parser.next_text.length() and state.get_speaker() == (state.rchar if right else state.lchar):
		var mouth = pose.mouth
		$Mouth.texture = mouth[0]
		$Mouth.offset = Vector2(mouth[1], mouth[2])
		if !$SpeakPlayer.is_playing() and state.parser.blipped:
			if mouth.size() > 3:
				if mouth.size() > 4:
					$Mouth.hframes = 3
				else:
					$Mouth.hframes = 2
				$SpeakPlayer.play(mouth[3])
			else:
				$Mouth.hframes = 2
				$SpeakPlayer.play("speak")
	else:
		$Mouth.texture = null
	var width = texture.get_width() if texture else pose.size.x
	var height = texture.get_height() if texture else pose.size.y
	if right:
		if state.lchar:
			position.x = get_viewport_rect().size.x - width * s
		else:
			if state.rchar == char_querco:
				position.x = get_viewport_rect().size.x - width * s * 1.4
			else:
				position.x = get_viewport_rect().size.x / 2 - width * s / 2
	else:
		position.x = 0# s * 20
	position.y = get_viewport_rect().size.y - height * s
