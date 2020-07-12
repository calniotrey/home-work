extends Control

onready var Coworker = preload("res://scenes/Coworker.tscn")

var coworkerSelected = null
var coworkers_list = []

var diff_graph
var total_graph

var stop = false

var MAX_TIME_UNIT = 300.0
var TARGET_PRODUCTION = 10.0
var IRL_TIME_PER_UNIT = 0.05 # TODO restore to 1 before getting good constants

var current_production = 0.0
var current_time = 0.0
var time_since_last_graph_append = 0.0
var production_since_last_graph_append = 0.0

var refactos_list = []
var docs_list = []
var time_spent_on_archi = 0
var debugs_list = []
var time_since_last_meeting = 0
var total_time_elapsed = 0

const ARCHI_THRESHOLD = 50
const TIME_REFACTO_CONSTANT = 1
const TIME_DOC_CONSTANT 	= 1
const TIME_ARCHI_CONSTANT 	= 1
const TIME_DEBUG_CONSTANT 	= 1
const TIME_MEETING_CONSTANT = 1

const PRODUCTION_CONSTANT = 0.001

const P_DISTURBED_REMOVED   = 0.01
const P_SATISFIED_REMOVED   = 0.01
const P_ANGRY_REMOVED       = 0.01

const P_ANNOYING_EFFECT     = 0.001
const P_AMBITIOUS_EFFECT    = 0.001
const GAMING_CONSTANT       = 10000.0

# Called when the node enters the scene tree for the first time.
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
			coworkers_list.append(coworker)
			coworker.set_random_traits()
			coworker.set_random_task_preference()
			coworker.set_random_task()

func _process(delta):
	add_time(delta)

	compute_production()
	change_tasks_if_necessary()
	coworkers_modifiers_check()
	coworkers_traits_effects()
	if not stop and time_since_last_graph_append >= IRL_TIME_PER_UNIT:
		# print("append : ", current_production)
		current_time += 1
		time_since_last_graph_append -= IRL_TIME_PER_UNIT
		check_end_game()
		# print("current prod : ", current_production)
		total_graph.add_point(current_production)
		production_since_last_graph_append = max(0, min(diff_graph.MAX_VALUE, production_since_last_graph_append))
		diff_graph.add_point(production_since_last_graph_append)
		production_since_last_graph_append = 0

func add_time(delta):
	total_time_elapsed += delta
	time_since_last_graph_append += delta
	time_since_last_meeting += delta
	for coworker in coworkers_list:
		coworker.time_until_task_change -= delta
		coworker.time_spent_on_current_task += delta
		coworker.time_since_last_interaction +=  delta

func get_global_production_factor():
	var factor = 1.0
	for refacto in refactos_list:
		var time_since = total_time_elapsed - refacto[0]
		var time_spent = refacto[1]
		factor *= 1.0 + exp(-1.0 * time_since / time_spent / TIME_REFACTO_CONSTANT)
	for doc in docs_list:
		var time_since = total_time_elapsed - doc[0]
		var time_spent = doc[1]
		factor *= 1.0 + .5 * exp(-1.0 * time_since / time_spent / TIME_DOC_CONSTANT)
	factor *= 1.0 + 0.5 * min(1.0, exp(- (ARCHI_THRESHOLD - time_spent_on_archi) / TIME_ARCHI_CONSTANT))
	for debug in debugs_list:
		var time_since = total_time_elapsed - debug[0]
		var time_spent = debug[1]
		factor *= 1.0 + 0.2 * exp(-1.0 * time_since / time_spent / TIME_DEBUG_CONSTANT)
	factor *= (0.5 + exp(-time_since_last_meeting / TIME_MEETING_CONSTANT))
	return factor

func _coworker_selected(coworker):
	var cwk = $VBoxContainer/Top/MainDisplay/CurrentWorker
	cwk.visible = true
	cwk.modulate.a = 1
	cwk.get_node("Avatar").copy(coworker.get_avatar())
	cwk.get_node("FadeTimer").start()


func compute_production():
	var prod = 0.0
	for coworker in coworkers_list:
		var rp = coworker.get_raw_production()
		var pf = get_global_production_factor()
		var p = PRODUCTION_CONSTANT * rp * pf
		prod += p
		# print(rp, " : ", pf, " : ", p)
	production_since_last_graph_append += prod
	current_production += prod
	current_production = min(total_graph.MAX_VALUE, max(0, current_production))

func change_tasks_if_necessary():
	for coworker in coworkers_list:
		if coworker.time_until_task_change <= 0:
			var new_elem = [total_time_elapsed, coworker.time_spent_on_current_task]
			if coworker.current_task == "feature":
				pass
			elif coworker.current_task == "documentation":
				docs_list.append(new_elem)
			elif coworker.current_task == "debug":
				debugs_list.append(new_elem)
			elif coworker.current_task == "refactoring":
				refactos_list.append(new_elem)
			elif coworker.current_task == "architecture":
				time_spent_on_archi += coworker.time_spent_on_current_task

			coworker.set_random_task()

func coworkers_modifiers_check():
	for index in len(coworkers_list):
		var coworker = coworkers_list[index]
		if coworker.is_disturbed and randf() < P_DISTURBED_REMOVED:
			print("Coworker ", index, " stops being disturbed")
			coworker.is_disturbed = false
		if coworker.is_satisfied and randf() < P_SATISFIED_REMOVED:
			print("Coworker ", index, " stops being satisfied")
			coworker.is_satisfied = false
		if coworker.is_angry and randf() < P_ANGRY_REMOVED:
			print("Coworker ", index, " stops being angry")
			coworker.is_angry = false

func coworkers_traits_effects():
	for index in len(coworkers_list):
		var coworker = coworkers_list[index]
		if coworker.traits.has("annoying") and randf() < P_ANNOYING_EFFECT:
			var random_index = randi() % (len(coworkers_list) - 1)
			if random_index >= index: # remove possibility to get same coworker
				random_index += 1
			coworkers_list[random_index].is_disturbed = true
			print("Coworker ", index, " disturbs coworker ", random_index)
		if coworker.traits.has("ambitious") and randf() < P_AMBITIOUS_EFFECT:
			var random_index = randi() % (len(coworkers_list) - 1)
			if random_index >= index: # remove possibility to get same coworker
				random_index += 1
			coworkers_list[random_index].time_since_last_interaction = 0
			print("Coworker ", index, " 'manages' coworker ", random_index)
		if coworker.traits.has("gamer") and randf() > exp(-coworker.time_since_last_interaction / GAMING_CONSTANT ):
			coworker.set_task("gaming") # TODO add proba to trigger gaming on others
			print("Coworker ", index, " starts playing")

func check_end_game():
	if current_production >= TARGET_PRODUCTION:
		stop = true
		get_tree().change_scene("res://scenes/Victory.tscn")
	elif total_time_elapsed >= MAX_TIME_UNIT * IRL_TIME_PER_UNIT:
		stop = true
		get_tree().change_scene("res://scenes/Defeat.tscn")

func _on_start_fading():
	var cwk = $VBoxContainer/Top/MainDisplay/CurrentWorker
	var tween = cwk.get_node("FadeTween")
	tween.interpolate_property(cwk, "modulate:a", 1, 0, 3,
							   Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
