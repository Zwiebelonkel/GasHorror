# CreditsScreen.gd
extends Control

# Beispiel-Daten
var assets = [
	{ "title": "Lowpoly Gas Station – by AspectStudios", "url": "https://skfb.ly/pzV7U" },
	{ "title": "Redneck Character PSX Style – by vinrax", "url": "https://skfb.ly/pypzp" },
	{ "title": "Scientist PSX style – by vinrax", "url": "https://skfb.ly/oA8NX" },
	{ "title": "PSXprop - Male Character 02 – by WardsterOnSketchfab", "url": "https://skfb.ly/pt6SD" },
	{ "title": "PSX Base - Bearded Man – by MrPrisma3D", "url": "https://skfb.ly/pxRKW" },
	{ "title": "PSX Colt 1911 – by Charckes", "url": "https://skfb.ly/prUZZ" },
	{ "title": "Flash Light Psx | Low Poly – by liltoba", "url": "https://skfb.ly/o8ExH" },
	{ "title": "PSX Forest Asset Pack – by AkuVain", "url": "https://skfb.ly/oJPOT" },
	{ "title": "Murphy '92 – by Daniel Zhabotinsky", "url": "https://skfb.ly/pAPuD" },
	{ "title": "Deadman-Deadbody man – by unalien.gaming", "url": "https://skfb.ly/oWuAB" },
	{ "title": "Locker – by Samuel F. Johanns", "url": "https://skfb.ly/oWGYI" },
	{ "title": "Industrial Pipes – by Dumokan Art", "url": "https://skfb.ly/6THNP" },
	{ "title": "Industrial Electrical Box – by Mehdi Shahsavan", "url": "https://skfb.ly/oTTw9" },
	{ "title": "Industrial Robot – by jacuo777", "url": "https://skfb.ly/ov66o" },
]

func _ready():
	var list_container = $ScrollContainer/VBoxContainer
	for asset in assets:
		var label = Label.new()
		label.text = asset.title
		list_container.add_child(label)

		var link = LinkButton.new()
		link.text = asset.url
		link.uri = asset.url
		list_container.add_child(link)
