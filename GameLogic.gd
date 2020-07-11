extends Control


var diffGraph
var totalGraph

var stop = false

var currentTimeUnit = 0.0
var IRL_TIME_PER_UNIT = 0.05
var MAX_TIME_UNIT = 300.0
var TARGET_PRODUCTION = 10.0

var currentProduction = 0.0
var timeSinceLastTimeUnit = 0.0
var productionSinceLastTimeUnit = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	diffGraph = $"VBoxContainer/Top/TabContainer/Diff Graph/Line2D"
	diffGraph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	diffGraph.MAX_VALUE = TARGET_PRODUCTION / MAX_TIME_UNIT / 2.0
	totalGraph = $"VBoxContainer/Top/TabContainer/Total Graph/Line2D"
	totalGraph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	totalGraph.MAX_VALUE = TARGET_PRODUCTION

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeSinceLastTimeUnit += delta
	# TODO replace following by the sum of production from team members
	var prod = (3*randf() - 1)*0.001
	productionSinceLastTimeUnit += prod
	currentProduction += prod
	if not stop and timeSinceLastTimeUnit >= IRL_TIME_PER_UNIT:
		currentTimeUnit += 1
		timeSinceLastTimeUnit -= IRL_TIME_PER_UNIT
		if currentProduction >= totalGraph.MAX_VALUE:
			print("VICTORY")
			stop = true
			# TODO : change scene to victory sceen
		elif currentTimeUnit >= diffGraph.MAX_NUMBER_OF_POINTS - 1:
			print("DEFEAT")
			stop = true
			# TODO : change to defeat screen
		totalGraph.addPoint(currentProduction)
		productionSinceLastTimeUnit = min(diffGraph.MAX_VALUE, max(0, productionSinceLastTimeUnit))
		diffGraph.addPoint(productionSinceLastTimeUnit)
		productionSinceLastTimeUnit = 0
