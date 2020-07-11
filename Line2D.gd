extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var pv = self.points
	pv.append(Vector2(0, 0))
	var parent = get_parent()
	var x = parent.margin_right - parent.margin_left
	var y = parent.margin_bottom - parent.margin_top
	pv.append(Vector2(x, y))
	self.points = pv
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
