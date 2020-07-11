extends ColorRect

var listPositions = [0]
var NUMBER_OF_POINTS_MAX = 10
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func addPosition(pos):
	var lastPos = listPositions[-1]
	var newX = listPositions.size()
	var lastX = newX - 1
	var line = Line2D.new()
	listPositions.append(pos)
	
