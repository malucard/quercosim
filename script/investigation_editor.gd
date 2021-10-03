extends Panel

var file_path = null

var areas = []
var area = 0
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

func switch_area(i: int):
	area = i
	areas[area].examinables = areas[area].examinables
	grabbed = -1
	$HBoxContainer/VBoxContainer/TextEdit.text = areas[area].script
	grabbing = false
	bg_control.update()

func get_mouse_pos():
	var m = get_global_mouse_position() - bg_control.rect_position
	return m / bg_control.rect_size.y

func _input(ev):
	if ev is InputEventMouseButton and !$SaveDialog.visible and !$OpenDialog.visible and !$RenameTalkPopup.visible and !$NewAreaPopup.visible and !$MovePopup.visible and !$SetBgPopup.visible:
		if ev.pressed and !areas.empty() and ev.position.x < bg_control.rect_size.x and ev.position.y < bg_control.rect_size.y:
			grabbing = false
			grabbed = -1
			$HBoxContainer/VBoxContainer/TextEdit.text = areas[area].script
			var p = get_mouse_pos()
			var s = 1.0 / bg_control.rect_size.y
			for i in range(areas[area].examinables.size()):
				var e = areas[area].examinables[i]
				if p.x >= e.x and p.y >= e.y and p.x < e.x + e.w and p.y < e.y + e.h:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_MOVE
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x and p.y >= e.y - BORDER * s and p.x < e.x + e.w and p.y < e.y:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_T
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x - BORDER * s and p.y >= e.y and p.x < e.x and p.y < e.y + e.h:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_L
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x + e.w and p.y >= e.y and p.x < e.x + e.w + BORDER * s and p.y < e.y + e.h:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_R
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x and p.y >= e.y + e.h and p.x < e.x + e.w and p.y < e.y + e.h + BORDER * s:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_B
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x - BORDER * s and p.y >= e.y - BORDER * s and p.x < e.x and p.y < e.y:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_TL
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x + e.w and p.y >= e.y - BORDER * s and p.x < e.x + e.w + BORDER * s and p.y < e.y:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_TR
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x - BORDER * s and p.y >= e.y + e.h and p.x < e.x and p.y < e.y + e.h + BORDER * s:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					grabbed = i
					grabbed_mode = GRAB_RESIZE_BL
					grabbed_el = {x = e.x, y = e.y, w = e.w, h = e.h}
					grabbed_offset = p
				elif p.x >= e.x + e.w and p.y >= e.y + e.h and p.x < e.x + e.w + BORDER * s and p.y < e.y + e.h + BORDER * s:
					grabbing = true
					$HBoxContainer/VBoxContainer/TextEdit.text = e.script
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
	$HBoxContainer/VBoxContainer2/Area/RenameTalk.visible = false
	$HBoxContainer/VBoxContainer2/Area/RemoveTalk.visible = false
	if typeof(grabbed) == TYPE_STRING:
		$HBoxContainer/VBoxContainer/Editing.text = "editing: talk " + grabbed + " script"
		$HBoxContainer/VBoxContainer2/Area/RenameTalk.visible = true
		$HBoxContainer/VBoxContainer2/Area/RemoveTalk.visible = true
	elif grabbed == -1:
		$HBoxContainer/VBoxContainer/Editing.text = "editing: area script"
	else:
		$HBoxContainer/VBoxContainer/Editing.text = "editing: examinable " + str(grabbed) + " script"
	$HBoxContainer/VBoxContainer/TextEdit.readonly = areas.empty()
	$HBoxContainer/VBoxContainer2/Area.visible = !areas.empty()
	$HBoxContainer/VBoxContainer2/File.text = file_path if file_path else "[none]"
	$HBoxContainer/VBoxContainer2/Save/Save.visible = true if file_path else false
	bg_control.texture = load(globals.bgs[areas[area].bg]) if !areas.empty() else null
	update_talks()
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
						areas[area].examinables[grabbed].x = nx
						areas[area].examinables[grabbed].y = ny
					GRAB_RESIZE_T:
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nh > 0:
							areas[area].examinables[grabbed].y = m.y - grabbed_offset.y + grabbed_el.y
							areas[area].examinables[grabbed].h = nh
					GRAB_RESIZE_B:
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nh > 0:
							areas[area].examinables[grabbed].h = nh
					GRAB_RESIZE_L:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						if nw > 0:
							areas[area].examinables[grabbed].x = m.x - grabbed_offset.x + grabbed_el.x
							areas[area].examinables[grabbed].w = nw
					GRAB_RESIZE_R:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						if nw > 0:
							areas[area].examinables[grabbed].w = nw
					GRAB_RESIZE_TL:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nw > 0 and nh > 0:
							areas[area].examinables[grabbed].y = m.y - grabbed_offset.y + grabbed_el.y
							areas[area].examinables[grabbed].h = nh
							areas[area].examinables[grabbed].x = m.x - grabbed_offset.x + grabbed_el.x
							areas[area].examinables[grabbed].w = nw
					GRAB_RESIZE_TR:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						var nh = grabbed_offset.y - m.y + grabbed_el.h
						if nw > 0 and nh > 0:
							areas[area].examinables[grabbed].y = m.y - grabbed_offset.y + grabbed_el.y
							areas[area].examinables[grabbed].h = nh
							areas[area].examinables[grabbed].w = nw
					GRAB_RESIZE_BL:
						var nw = grabbed_offset.x - m.x + grabbed_el.w
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nw > 0 and nh > 0:
							areas[area].examinables[grabbed].h = nh
							areas[area].examinables[grabbed].x = m.x - grabbed_offset.x + grabbed_el.x
							areas[area].examinables[grabbed].w = nw
					GRAB_RESIZE_BR:
						var nw = m.x - grabbed_offset.x + grabbed_el.w
						var nh = m.y - grabbed_offset.y + grabbed_el.h
						if nw > 0 and nh > 0:
							areas[area].examinables[grabbed].h = nh
							areas[area].examinables[grabbed].w = nw
			bg_control.update()
		if typeof(grabbed) == TYPE_STRING:
			areas[area].talks[grabbed] = $HBoxContainer/VBoxContainer/TextEdit.text
		elif grabbed >= 0:
			areas[area].examinables[grabbed].script = $HBoxContainer/VBoxContainer/TextEdit.text
		else:
			areas[area].script = $HBoxContainer/VBoxContainer/TextEdit.text

func _bg_draw():
	if !areas.empty():
		for e in areas[area].examinables:
			var s = bg_control.rect_size.y
			bg_control.draw_rect(Rect2(e.x * s + bg_control.rect_position.x, e.y * s + bg_control.rect_position.y, e.w * s, e.h * s), Color(0x7F7FFF9F), true, 1.0, false)
			bg_control.draw_rect(Rect2(e.x * s + bg_control.rect_position.x - BORDER / 2, e.y * s + bg_control.rect_position.y - BORDER / 2, e.w * s + BORDER, e.h * s + BORDER), Color(0xFF7F7F9F), false, BORDER, false)

var default_20 = load("res://gui/fonts/default_20.tres")
func update_talks():
	var talk = $HBoxContainer/VBoxContainer2/Area/Talk/Box
	var children = talk.get_children()
	if areas.empty():
		for i in range(children.size()):
			children[i].queue_free()
		return
	var talks = areas[area].talks.keys()
	if children.size() != talks.size():
		for i in range(children.size()):
			children[i].queue_free()
		for i in range(talks.size()):
			var tb = ToolButton.new()
			tb.text = talks[i]
			tb.add_font_override("font", default_20)
			talk.add_child(tb)
			tb.connect("pressed", self, "_select_talk", [talks[i]])
	else:
		for i in range(talks.size()):
			children[i].text = talks[i]
			children[i].disconnect("pressed", self, "_select_talk")
			children[i].connect("pressed", self, "_select_talk", [talks[i]])

func _move():
	$MovePopup.clear()
	for a in areas:
		$MovePopup.add_item(a.name)
	$MovePopup.popup_centered()

func _move_selected(id):
	switch_area(id)

func _set_bg():
	$SetBgPopup.popup_centered()

func _set_bg_selected(id):
	var i = 0
	for n in globals.bgs:
		if i == id:
			areas[area].bg = n
			break
		i += 1

func _add_talk():
	grabbed = "Dummy"
	var i = 2
	while areas[area].talks.has(grabbed):
		grabbed = "Dummy " + str(i)
		i += 1
	areas[area].talks[grabbed] = ""
	$HBoxContainer/VBoxContainer/TextEdit.text = ""
	grabbed = grabbed
	update_talks()

func _select_talk(which: String):
	$HBoxContainer/VBoxContainer/TextEdit.text = areas[area].talks[which]
	grabbed = which
	update_talks()

func _add_area():
	$NewAreaPopup/VBoxContainer/TextEdit.text = "Area"
	$NewAreaPopup.popup_centered()

func _add_area_ok():
	areas.push_back({
		name = $NewAreaPopup/VBoxContainer/TextEdit.text,
		bg = "garden",
		examinables = [],
		mode = 0,
		script = "",
		talks = {}
	})
	switch_area(areas.size() - 1)
	$NewAreaPopup.hide()

func _add_examinable():
	grabbed = areas[area].examinables.size()
	areas[area].examinables.push_back({x = 0, y = 0, w = 0.1, h = 0.1, script = ""})
	$HBoxContainer/VBoxContainer/TextEdit.text = ""
	bg_control.update()

func import_investigation(json):
	var a = parse_json(json)
	areas = a.areas
	area = 0
	$HBoxContainer/VBoxContainer/TextEdit.text = "" if areas.empty() else areas[0].script

func export_investigation():
	return to_json({
		type = "investigation",
		areas = areas
	})

func _close():
	get_tree().change_scene("res://title_screen.tscn")

func _new():
	file_path = null
	areas = []

func _open():
	$OpenDialog.popup_centered()

func _save():
	var t = export_investigation()
	var f = File.new()
	f.open(file_path, File.WRITE)
	f.store_string(t)
	f.close()

func _save_as():
	$SaveDialog.popup_centered()

func _save_selected(path):
	file_path = path

func _open_selected(path):
	file_path = path
	var f = File.new()
	f.open(file_path, File.READ)
	import_investigation(f.get_as_text())
	f.close()

func _remove_talk():
	areas[area].talks.erase(grabbed)
	grabbed = -1
	$RenameTalkPopup/VBoxContainer/TextEdit.text = areas[area].script

func _rename_talk():
	$RenameTalkPopup.popup_centered()
	$RenameTalkPopup/VBoxContainer/TextEdit.text = grabbed

func _rename_talk_ok():
	if typeof(grabbed) != TYPE_STRING:
		return
	var new = $RenameTalkPopup/VBoxContainer/TextEdit.text
	areas[area].talks[new] = areas[area].talks[grabbed]
	areas[area].talks.erase(grabbed)
	grabbed = new
	$HBoxContainer/VBoxContainer/TextEdit.text = areas[area].talks[grabbed]
