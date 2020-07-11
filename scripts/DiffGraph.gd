extends Line2D

var pointsList = []
var MAX_NUMBER_OF_POINTS = 1000
var MAX_VALUE = 10.0


# Called when the node enters the scene tree for the first time.
func _ready():
#	pointsList.append(1)
#	pointsList.append(3)
#	pointsList.append(2)
#	pointsList.append(10)
#	pointsList.append(5)
	drawGraph()

func addPoint(point):
	if pointsList.size() >= MAX_NUMBER_OF_POINTS:
		pointsList = []
	pointsList.append(point)
	drawGraph()
	
func drawGraph():
	var pv = PoolVector2Array()
	var parent = get_parent()
#	print(parent.rect_size)
#	var maxX = parent.margin_right - parent.margin_left
#	var maxY = parent.margin_bottom - parent.margin_top
	var maxX = parent.rect_size.x
	var maxY = parent.rect_size.y
	var deltaX = maxX / (MAX_NUMBER_OF_POINTS - 1)
	for i in range(pointsList.size()):
		var value = pointsList[i]
		var currentX = deltaX * float(i)
		var currentY = maxY - float(value) / MAX_VALUE * maxY
		# print(i, ":", currentX, ", ", currentY)
		pv.append(Vector2(currentX, currentY))
	self.points = pv

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Root_resized():
	drawGraph()
