class_name ExtrasSong
extends HBoxContainer

const infos = {
	querco = {
		cover = "aai.webp",
		title = "Quercus Alba ~ The Enemy Who Surpasses The Law",
		composer = "Noriyuki Iwadare",
		work = "Ace Attorney Investigations: Miles Edgeworth"
	},
	blaise = {
		cover = "aai2.webp",
		title = "Prosecutorial Investigation Committee ~ Rigorous Justice",
		composer = "Noriyuki Iwadare",
		company = "Capcom",
		work = "Ace Attorney Investigations 2"
	},
	moderato = {
		cover = "aai.webp",
		title = "Confrontation ~ Moderato 2009 2021",
		composer = "Noriyuki Iwadare (remixed)",
		work = "Ace Attorney Investigations: Miles Edgeworth, Quercus Alba Dating Simulator"
	},
	allegro = {
		cover = "aai.webp",
		title = "Confrontation ~ Allegro 2009 2021",
		composer = "Noriyuki Iwadare (remixed)",
		work = "Ace Attorney Investigations: Miles Edgeworth, Quercus Alba Dating Simulator"
	},
	panic = {
		cover = "../../../gui/logo.png",
		title = "Panic of Fate",
		composer = "malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	inv = {
		cover = "../../../gui/logo.png",
		title = "Investigation ~ Opening 2021",
		composer = "malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	invmid = {
		cover = "../../../gui/logo.png",
		title = "Investigation ~ Middlegame 2021",
		composer = "malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	invepic = {
		cover = "../../../gui/logo.png",
		title = "Investigation ~ Epic 2021",
		composer = "malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	protagonist = {
		cover = "../../../gui/logo.png",
		title = "Protagonist ~ Pure Love",
		og_title = "Klavier Gavin ~ Guilty Love",
		composer = "Toshihiko Horiyama, malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	heaven = {
		cover = "../../../gui/logo.png",
		title = "Heaven",
		composer = "malucart",
		company = "Capcom",
		work = "Quercus Alba Dating Simulator"
	},
	secrets = {
		cover = "hd.jpeg",
		title = "Secrets",
		composer = "Satoshi Okubo",
		company = "Cing",
		work = "Hotel Dusk: Room 215"
	},
	twilight_sad = {
		cover = "lw.jpeg",
		title = "Twilight Sad",
		composer = "Satoshi Okubo",
		company = "Cing",
		work = "Last Window: The Secret of Cape West"
	}
}

#[table=4]
#[cell][color=#777]Composer [/color][/cell]
#[cell]Noriyuki Iwadare[/cell]
#[cell][/cell][cell][/cell]
#[cell][color=#777]Company [/color][/cell]
#[cell]Capcom[/cell]
#[cell][color=#777]Work [/color][/cell]
#[cell]Ace Attorney Investigations: Miles Edgeworth[/cell]

export var song: String

func _ready():
	var info = infos[song]
	var bb = "[table=2]"
	if "composer" in info:
		bb += "[cell][color=#777]Composer [/color][/cell]"
		bb += "[cell][color=#aaa]" + info.composer + "  [/color][/cell]"
	#if "og_title" in info:
	#	bb += "[cell][color=#777]Modified From [/color][/cell]"
	#	bb += "[cell][color=#aaa]" + info.og_title + "[/color][/cell]"
	#else:
	#	bb += "[cell][/cell][cell][/cell]"
	#if "company" in info:
	#	bb += "[cell][color=#777]Company [/color][/cell]"
	#	bb += "[cell][color=#aaa]" + info.company + "  [/color][/cell]"
	if "work" in info:
		bb += "[cell][color=#777]From [/color][/cell]"
		bb += "[cell][color=#aaa]" + info.work + "[/color][/cell]"
	$TextureRect.texture = load("res://sounds/music/covers/" + info.cover)
	$VBoxContainer/Title.bbcode_text = info.title
	$VBoxContainer/Info.bbcode_text = bb
