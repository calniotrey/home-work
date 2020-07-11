extends PanelContainer


var eye_id = 0
var hair_id = 0
var symbol_id = 0
var shirt_color = Color(1, 1, 1)


func _ready():
	generate_face()


func hide_all():
	hide_feature($Eyes)
	hide_feature($Hairs)
	hide_feature($Symbols)


func hide_feature(node):
	for child in node.get_children():
		child.visible = false


func generate_face():
	hide_all()
	
	var eyes = $Eyes.get_children()
	eye_id = randi() % len(eyes)
	eyes[eye_id].visible = true
	
	var hairs = $Hairs.get_children()
	hair_id = randi() % len(hairs)
	hairs[hair_id].visible = true
	
	var symbols = $Symbols.get_children()
	symbol_id = randi() % len(symbols)
	symbols[symbol_id].visible = true
	
	shirt_color = Color(randf(), randf(), randf())
	$Shirt.modulate = shirt_color
	

func copy(avatar_to_copy):
	hide_all()
	var eyes = $Eyes.get_children()
	eye_id = avatar_to_copy.eye_id
	eyes[eye_id].visible = true
	
	var hairs = $Hairs.get_children()
	hair_id = avatar_to_copy.hair_id
	hairs[hair_id].visible = true
	
	var symbols = $Symbols.get_children()
	symbol_id = avatar_to_copy.symbol_id
	symbols[symbol_id].visible = true
	
	shirt_color = avatar_to_copy.shirt_color
	$Shirt.modulate = shirt_color

