extends Sprite

onready var state = $"../.."
onready var parser = $"../../TextureRect/RunScript"

export(int) var id = 0

var prev_x
var target_x
var start
var alpha_start
var just_appeared
var both_sides
var delta
func _process(_delta):
	delta = _delta
	var a = $AnimationPlayer
	if !a.is_playing() or a.current_animation != "charfadeout":
		modulate.a = 1.0
	if !a.is_playing():
		a.play("blink")
	var c = state.rchar if id == 0 else (state.lchar if id == 1 else state.echar[id - 2])
	if c and !state.has_tag("hide_char"):
		just_appeared = !visible
		if alpha_start: # and (!a.is_playing() or a.current_animation != "charfadeout"):
			var cur = min(OS.get_ticks_msec(), alpha_start + 500)
			modulate = Color(1.0, 1.0, 1.0, (cur - alpha_start) / 500.0)
			if cur == alpha_start + 500:
				alpha_start = null
				parser.resume_talking(true)
		visible = true
		if start:
			var cur = min(OS.get_ticks_msec(), start + 200)
			position.x = lerp(prev_x, target_x, float(cur - start) / 200.0)
			if cur == start + 200:
				start = null
				parser.resume_talking()
		else:
			draw(c.pose, c)
	else:
		visible = false

func appear():
	if !visible:
		alpha_start = OS.get_ticks_msec()
		modulate = Color(1.0, 1.0, 1.0, 0.0)
		parser.stop_talking()

func appear_sudden():
	visible = true
	just_appeared = false
	modulate.a = 0.0
	prev_x = position.x

func disappear():
	parser.stop_talking()
	parser.stop_talking()
	$AnimationPlayer.play("charfadeout")
	while $AnimationPlayer.current_animation != "charfadeout":
		yield(get_tree(), "idle_frame")
	yield($AnimationPlayer, "animation_finished")
	yield(get_tree(), "idle_frame")
	parser.resume_talking()

func remove():
	if start:
		start = null
		parser.resume_talking(true)
	if id == 0:
		state.rchar = null
	elif id == 1:
		state.lchar = null
	else:
		state.echar[id - 2] = null
	visible = false

func load_char_res(path):
	if id == 0:
		return state.rchar.load_(path)
	elif id == 1:
		return state.lchar.load_(path)
	else:
		return state.echar[id - 2].load_(path)

func get_idx(mychar):
	var i = 0
	if state.rchar:
		if state.rchar == mychar:
			return i
		i += 1
	if state.lchar:
		if state.lchar == mychar:
			return i
		i += 1
	for e in state.echar:
		if e == mychar:
			return i
		if e:
			i += 1
	return i

func count_chars():
	var i = 0
	if state.rchar:
		i += 1
	if state.lchar:
		i += 1
	for e in state.echar:
		if e:
			i += 1
	return i

var setup_anim_start = 0
var setup_anim_frames = 0
var last_pose
var custom = false
func draw(pose, mychar):
	prev_x = position.x
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
			#$Eyes.texture = null
			#$Mouth.texture = null
			custom = true
		else:
			custom = false
	var tex = pose.get("texture")
	if typeof(tex) == TYPE_STRING:
		tex = load_char_res(tex)
		pose["texture"] = tex
	texture = tex
	if "hframes" in pose:
		hframes = pose.get("hframes")
	else:
		hframes = 1
	var pose_scale = pose.get("scale") if "scale" in pose else 1.0
	var s = get_viewport_rect().size.y / 820.0 * pose_scale if !pose.has("unscaled") else 1.0
	scale = Vector2(s, s)
	var width = (texture.get_width() / hframes if texture else pose["size"].x)
	var height = (texture.get_height() / vframes if texture else pose["size"].y)
	var flipped = false
	if id != 0:
		if "flip" in pose:
			flipped = pose.get("flip")
		else:
			flipped = "flip" in mychar
		if flipped:
			scale.x = -scale.x
		##flip_h = false
		#$Mouth.flip_h = flip_h
		#$Eyes.flip_h = flip_h
	if "eyes" in pose:
		var eyes = pose.eyes
		if typeof(eyes[0]) == TYPE_STRING:
			eyes[0] = load_char_res(eyes[0])
		$Eyes.texture = eyes[0]
		if flip_h:
			$Eyes.offset = Vector2(width - eyes[1] - eyes[0].get_width() / $Eyes.hframes, eyes[2])
		else:
			$Eyes.offset = Vector2(eyes[1], eyes[2])
	else:
		$Eyes.texture = null
	if state.get_speaker() == mychar:
		modulate.r = lerp(modulate.r, 1.0, delta * 8)
		modulate.g = modulate.r
		modulate.b = modulate.r
		if parser.next_text.length() and "mouth" in pose:
			var mouth = pose.mouth
			if typeof(mouth[0]) == TYPE_STRING:
				mouth[0] = load_char_res(mouth[0])
			$Mouth.texture = mouth[0]
			if flip_h:
				$Mouth.offset = Vector2(width - mouth[1] - mouth[0].get_width() / $Mouth.hframes, mouth[2])
			else:
				$Mouth.offset = Vector2(mouth[1], mouth[2])
			if !$SpeakPlayer.is_playing() and parser.blipped:
				parser.blipped = false
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
	else:
		modulate.r = lerp(modulate.r, 0.5, 0.5)
		modulate.g = modulate.r
		modulate.b = modulate.r
	#scale = Vector2(pose_scale, pose_scale)
	if visible:
		var count = count_chars()
		var i = get_idx(mychar)
		var vwfull = get_viewport_rect().size.x
		var vw = min(vwfull, get_viewport_rect().size.y * 16 / 9)
		var sw = vw / count
		var sx = vw - sw * (i + 1)
		if vw < vwfull:
			sx += (vwfull - vw) / 2
		if "flip" in pose or "flip" in mychar:
			if flipped:
				var center = (pose.center_from_right) if "center_from_right" in pose else (width / 2)
				if i == count - 1 and count == 2:
					position.x = sx + width * s
				elif count > 2:
					position.x = sx + sw / 2 - center * s + width * s
				else:
					position.x = sx + sw / 2 - width * s / 2 + width * s
			else:
				var center = (width - pose.center_from_right) if "center_from_right" in pose else (width / 2)
				#if "center_from_right" in pose:
					#print(center)
				if i == 0 and count == 2:
					position.x = sx + sw - width * s
				elif count == 1:
					position.x = sx + sw / 2 - width * s / 2
				else:
					position.x = sx + sw - center * s
		else:
			position.x = sx + sw / 2 - width * s / 2
	position.y = get_viewport_rect().size.y - height * s
	if position.x != prev_x and both_sides != (state.lchar and state.rchar) and !just_appeared:
		start = OS.get_ticks_msec()
		target_x = position.x
		parser.stop_talking()
		position.x = prev_x
	both_sides = state.lchar and state.rchar
	var period = 0.5
	if "frame_period" in pose:
		period = pose.get("frame_period")
	if "setup_anim_frames" in pose:
		setup_anim_frames = pose.get("setup_anim_frames")
	else:
		setup_anim_frames = 0
	var time = OS.get_ticks_msec() - setup_anim_start
	var setup_anim_len = int(period * 1000) * setup_anim_frames
	var loop_delay = int(pose.get("loop_delay") * 1000) if "loop_delay" in pose else 0
	if time >= setup_anim_len:
		frame = setup_anim_frames + (time - setup_anim_len) % (int(period * 1000) * (hframes - setup_anim_frames) + loop_delay) / int(period * 1000)
		if frame >= hframes:
			frame = hframes - 1
	else:
		frame = time / int(period * 1000)
		$Eyes.texture = null
		$Mouth.texture = null
