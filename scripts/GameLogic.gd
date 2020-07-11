extends Control

onready var Coworker = preload("res://scenes/Coworker.tscn")

var coworkerSelected = null

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
	randomize()

	diffGraph = $VBoxContainer/Top/TabContainer/DiffGraph/Line2D
	diffGraph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	diffGraph.MAX_VALUE = TARGET_PRODUCTION / MAX_TIME_UNIT / 2.0
	totalGraph = $VBoxContainer/Top/TabContainer/TotalGraph/Line2D
	totalGraph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	totalGraph.MAX_VALUE = TARGET_PRODUCTION
	
	# Init all the coworkers
	var grids = [$VBoxContainer/Top/LeftCoworkerGrid, $VBoxContainer/Top/RightCoworkerGrid]
	for grid in grids:
		for i in range(4):
			var coworker = Coworker.instance()
			coworker.connect("selected_signal", self, "coworkerSelected")
			grid.add_child(coworker)

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
			stop = true
			get_tree().change_scene("res://scenes/Victory.tscn")
		elif currentTimeUnit >= diffGraph.MAX_NUMBER_OF_POINTS - 1:
			stop = true
			get_tree().change_scene("res://scenes/Defeat.tscn")
		totalGraph.addPoint(currentProduction)
		productionSinceLastTimeUnit = min(diffGraph.MAX_VALUE, max(0, productionSinceLastTimeUnit))
		diffGraph.addPoint(productionSinceLastTimeUnit)
		productionSinceLastTimeUnit = 0

func coworkerSelected(coworker):
	coworkerSelected = coworker
	$VBoxContainer/Bottom/Profil/Avatar.visible = true
	$VBoxContainer/Bottom/Profil/Avatar.copy(coworker.get_avatar())
