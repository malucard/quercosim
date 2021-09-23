extends TextureRect
class_name Bg

const bgs = {
	theatrum = "res://bg/theatrum.png",
	querco_office = "res://bg/alba_office.png",
	garden = "res://bg/garden.png",
	bad_end = "res://bg/bad_end.png",
	hallway = "res://bg/hallway.png",
	classroom = "res://bg/classroom.png",
	art_room = "res://bg/art_room.png",
	maintenance_area = "res://bg/maintenance_area.png",
	protagonist = "res://bg/protagonist.png",
	living_room = "res://bg/living_room.png",
	sky = "res://bg/sky.png",
	heaven_gate = "res://bg/heaven_gate.png",
	heaven_castle = "res://bg/heaven_castle.png",
	classroom_broken_wall = "res://bg/classroom_broken_wall.png",
	duct = "res://bg/duct.png",
	duct_big = "res://bg/duct_big.jpg",
	duct_house = "res://bg/duct_house.png",
	duct_house_blood = "res://bg/ch2/duct_house_blood.png",
	deid_mann_dead = "res://bg/ch2/deid_dead.png",
	classroom_forklift = "res://bg/ch2/classroom_forklift.png",
	classroom_manny = "res://bg/ch1/classroom_manny.png",
	piano_protagonist_colias = "res://bg/ch2/piano_protagonist_colias.png",
	piano_protagonist_colias_2 = "res://bg/ch2/piano_protagonist_colias_2.png",
	hallway_forklift = "res://bg/ch2/hallway_forklift.png",
	hallway_forklift_rain = "res://bg/ch2/hallway_forklift_rain.png",
	hallway_rain = "res://bg/hallway_rain.png",
	maintenance_area_stained = "res://bg/ch2/maintenance_area_stained.png",
	forklift_stain = "res://bg/ch2/forklift_stain.png",
	forklift_stain_arrow = "res://bg/ch2/forklift_stain_arrow.png",
	forklift_flying = "res://bg/ch2/forklift_flying.png",
	querco_return = "res://bg/ch2/querco_return.png",
	querco_return_vent = "res://bg/ch2/querco_return_vent.png",
	command_center = "res://bg/command_center.png",
	train_in = "res://bg/train_in.png",
	train_out = "res://bg/train_out.png",
	the_place_where_wars_are_fought = "res://bg/the_place_where_wars_are_fought.png",
	warehouse = "res://bg/warehouse.png",
	speaker = "res://bg/speaker.png",
	hell = "res://bg/hell.webp",
	babahl = "res://bg/Babaru.webp",
	hallway_babahl = "res://bg/hallway_babahl.webp",
	earth_embassy = "res://bg/ch2/earth_embassy.png",
	earth_embassy_markiplier = "res://bg/ch2/earth_embassy_markiplier.png",
	earth_embassy_embassy = "res://bg/ch2/earth_embassy_embassy.png",
	earth_federal_hall = "res://bg/ch2/earth_federal_hall.png",
	earth_cohdopia = "res://bg/ch2/earth_cohdopia.png",
	shelock_holmes = "res://bg/ch2/shelock_holmes.png",
	mysterious_dead = "res://bg/ch2/mysterious_dead.png"
}

onready var state = $"../.."
var prev = null
var cur = null
onready var prevbg = $"../PrevBG"
var fade_in_since = 0
var t = 1
var side = 0

signal transition_done

func _ready():
	state.bg = self

func _exit_tree():
	if state.bg == self:
		state.bg = null
	Input.set_custom_mouse_cursor(null)

func _process(delta: float):
	if state.has_tag("investigation") and !$"../../Organizer".visible and !$"../../SaveMenu".visible:
		cur = bgs[state.inv.areas[state.inv.area].bg]
		$"../../Investigation/SideRight".visible = side == 0
		$"../../Investigation/SideLeft".visible = side == 1
	if prev != cur:
		prev = cur
		if get_parent().modulate.r > 0.1:
			prevbg.texture = texture
			prevbg.rect_position.x = rect_position.x
			fade_in_since = OS.get_ticks_usec()
			texture = load(cur) if cur else null
		else:
			prevbg.texture = null
			texture = load(cur) if cur else null
			emit_signal("transition_done")
	if texture:
		var tw = texture.get_width()
		var th = texture.get_height()
		if th * 16 / 9 >= tw + 1 or get_viewport_rect().size.aspect() > tw / th:
			t = 0.5
		else:
			if side:
				t = max(t - delta * 2, 0)
			else:
				t = min(t + delta * 2, 1)
		var s = get_viewport_rect().size.y / texture.get_height()
		rect_position.x = lerp(get_viewport_rect().size.x - texture.get_width() * s, 0, t)
	if state.has_tag("investigation_examine") and !$"../../Organizer".visible and !$"../../SaveMenu".visible:
		update_cursor()
	else:
		Input.set_custom_mouse_cursor(null)
	var now = OS.get_ticks_usec()
	modulate.a = min((now - fade_in_since) / 500000.0, 1)
	if modulate.a == 1:
		prevbg.texture = null
		emit_signal("transition_done")

func get_mouse_pos():
	var m = get_global_mouse_position() - rect_position
	return m / rect_size.y

func update_cursor():
	var p = get_mouse_pos()
	var es = state.inv.areas[state.inv.area].examinables
	var tex = t_hand
	for i in range(es.size()):
		var e = es[i]
		if p.x >= e.x and p.y >= e.y and p.x < e.x + e.w and p.y < e.y + e.h:
			tex = t_hand_check if state.inv.examined.has(str(state.inv.area) + ":" + str(i)) else t_hand_lit
			break
	Input.set_custom_mouse_cursor(tex, 0, Vector2(8, 4))
	if globals.mobile:
		$"../../Investigation/Hand".visible = true
		$"../../Investigation/Hand".texture = tex
		$"../../Investigation/Hand".rect_position = p * rect_size.y - Vector2(16 - rect_position.x, 8)
		$"../../Investigation/Hand".rect_size = tex.get_size() * 2
	else:
		$"../../Investigation/Hand".visible = false
	return p

var t_hand = preload("res://gui/investigation/hand.png")
var t_hand_lit = preload("res://gui/investigation/hand_lit.png")
var t_hand_check = preload("res://gui/investigation/hand_check.png")
var prev_mp = Vector2()
func _input(ev):
	if !state.has_tag("investigation_examine") or $"../../Organizer".visible or $"../../SaveMenu".visible:
		Input.set_custom_mouse_cursor(null)
		return
	if ev is InputEventMouseMotion:
		prev_mp = update_cursor()
	elif ev is InputEventMouseButton:
		var p = get_mouse_pos()
		if globals.mobile:
			if p.distance_squared_to(prev_mp) > 0.1 * 0.1:
				prev_mp = update_cursor()
				return
		if ev.pressed and !state.inv.areas.empty() and ev.position.x < rect_size.x and ev.position.y < rect_size.y:
			var cur_area = state.inv.areas[state.inv.area]
			#$HBoxContainer/VBoxContainer/TextEdit.text = cur_area.script
			var s = 1.0 / rect_size.y
			for i in range(cur_area.examinables.size()):
				var e = cur_area.examinables[i]
				if p.x >= e.x and p.y >= e.y and p.x < e.x + e.w and p.y < e.y + e.h:
					#$HBoxContainer/VBoxContainer/TextEdit.text = e.script
					state.push_call_stack()
					state.parser.go_to(e.script)
					var exid = str(state.inv.area) + ":" + str(i)
					#state.parser.script_id = "inv:" + state.inv.id + ":" + exid
					state.state = "dialogue"
					if !state.inv.examined.has(exid):
						state.inv.examined.push_back(exid)
					state.parser.next()

func _switch_side():
	side = 0 if side else 1
	globals.play_sfx("click")
