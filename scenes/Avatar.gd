extends PanelContainer

func _ready():
	generate_face()


func generate_face():
	var eyes = $Eyes.get_children()
	
	for eye in eyes:
		eye.visible = false
	
	var k = randi() % len(eyes)
	eyes[k].visible = true

func copy(avatarToCopy):
	var eyes = $Eyes.get_children()
	for i in range(len(eyes)):
		eyes[i].visible = avatarToCopy.get_node("Eyes").get_children()[i].visible
