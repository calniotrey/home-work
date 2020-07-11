extends Control

onready var Coworker = preload("res://scenes/Coworker.tscn")

var coworkerSelected = null

var diff_graph
var total_graph

var stop = false

var MAX_TIME_UNIT = 300.0
var TARGET_PRODUCTION = 10.0
var PRODUCTION_TICK = 0.05

var current_production = 0.0
var current_time = 0.0


func _ready():
	randomize()

	diff_graph = $VBoxContainer/Top/MainDisplay/TabContainer/DiffGraph
	diff_graph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	diff_graph.MAX_VALUE = TARGET_PRODUCTION / MAX_TIME_UNIT / 2.0
	total_graph = $VBoxContainer/Top/MainDisplay/TabContainer/TotalGraph
	total_graph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	total_graph.MAX_VALUE = TARGET_PRODUCTION
	
	# Init all the coworkers
	var grids = [$VBoxContainer/Top/LeftCoworkerGrid, $VBoxContainer/Top/RightCoworkerGrid]
	for grid in grids:
		for coworker in grid.get_children():
			coworker.connect("selected", self, "_coworker_selected")
			coworker.get_avatar().generate_face()


func _process(delta):
	current_time += delta
	if current_time >= PRODUCTION_TICK:
		production_tick()


func _coworker_selected(coworker):
	var cwk = $VBoxContainer/Top/MainDisplay/CurrentWorker
	cwk.visible = true
	cwk.modulate.a = 1
	cwk.get_node("Avatar").copy(coworker.get_avatar())
	cwk.get_node("FadeTimer").start()


func production_tick():
	var prod = (3*randf() - 1)*0.001
	current_production += prod
	
	if false:
		stop = true
		get_tree().change_scene("res://scenes/Victory.tscn")
	elif false:
		stop = true
		get_tree().change_scene("res://scenes/Defeat.tscn")
	
	diff_graph.add_point(prod + 0.005)
	total_graph.add_point(current_production)


func _on_start_fading():
	var cwk = $VBoxContainer/Top/MainDisplay/CurrentWorker
	var tween = cwk.get_node("FadeTween")
	tween.interpolate_property(cwk, "modulate:a", 1, 0, 3,
							   Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
