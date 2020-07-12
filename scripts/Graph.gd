extends PanelContainer

var pointsList = []
var MAX_NUMBER_OF_POINTS = 100
var MAX_VALUE = 10.0

export(Color) var line_color

signal points_updated(points)

var average_required = 0

func _ready():
	draw_graph()
	$Line2D.default_color = line_color


func add_point(point):
	if pointsList.size() >= MAX_NUMBER_OF_POINTS:
		pointsList = []
	pointsList.append(point)
	draw_graph()
	emit_signal("points_updated", pointsList)


func draw_graph():
	var pv = PoolVector2Array()
	var maxX = rect_size.x
	var maxY = rect_size.y - 5
	var deltaX = maxX / (MAX_NUMBER_OF_POINTS - 1)

	for i in range(pointsList.size()):
		var value = pointsList[i]
		var currentX = deltaX * float(i)
		var currentY = maxY * (1 - float(value) / MAX_VALUE)
		pv.append(Vector2(currentX, max(0, currentY)))
	$Line2D.points = pv

	if average_required == 0:
		$HorizontalBar.visible = false
	else:
		$HorizontalBar.visible = true
		$HorizontalBar.points = [
			Vector2(0, maxY * (1 - float(average_required) / MAX_VALUE)),
			Vector2(maxX, maxY * (1 - float(average_required) / MAX_VALUE))
		]

func copy_display_of(other_graph):
	MAX_NUMBER_OF_POINTS = other_graph.MAX_NUMBER_OF_POINTS
	MAX_VALUE = other_graph.MAX_VALUE / 300
	other_graph.connect("points_updated", self, "set_points")


func stop_copy_display_of(other_graph):
	other_graph.disconnect("points_updated", self, "set_points")


func set_points(points):
	pointsList = points
	draw_graph()


func _on_graph_resized():
	draw_graph()
