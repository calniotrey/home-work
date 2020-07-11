extends Control

onready var Coworker = preload("res://scenes/Coworker.tscn")

var coworkerSelected = null
var coworkers_list = []

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

var refactos_list = []
var docs_list = []
var time_spent_on_archi = 0
var debugs_list = []
var time_since_last_meeting = 0

const ARCHI_THRESHOLD = 50
const TIME_REFACTO_CONSTANT = 1
const TIME_DOC_CONSTANT 	= 1
const TIME_ARCHI_CONSTANT 	= 1
const TIME_DEBUG_CONSTANT 	= 1
const TIME_MEETING_CONSTANT = 1

const PRODUCTION_CONSTANT = 0.002

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
			coworker.connect("selected_task_signal", self, "coworker_selected_task")
			grid.add_child(coworker)
			coworkers_list.append(coworker)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	add_time(delta)
	for coworker in coworkers_list:
		if coworker.current_task == "feature":
			pass
		elif coworker.current_task == "documentation":
			docs_list[coworker.list_index][0] -= delta # because add_time added delta
			docs_list[coworker.list_index][1] += delta
		elif coworker.current_task == "debug":
			debugs_list[coworker.list_index][0] -= delta # because add_time added delta
			debugs_list[coworker.list_index][1] += delta
		elif coworker.current_task == "refactoring":
			refactos_list[coworker.list_index][0] -= delta # because add_time added delta
			refactos_list[coworker.list_index][1] += delta
		elif coworker.current_task == "architecture":
			time_spent_on_archi += delta
	# Get productio,
	var prod = 0
	for coworker in coworkers_list:
		var rp = coworker.get_raw_production()
		var pf = get_global_production_factor()
		var p = PRODUCTION_CONSTANT * rp * pf
		prod += p
		# print(rp, " : ", pf, " : ", p)
	# Change task if necessary
	for coworker in coworkers_list:
		if coworker.time_until_task_change <= 0:
			coworker.set_random_task()
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

func add_time(delta):
	timeSinceLastTimeUnit += delta
	time_since_last_meeting += delta
	for i in len(refactos_list):
		refactos_list[i][0] = refactos_list[i][0] + delta
	for doc in docs_list:
		doc[0] += delta
	for debug in debugs_list:
		debug[0] += delta
	for coworker in coworkers_list:
		coworker.time_until_task_change -= delta
	
func get_global_production_factor():
	var factor = 1.0
	for refacto in refactos_list:
		var time_since = refacto[0]
		var time_spent = refacto[1]
		factor *= 1.0 + exp(-1.0 * time_since / time_spent / TIME_REFACTO_CONSTANT)
	for doc in docs_list:
		var time_since = doc[0]
		var time_spent = doc[1]
		factor *= 1.0 + .5 * exp(-1.0 * time_since / time_spent / TIME_DOC_CONSTANT)
	factor *= 1.0 + 0.5 * min(1.0, exp(- (ARCHI_THRESHOLD - time_spent_on_archi) / TIME_ARCHI_CONSTANT))
	for debug in debugs_list:
		var time_since = debug[0]
		var time_spent = debug[1]
		factor *= 1.0 + 0.2 * exp(-1.0 * time_since / time_spent / TIME_DEBUG_CONSTANT)
	factor *= (0.5 + exp(-time_since_last_meeting / TIME_MEETING_CONSTANT))
	return factor

func coworkerSelected(coworker):
	coworkerSelected = coworker
	$VBoxContainer/Bottom/Profil/Avatar.visible = true
	$VBoxContainer/Bottom/Profil/Avatar.copy(coworker.get_avatar())

func coworker_selected_task(coworker):
	if coworker.current_task == "documentation":
		coworker.list_index = len(docs_list)
		docs_list.append([0.0, 0.0])
	elif coworker.current_task == "debug":
		coworker.list_index = len(debugs_list)
		debugs_list.append([0.0, 0.0])
	elif coworker.current_task == "refactoring":
		coworker.list_index = len(refactos_list)
		refactos_list.append([0.0, 0.0])
