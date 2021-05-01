extends Sprite

export(bool) var right = false

func _ready():
	if right:
		state.rsprite = self
	else:
		state.lsprite = self

var prev_x
var target_x
var start
var just_appeared
var both_sides
func _process(_delta):
	var a = $"../../AnimationPlayer"
	if !a.is_playing() or a.current_animation != ("rcharfadeout" if right else "lcharfadeout"):
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	var c = state.rchar if right else state.lchar
	if c:
		just_appeared = !visible
		visible = true
		if start:
			var cur = min(OS.get_ticks_msec(), start + 200)
			position.x = lerp(prev_x, target_x, float(cur - start) / 200.0)
			if cur >= start + 200:
				start = null
				state.parser.resume_talking()
		else:
			draw(c.pose)
	else:
		visible = false

func remove():
	if start:
		start = null
		state.parser.resume_talking()
	if right:
		state.rchar = null
	else:
		state.lchar = null
	visible = false

var setup_anim_start = 0
var setup_anim_frames = 0
var last_pose
var custom = false
func draw(pose):
	prev_x = position.x
	if !state.parser:
		return
	if pose != last_pose:
		setup_anim_start = OS.get_ticks_msec()
		setup_anim_frames = 0
		last_pose = pose
		if has_node("canvas"):
			get_node("canvas").queue_free()
		if "scene" in pose:
			var n = pose.scene.instance(PackedScene.GEN_EDIT_STATE_DISABLED)
			n.name = "canvas"
			add_child(n)
			move_child(n, 0)
			if "anim" in pose:
				n.anim = pose.anim
			texture = null
			$Eyes.texture = null
			$Mouth.texture = null
			custom = true
		else:
			custom = false
	var pose_scale = pose.get("scale") if "scale" in pose else 1.0
	var s = get_viewport_rect().size.y / 820.0 * pose_scale if !pose.has("unscaled") else 1.0
	scale = Vector2(s, s)
	var ch = state.rchar if right else state.lchar
	if !right:
		if pose.has("flip"):
			flip_h = pose.get("flip")
		else:
			flip_h = "flip" in ch
	var period = 0.5
	texture = pose.get("texture")
	if "hframes" in pose:
		hframes = pose.get("hframes")
	else:
		hframes = 1
	if "frame_period" in pose:
		period = pose.get("frame_period")
	if "setup_anim_frames" in pose:
		setup_anim_frames = pose.get("setup_anim_frames")
	else:
		setup_anim_frames = 0
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
	#scale = Vector2(pose_scale, pose_scale)
	var width = (texture.get_width() / hframes if texture else pose.size.x)
	var height = (texture.get_height() / vframes if texture else pose.size.y)
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
	if position.x != prev_x and both_sides != (state.lchar and state.rchar) and !just_appeared:
		start = OS.get_ticks_msec()
		target_x = position.x
		state.parser.stop_talking()
		position.x = prev_x
	both_sides = state.lchar and state.rchar
	var time = OS.get_ticks_msec() - setup_anim_start
	var setup_anim_len = int(period * 1000) * setup_anim_frames
	if time >= setup_anim_len:
		frame = setup_anim_frames + (time - setup_anim_len) % (int(period * 1000) * (hframes - setup_anim_frames)) / int(period * 1000)
	else:
		frame = time / int(period * 1000)
