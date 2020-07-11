extends PanelContainer

var pointsList = []
var MAX_NUMBER_OF_POINTS = 100
var MAX_VALUE = 10.0


func _ready():
	draw_graph()


func add_point(point):
	if pointsList.size() >= MAX_NUMBER_OF_POINTS:
		pointsList = []
	pointsList.append(point)
	draw_graph()


func draw_graph():
	var pv = PoolVector2Array()
	var maxX = rect_size.x
	var maxY = rect_size.y
	var deltaX = maxX / (MAX_NUMBER_OF_POINTS - 1)

	for i in range(pointsList.size()):
		var value = pointsList[i]
		var currentX = deltaX * float(i)
		var currentY = maxY * (1 - float(value) / MAX_VALUE)
		# print(i, ":", currentX, ", ", currentY, " value : ", value)
		pv.append(Vector2(currentX, currentY))
	$Line2D.points = pv


func _on_graph_resized():
	draw_graph()
