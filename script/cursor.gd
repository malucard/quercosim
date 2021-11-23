extends TextureRect

export var off_x: int = 0
var prev_focused

func _process(delta):
	var focused = $"..".get_focus_owner()
	if focused:
		if prev_focused != focused:
			globals.play_sfx("cursor_ffviii")
		prev_focused = focused
		visible = true
		var fp = focused
		while fp:
			if !("visible" in fp):
				break
			elif !fp.visible:
				visible = false
				break
			else:
				fp = fp.get_parent()
		if visible:
			var pos = focused.rect_global_position
			var size = focused.rect_size
			if "text" in focused:
				var ts = focused.get_font("Font").get_string_size(focused.text)
				if "align" in focused and focused.align == Button.ALIGN_CENTER:
					pos.x += (size.x - ts.x) / 2
					size.x = ts.x
			var target = pos + Vector2(off_x - 29, size.y / 2 - 10)
			rect_global_position = lerp(rect_global_position, target, delta * 8)
	else:
		prev_focused = null
		visible = false
