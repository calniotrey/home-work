extends PanelContainer

func _ready():
	generate_face()


func generate_face():
	var eyes = $Eyes.get_children()
	
	for eye in eyes:
		eye.visible = false
	
	var k = randi() % len(eyes)
	print(len(eyes))
	print(k)
	eyes[k].visible = true
