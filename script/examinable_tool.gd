extends Panel

var file_path = null

onready var bg_control = $HBoxContainer/VBoxContainer/CenterContainer/TextureRect
enum {
	GRAB_MOVE,
	GRAB_RESIZE_T,
	GRAB_RESIZE_TL,
	GRAB_RESIZE_TR,
	GRAB_RESIZE_L,
	GRAB_RESIZE_R,
	GRAB_RESIZE_B,
	GRAB_RESIZE_BL,
	GRAB_RESIZE_BR
}
const BORDER = 8
var grabbing = false
var grabbed = -1
var grabbed_mode
var grabbed_el
var grabbed_offset
var bg = "theatrum"
var e = {x = 0.4, y = 0.4, w = 0.2, h = 0.2}

func get_mouse_pos():
	var m = get_global_mouse_position() - bg_control.rect_position
	return m / bg_control.rect_size.y

func _input(ev):
	if ev is InputEventMouseButton and !$SaveDialog.visible and !$OpenDialog.visible and !$RenameTalkPopup.visible and !$NewAreaPopup.visible and !$MovePopup.visible and !$SetBgPopup.visible:
		if ev.pressed and ev.position.x < bg_control.rect_size.x and ev.position.y < bg_control.rect_size.y:
			grabbing = false
			grabbed = -1
			var p = get_mouse_pos()
			var s = 1.0 / bg_control.rect_size.y
			var i = 0
			if p.x >= e.x and p.y >= e.y and p.x < e.x + e.w and p.y < e.y + e.h:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_MOVE
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x and p.y >= e.y - BORDER * s and p.x < e.x + e.w and p.y < e.y:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_T
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x - BORDER * s and p.y >= e.y and p.x < e.x and p.y < e.y + e.h:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_L
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x + e.w and p.y >= e.y and p.x < e.x + e.w + BORDER * s and p.y < e.y + e.h:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_R
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x and p.y >= e.y + e.h and p.x < e.x + e.w and p.y < e.y + e.h + BORDER * s:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_B
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x - BORDER * s and p.y >= e.y - BORDER * s and p.x < e.x and p.y < e.y:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_TL
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x + e.w and p.y >= e.y - BORDER * s and p.x < e.x + e.w + BORDER * s and p.y < e.y:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_TR
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x - BORDER * s and p.y >= e.y + e.h and p.x < e.x and p.y < e.y + e.h + BORDER * s:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_BL
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
			elif p.x >= e.x + e.w and p.y >= e.y + e.h and p.x < e.x + e.w + BORDER * s and p.y < e.y + e.h + BORDER * s:
				grabbing = true
				grabbed = i
				grabbed_mode = GRAB_RESIZE_BR
				grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
				grabbed_offset = p
		else:
			grabbing = false

func _ready():
	for n in globals.bgs:
		$SetBgPopup.add_item(n)

func _process(delta):
	var ex_text = "examinable x " + str(e.x) + " y " + str(e.y) + " w " + str(e.w) + " h " + str(e.h)
	if ex_text != $HBoxContainer/VBoxContainer/Editing.bbcode_text:
		$HBoxContainer/VBoxContainer/Editing.bbcode_text = ex_text
	bg_control.texture = load(globals.bgs[bg])
	if bg_control.texture:
		var ts = bg_control.texture.get_size()
		$HBoxContainer/VBoxContainer/CenterContainer.ratio = ts.x / ts.y
		if Input.is_mouse_button_pressed(BUTTON_LEFT) and grabbing:
			var m = get_mouse_pos()
			if m.x >= 0 and m.y >= 0 and m.x < ts.x / ts.y and m.y < 1:
				var s = 1.0 / bg_control.rect_size.y
				match grabbed_mode:
					GRAB_MOVE:
						var nx = clamp(m.x - grabbed_offset.x + grabbed_el.x, 0.0, ts.x / ts.y - grabbed_el.w)
						var ny = clamp(m.y - grabbed_offset.y + grabbed_el.y, 0.0, 1.0 - grabbed_el.h)
						e.x = nx
						e.y = ny
					GRAB_RESIZE_T:
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nh > 0:
							e.y = m.y - grabbed_offset.y + grabbed_el.y
							e.h = nh
					GRAB_RESIZE_B:
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nh > 0:
							e.h = nh
					GRAB_RESIZE_L:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						if nw > 0:
							e.x = m.x - grabbed_offset.x + grabbed_el.x
							e.w = nw
					GRAB_RESIZE_R:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						if nw > 0:
							e.w = nw
					GRAB_RESIZE_TL:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nw > 0 and nh > 0:
							e.y = m.y - grabbed_offset.y + grabbed_el.y
							e.h = nh
							e.x = m.x - grabbed_offset.x + grabbed_el.x
							e.w = nw
					GRAB_RESIZE_TR:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nw > 0 and nh > 0:
							e.y = m.y - grabbed_offset.y + grabbed_el.y
							e.h = nh
							e.w = nw
					GRAB_RESIZE_BL:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nw > 0 and nh > 0:
							e.h = nh
							e.x = m.x - grabbed_offset.x + grabbed_el.x
							e.w = nw
					GRAB_RESIZE_BR:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nw > 0 and nh > 0:
							e.h = nh
							e.w = nw
			bg_control.update()

func _bg_draw():
	var s = bg_control.rect_size.y
	bg_control.draw_rect(Rect2(e.x * s + bg_control.rect_position.x, e.y * s + bg_control.rect_position.y, e.w * s, e.h * s), Color(0x7F7FFF9F), true, 1.0, false)
	bg_control.draw_rect(Rect2(e.x * s + bg_control.rect_position.x - BORDER / 2, e.y * s + bg_control.rect_position.y - BORDER / 2, e.w * s + BORDER, e.h * s + BORDER), Color(0xFF7F7F9F), false, BORDER, false)

func _set_bg():
	$SetBgPopup.popup_centered()

func _set_bg_selected(id):
	e = {x = 0.4, y = 0.4, w = 0.2, h = 0.2}
	var i = 0
	for n in globals.bgs:
		if i == id:
			bg = n
			break
		i += 1

func _close():
	get_tree().change_scene("res://title_screen.tscn")

func _copy_examinable():
	OS.clipboard = "examinable x " + str(e.x) + " y " + str(e.y) + " w " + str(e.w) + " h " + str(e.h)
